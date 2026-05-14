library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port (
        clk         : in  STD_LOGIC;
        rst_btn     : in  STD_LOGIC;
        trigger_btn : in  STD_LOGIC;
        done        : out STD_LOGIC
    );
end top_level;

architecture Behavioral of top_level is

    -- Parameters
    constant NUM_ROS    : integer := 256;
    constant NUM_PAIRS  : integer := 128;
    constant COUNT_BITS : integer := 32;
    constant WINDOW     : integer := 1000000;

    -- State machine
    type state_type is (IDLE, ENABLE_ROS, WAIT_COUNT, COMPARE, STORE, COMPLETE);
    signal state : state_type := IDLE;

    -- Debounced button signals
    signal rst     : STD_LOGIC;
    signal trigger : STD_LOGIC;

    -- Done signal
    signal done_sig : STD_LOGIC := '0';

    -- Auto trigger
    signal auto_count : integer range 0 to 12500000 := 0;

    -- RO signals
    signal ro_enable  : STD_LOGIC := '0';
    signal ro_out     : STD_LOGIC_VECTOR(NUM_ROS-1 downto 0);
    signal ro_a_sel   : STD_LOGIC;
    signal ro_b_sel   : STD_LOGIC;

    -- Counter signals
    signal cnt_rst    : STD_LOGIC := '0';
    signal cnt_en     : STD_LOGIC := '0';
    signal count_a    : STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0);
    signal count_b    : STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0);
    signal cnt_done_a : STD_LOGIC;
    signal cnt_done_b : STD_LOGIC;
    signal window_cnt : integer range 0 to WINDOW := 0;

    -- Comparator signals
    signal cmp_valid  : STD_LOGIC := '0';
    signal response   : STD_LOGIC;
    signal cmp_done   : STD_LOGIC;

    -- Response storage
    signal responses  : STD_LOGIC_VECTOR(NUM_PAIRS-1 downto 0) := (others => '0');
    signal pair_idx   : integer range 0 to NUM_PAIRS-1 := 0;

    -- Component declarations
    component ring_oscillator
        Generic (NUM_INVERTERS : integer := 5);
        Port (
            enable  : in  STD_LOGIC;
            clk_out : out STD_LOGIC
        );
    end component;

    component counter
        Generic (COUNT_BITS : integer := 32);
        Port (
            clk    : in  STD_LOGIC;
            rst    : in  STD_LOGIC;
            enable : in  STD_LOGIC;
            ro_clk : in  STD_LOGIC;
            count  : out STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0);
            done   : out STD_LOGIC
        );
    end component;

    component comparator
        Generic (COUNT_BITS : integer := 32);
        Port (
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            count_a  : in  STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0);
            count_b  : in  STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0);
            valid    : in  STD_LOGIC;
            response : out STD_LOGIC;
            done     : out STD_LOGIC
        );
    end component;

    component debounce
        Port (
            clk  : in  STD_LOGIC;
            btn  : in  STD_LOGIC;
            dbnc : out STD_LOGIC
        );
    end component;

    component ila_0
        Port (
            clk    : in STD_LOGIC;
            probe0 : in STD_LOGIC_VECTOR(127 downto 0);
            probe1 : in STD_LOGIC_VECTOR(0 downto 0);
            probe2 : in STD_LOGIC_VECTOR(31 downto 0);
            probe3 : in STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

begin

    -- Debounce instances
    debounce_rst: debounce
        Port map (
            clk  => clk,
            btn  => rst_btn,
            dbnc => rst
        );

    debounce_trig: debounce
        Port map (
            clk  => clk,
            btn  => trigger_btn,
            dbnc => trigger
        );

    -- RO pair selection
    ro_a_sel <= ro_out(pair_idx * 2);
    ro_b_sel <= ro_out(pair_idx * 2 + 1);

    -- Ring oscillator instances
    gen_ros: for i in 0 to NUM_ROS-1 generate
        ro_inst: ring_oscillator
            Generic map (NUM_INVERTERS => 5)
            Port map (
                enable  => ro_enable,
                clk_out => ro_out(i)
            );
    end generate;

    -- Counter A instance
    cnt_a_inst: counter
        Generic map (COUNT_BITS => COUNT_BITS)
        Port map (
            clk    => clk,
            rst    => cnt_rst,
            enable => cnt_en,
            ro_clk => ro_a_sel,
            count  => count_a,
            done   => cnt_done_a
        );

    -- Counter B instance
    cnt_b_inst: counter
        Generic map (COUNT_BITS => COUNT_BITS)
        Port map (
            clk    => clk,
            rst    => cnt_rst,
            enable => cnt_en,
            ro_clk => ro_b_sel,
            count  => count_b,
            done   => cnt_done_b
        );

    -- Comparator instance
    cmp_inst: comparator
        Generic map (COUNT_BITS => COUNT_BITS)
        Port map (
            clk      => clk,
            rst      => rst,
            count_a  => count_a,
            count_b  => count_b,
            valid    => cmp_valid,
            response => response,
            done     => cmp_done
        );

    -- ILA instance
    ila_inst: ila_0
        Port map (
            clk      => clk,
            probe0   => responses,
            probe1(0)=> done_sig,
            probe2   => count_a,
            probe3   => count_b
        );

    -- Done output
    done_sig <= '1' when state = COMPLETE else '0';
    done     <= done_sig;

    -- Main state machine
    process(clk, rst)
    begin
        if rst = '1' then
            state      <= IDLE;
            ro_enable  <= '0';
            cnt_rst    <= '1';
            cnt_en     <= '0';
            cmp_valid  <= '0';
            pair_idx   <= 0;
            window_cnt <= 0;
            auto_count <= 0;
            responses  <= (others => '0');

        elsif rising_edge(clk) then
            case state is

                when IDLE =>
                    ro_enable <= '0';
                    cnt_rst   <= '0';
                    if trigger = '1' then
                        pair_idx  <= 0;
                        responses <= (others => '0');
                        state     <= ENABLE_ROS;
                    end if;

                when ENABLE_ROS =>
                    ro_enable  <= '1';
                    cnt_rst    <= '1';
                    cnt_en     <= '0';
                    cmp_valid  <= '0';
                    window_cnt <= 0;
                    state      <= WAIT_COUNT;

                when WAIT_COUNT =>
                    cnt_rst <= '0';
                    cnt_en  <= '1';
                    if window_cnt = WINDOW then
                        cnt_en    <= '0';
                        ro_enable <= '0';
                        cmp_valid <= '1';
                        state     <= COMPARE;
                    else
                        window_cnt <= window_cnt + 1;
                    end if;

                when COMPARE =>
                    cmp_valid <= '0';
                    if cmp_done = '1' then
                        state <= STORE;
                    end if;

                when STORE =>
                    responses(pair_idx) <= response;
                    if pair_idx = NUM_PAIRS-1 then
                        state      <= COMPLETE;
                        auto_count <= 0;
                    else
                        pair_idx <= pair_idx + 1;
                        state    <= ENABLE_ROS;
                    end if;

                when COMPLETE =>
                    if auto_count = 12500000 then
                        auto_count <= 0;
                        pair_idx   <= 0;
                        responses  <= (others => '0');
                        state      <= ENABLE_ROS;
                    else
                        auto_count <= auto_count + 1;
                    end if;

            end case;
        end if;
    end process;

end Behavioral;