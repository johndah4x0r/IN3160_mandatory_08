library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- n-bit brute-force synchronizer
entity synch is
    generic (
        WIDTH   : natural := 2
    );

    port (
        clk     : in std_ulogic; 
        n       : in std_ulogic_vector(WIDTH-1 downto 0);
        n_synch : out std_ulogic_vector(WIDTH-1 downto 0)
    );
end entity synch;

architecture rtl of synch is
    signal x_synch, y_synch : std_ulogic_vector(WIDTH-1 downto 0);
begin
    clocked: process(clk)
    begin
        if rising_edge(clk) then
            y_synch <= x_synch;
            x_synch <= n;
        end if;
    end process;

    n_synch <= y_synch;
end architecture rtl;
