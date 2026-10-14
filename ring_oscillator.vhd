library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

-- Ring oscillator: AND enable stage + 3 inverters (odd number of inversions),
-- followed by a divide-by-2 toggle flip-flop so the counter clock stays well
-- below the fabric limit. Cell names are referenced by ro_placement.tcl and
-- ro_route.tcl, which give every ring an identical layout.
entity ring_oscillator is
    Port (
        enable  : in  STD_LOGIC;
        clk_out : out STD_LOGIC   -- ring frequency / 2
    );
end ring_oscillator;

architecture Behavioral of ring_oscillator is

    attribute DONT_TOUCH     : string;
    attribute KEEP_HIERARCHY : string;
    attribute KEEP_HIERARCHY of Behavioral : architecture is "yes";

    signal t0, t1, t2, t3 : STD_LOGIC;
    signal div_d, div_q   : STD_LOGIC;

    attribute DONT_TOUCH of t0    : signal is "true";
    attribute DONT_TOUCH of t1    : signal is "true";
    attribute DONT_TOUCH of t2    : signal is "true";
    attribute DONT_TOUCH of t3    : signal is "true";
    attribute DONT_TOUCH of div_d : signal is "true";
    attribute DONT_TOUCH of div_q : signal is "true";

    attribute DONT_TOUCH of LUT_AND  : label is "true";
    attribute DONT_TOUCH of LUT_INV0 : label is "true";
    attribute DONT_TOUCH of LUT_INV1 : label is "true";
    attribute DONT_TOUCH of LUT_INV2 : label is "true";
    attribute DONT_TOUCH of LUT_DIV  : label is "true";
    attribute DONT_TOUCH of FF_DIV   : label is "true";

begin

    -- AND gate controlled by enable (first stage, non-inverting)
    LUT_AND : LUT2
        generic map (
            INIT => X"8"  -- AND
        )
        port map (
            O  => t0,
            I0 => enable,
            I1 => t3
        );

    -- Inverter stage 1
    LUT_INV0 : LUT1
        generic map (
            INIT => "01"  -- INV
        )
        port map (
            O  => t1,
            I0 => t0
        );

    -- Inverter stage 2
    LUT_INV1 : LUT1
        generic map (
            INIT => "01"  -- INV
        )
        port map (
            O  => t2,
            I0 => t1
        );

    -- Inverter stage 3
    LUT_INV2 : LUT1
        generic map (
            INIT => "01"  -- INV
        )
        port map (
            O  => t3,
            I0 => t2
        );

    -- Divide-by-2 toggle flip-flop clocked by the ring
    LUT_DIV : LUT1
        generic map (
            INIT => "01"  -- INV
        )
        port map (
            O  => div_d,
            I0 => div_q
        );

    FF_DIV : FDRE
        generic map (
            INIT => '0'
        )
        port map (
            Q  => div_q,
            C  => t3,
            CE => '1',
            R  => '0',
            D  => div_d
        );

    clk_out <= div_q;

end Behavioral;
