library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vr_test is
    port (
        clk, reset  : in std_ulogic;
        ab          : in std_ulogic_vector(1 downto 0);
        velocity    : out signed(7 downto 0)
    );
end entity vr_test;

architecture structural of vr_test is
    signal inner_bus : std_ulogic_vector(1 downto 0);
begin
    dec: entity work.quad_dec(behavioral)
        port map (
            clk => clk,
            reset => reset,
            ab => ab,
            pos_inc => inner_bus(1),
            pos_dec => inner_bus(0)
        );
    
    vr: entity work.velocity_reader(rtl)
            generic map (
                TEN_MS_COUNT => 1_000
            )
            
            port map (
            mclk => clk,
            reset => reset,
            pos_inc => inner_bus(1),
            pos_dec => inner_bus (0),
            velocity => velocity
        );
end architecture structural;
