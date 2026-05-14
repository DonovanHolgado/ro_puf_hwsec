library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity debounce is
  Port (clk : in std_logic;
        btn : in std_logic;
        dbnc : out std_logic);
end debounce;

architecture Behavioral of debounce is
signal shift_reg : std_logic_vector (1 downto 0) := (others => '0');
signal counter : std_logic_vector (21 downto 0) := (others => '0');
begin
    process(clk)
        begin
            if clk'event and clk='1' then
                  shift_reg(0) <= btn;
                  shift_reg(1) <= shift_reg(0);
            
            
                if shift_reg(1) = '1' then
                    if (unsigned(counter) < 2499999) then
                        counter <= std_logic_vector(unsigned(counter) + 1);
                        dbnc <= '0';
                    else
                        dbnc<= '1';
                    end if;
                else
                    counter <= (others => '0');
                    dbnc <= '0';
                end if;
                if shift_reg(0) = '0' then
                    counter <= (others =>'0');
                    dbnc <= '0';
                end if;
            end if;
    end process;

end Behavioral;
