/*
  Simulation model of a PWM modulator for PMOD-H-bridge. 
  The intention here is to provide non-synthesizable pwm model
  that does PWM, but causes errors found by the testbench. 
*/
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
 
entity pulse_width_modulator is
  port(
      mclk, reset : in std_logic; 
      duty_cycle  : in std_logic_vector(7 downto 0);
      dir, en     : out std_logic
    );
end entity pulse_width_modulator;

architecture behavioral of pulse_width_modulator is
  constant PERIOD : time := 150 us;  
  signal time_on, time_off : time := 100 us;
begin 
  -- dir as stated may cause direction changes while pulsing 
  -- short-circuiting the PMOD half bridge due to transistor capacitance
  dir <= not duty_cycle(7); -- sign bit = direction

  process(duty_cycle) is 
    variable duty : integer := 0;
  begin 
    duty := abs(to_integer(signed(duty_cycle)));
    time_on <= (duty*PERIOD)/128;
    time_off <= (128-duty)*PERIOD/128;
  end process;

  -- en will update with the current duty cycle value each period.  
  PULSING: process is 
  begin
    en <= '0';
    wait for time_off;
    en <= '1';
    wait for time_on;
  end process;
  
end architecture behavioral;