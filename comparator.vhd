library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator is
    Generic (
        COUNT_BITS : integer := 32
    );
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        count_a  : in  STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0);
        count_b  : in  STD_LOGIC_VECTOR(COUNT_BITS-1 downto 0);
        valid    : in  STD_LOGIC;  -- counts are ready to compare
        response : out STD_LOGIC;  -- PUF response bit
        done     : out STD_LOGIC   -- comparison complete
    );
end comparator;

architecture Behavioral of comparator is

begin

    process(clk, rst)
    begin
        if rst = '1' then
            response <= '0';
            done     <= '0';
        elsif rising_edge(clk) then
            if valid = '1' then
                -- compare two RO counts
                if unsigned(count_a) > unsigned(count_b) then
                    response <= '1';
                else
                    response <= '0';
                end if;
                done <= '1';
            else
                done <= '0';
            end if;
        end if;
    end process;

end Behavioral;
