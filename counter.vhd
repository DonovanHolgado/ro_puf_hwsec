library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Counts ring oscillator edges by using the ring output directly as the
-- counter clock. Enable comes from the system clock domain and the count is
-- synchronized back; the count is only valid once counting has stopped.
entity counter is
    Generic (
        COUNT_BITS : integer := 32  -- counter width
    );
    Port (
        clk      : in  STD_LOGIC;  -- system clock (readout)
        rst      : in  STD_LOGIC;  -- async clear
        enable   : in  STD_LOGIC;  -- count enable (system clock domain)
        ro_clk   : in  STD_LOGIC;  -- ring oscillator clock
        count    : out STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0)
    );
end counter;

architecture Behavioral of counter is

    attribute ASYNC_REG : string;

    -- ring oscillator domain
    signal en_sync   : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal count_reg : unsigned(COUNT_BITS-1 downto 0) := (others => '0');

    -- system clock domain
    signal count_s1  : STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0) := (others => '0');
    signal count_s2  : STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0) := (others => '0');

    attribute ASYNC_REG of en_sync  : signal is "TRUE";
    attribute ASYNC_REG of count_s1 : signal is "TRUE";
    attribute ASYNC_REG of count_s2 : signal is "TRUE";

begin

    -- count in the ring oscillator domain
    process(ro_clk, rst)
    begin
        if rst = '1' then
            en_sync   <= (others => '0');
            count_reg <= (others => '0');
        elsif rising_edge(ro_clk) then
            en_sync <= en_sync(0) & enable;
            if en_sync(1) = '1' then
                count_reg <= count_reg + 1;
            end if;
        end if;
    end process;

    -- bring the count into the system clock domain
    process(clk)
    begin
        if rising_edge(clk) then
            count_s1 <= STD_LOGIC_VECTOR(count_reg);
            count_s2 <= count_s1;
        end if;
    end process;

    count <= count_s2;

end Behavioral;
