library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_width_modulator is
    generic (
        MIN_OFF         : std_ulogic_vector(19 downto 0) := x"000FF";
        MIN_ON          : std_ulogic_vector(19 downto 0) := x"00FF0";
        MAX_ON          : std_ulogic_vector(19 downto 0) := x"FF000"
    );

    port(
        mclk, reset     : in std_ulogic;
        duty_cycle      : in signed(7 downto 0);
        dir, en         : out std_ulogic
    );
end entity pulse_width_modulator;

architecture behavioral of pulse_width_modulator is
    signal abs_duty     : std_ulogic_vector(19 downto 0) := (others => '0');
    signal gen_pulse    : std_ulogic := '0';
    signal unused       : std_ulogic;

    type pwm_state_t is (REVERSE_IDLE, REVERSE, FORWARD_IDLE, FORWARD);
    signal pwm_state, next_pwm_state : pwm_state_t;

    signal abs_duty_calc : std_ulogic_vector(7 downto 0);

    function calc_abs(x : signed) return std_ulogic_vector is
    begin
        if x < 0 then
            return std_ulogic_vector((not x) + 1);
        else
            return std_ulogic_vector(x);
        end if;
    end function;
begin
    pdm: entity work.pdm(rtl)
        generic map (
            WIDTH => 20
        )

        port map (
            clk => mclk,
            reset => reset,
            mea_req => '0',
            setpoint => abs_duty,
            min_off => MIN_OFF,
            min_on => MIN_ON,
            max_on => MAX_ON,
            mea_ack => unused,
            pdm_pulse => gen_pulse
        );
    
    clocked: process(mclk)
    begin
        if rising_edge(mclk) then
            if reset = '1' then
                pwm_state <= REVERSE_IDLE;
            else
                pwm_state <= next_pwm_state;
            end if;
        end if;
    end process;

    inner: process(pwm_state, duty_cycle)
    begin
        -- make sure `next_pwm_state` isn't left undefined
        next_pwm_state <= pwm_state;
            
        -- calculate state transitions
        -- (whenever directions change, a guard idle
        -- state must be entered)
        case pwm_state is
            when REVERSE_IDLE =>
                next_pwm_state <= REVERSE when duty_cycle < 0 else FORWARD_IDLE;
            when REVERSE =>
                next_pwm_state <= REVERSE when duty_cycle < 0 else REVERSE_IDLE;
            when FORWARD_IDLE =>
                next_pwm_state <= FORWARD when duty_cycle > 0 else REVERSE_IDLE;
            when FORWARD =>
                next_pwm_state <= FORWARD when duty_cycle > 0 else FORWARD_IDLE;
        end case;
    end process;

    -- (calculation of duty cycle is combinational)
    abs_duty_calc <= calc_abs(duty_cycle);
    abs_duty <= abs_duty_calc(6 downto 0) & "0000000000000";

    -- apply Moore outputs
    en <= gen_pulse when (pwm_state = REVERSE or pwm_state = FORWARD) else '0';
    dir <= '0' when (pwm_state = REVERSE or pwm_state = REVERSE_IDLE) else '1';
end architecture behavioral;
