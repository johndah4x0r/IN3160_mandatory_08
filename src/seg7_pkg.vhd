library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package seg7_pkg is
    function bin2ssd (indata : std_ulogic_vector(3 downto 0)) return std_ulogic_vector;
end package ; -- subprog_pck 

package body seg7_pkg is
    function bin2ssd (indata : std_ulogic_vector(3 downto 0)) return std_ulogic_vector is
    begin
        case indata is
            when "0000" => return "1111110";
            when "0001" => return "0110000";
            when "0010" => return "1101101";
            when "0011" => return "1111001";
            when "0100" => return "0110011";
            when "0101" => return "1011011";
            when "0110" => return "1011111";
            when "0111" => return "1110000";
            when "1000" => return "1111111";
            when "1001" => return "1111011";
            when "1010" => return "1110111";
            when "1011" => return "0011111";
            when "1100" => return "1001110";
            when "1101" => return "0111101";
            when "1110" => return "1001111";
            when "1111" => return "1000111";
            when others => return "0000000";            
        end case;
    end function bin2ssd;
end package body seg7_pkg;
