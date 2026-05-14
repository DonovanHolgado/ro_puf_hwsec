library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter is
    Generic (
        COUNT_BITS : integer := 32  -- counter width
    );
    Port (
        clk      : in  STD_LOGIC;  -- system clock
        rst      : in  STD_LOGIC;  -- reset
        enable   : in  STD_LOGIC;  -- count enable
        ro_clk   : in  STD_LOGIC;  -- ring oscillator input
        count    : out STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0);
        done     : out STD_LOGIC   -- counting window complete
    );
end counter;

architecture Behavioral of counter is

    signal count_reg  : unsigned(COUNT_BITS-1 downto 0) := (others => '0');
    signal ro_clk_prev : STD_LOGIC := '0';

begin

    process(clk, rst)
    begin
        if rst = '1' then
            count_reg   <= (others => '0');
            ro_clk_prev <= '0';
            done        <= '0';
        elsif rising_edge(clk) then
            ro_clk_prev <= ro_clk;
            if enable = '1' then
                -- detect rising edge of RO clock
                if ro_clk = '1' and ro_clk_prev = '0' then
                    count_reg <= count_reg + 1;
                end if;
                done <= '0';
            else
                done <= '1';
            end if;
        end if;
    end process;

    count <= STD_LOGIC_VECTOR(count_reg);

end Behavioral;