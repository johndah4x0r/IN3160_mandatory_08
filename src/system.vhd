library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

/*
    wrapper module around the self-test unit for simulation purposes

    all we're doing is isolate the generics from the core unit
*/

entity system is
    generic (
        MASTER_LIMIT    : integer := 2_500;                             -- master limit value (4 Hz - use reasonable values in simulations)
        SLAVE_LIMIT     : integer := 4;                                 -- slave limit value (0.25 s * 4 = 1 s)
        MIN_OFF         : std_ulogic_vector(19 downto 0) := x"0000A";
        MIN_ON          : std_ulogic_vector(19 downto 0) := x"0000A";
        MAX_ON          : std_ulogic_vector(19 downto 0) := x"000C8"
    );

    port (
        -- bare minimum ports
        clk, reset      : in std_ulogic;
        ab              : in std_ulogic_vector(1 downto 0);
        done, hb        : out std_ulogic;           -- port primarily used for simulation
        dir, en         : out std_ulogic;
    
        -- ports for display control
        abcdefg         : out std_ulogic_vector(6 downto 0);
        c               : out std_ulogic;

        -- ports to view pulses
        velocity        : out signed(7 downto 0);
        pulse           : out std_ulogic_vector(1 downto 0)
    );
end entity system;

architecture structural of system is
begin
    unit: entity work.self_test_unit(structural)
        generic map (
            MASTER_LIMIT => MASTER_LIMIT,
            SLAVE_LIMIT => SLAVE_LIMIT,
            MIN_OFF => MIN_OFF,
            MIN_ON => MIN_ON,
            MAX_ON => MAX_ON
        )

        port map (
            clk => clk,
            reset => reset,
            ab => ab,
            done => done,
            hb => hb,
            dir => dir,
            en => en,
            abcdefg => abcdefg,
            c => c,
            velocity => velocity,
            pulse => pulse
        );

end architecture structural;
