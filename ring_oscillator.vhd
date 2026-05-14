library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity ring_oscillator is
    Port (
        enable  : in  STD_LOGIC;
        clk_out : out STD_LOGIC
    );
end ring_oscillator;

architecture Behavioral of ring_oscillator is

    attribute DONT_TOUCH : string;
    
    signal t0, t1, t2, t3 : STD_LOGIC;
    
    attribute DONT_TOUCH of t0 : signal is "true";
    attribute DONT_TOUCH of t1 : signal is "true";
    attribute DONT_TOUCH of t2 : signal is "true";
    attribute DONT_TOUCH of t3 : signal is "true";

begin

    -- NAND gate controlled by enable (first stage)
    LUT6_NAND : LUT6_L
        generic map (
            INIT => X"8888888888888888"  -- NAND
        )
        port map (
            LO => t0,
            I0 => enable,
            I1 => t3,
            I2 => '0',
            I3 => '0',
            I4 => '0',
            I5 => '0'
        );

    -- Inverter stage 1
    LUT6_INV0 : LUT6_L
        generic map (
            INIT => X"5555555555555555"  -- INV
        )
        port map (
            LO => t1,
            I0 => t0,
            I1 => '0',
            I2 => '0',
            I3 => '0',
            I4 => '0',
            I5 => '0'
        );

    -- Inverter stage 2
    LUT6_INV1 : LUT6_L
        generic map (
            INIT => X"5555555555555555"  -- INV
        )
        port map (
            LO => t2,
            I0 => t1,
            I1 => '0',
            I2 => '0',
            I3 => '0',
            I4 => '0',
            I5 => '0'
        );

    -- Inverter stage 3
    LUT6_INV2 : LUT6_L
        generic map (
            INIT => X"5555555555555555"  -- INV
        )
        port map (
            LO => t3,
            I0 => t2,
            I1 => '0',
            I2 => '0',
            I3 => '0',
            I4 => '0',
            I5 => '0'
        );

    clk_out <= t3;

end Behavioral;
