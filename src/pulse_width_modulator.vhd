library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_width_modulator is
    port(
        mclk, reset  : in std_ulogic;
        duty_cycle   : in signed(7 downto 0);
        dir, en      : out std_ulogic
    );
end entity pulse_width_modulator;

architecture behavioral of pulse_width_modulator is
    signal abs_duty     : std_ulogic_vector(19 downto 0) := (others => '0');
    signal gen_pulse    : std_ulogic := '0';
    signal unused       : std_ulogic;

    type pwm_state_t is (REVERSE_IDLE, REVERSE, FORWARD_IDLE, FORWARD);
    signal pwm_state, next_pwm_state : pwm_state_t;

    signal abs_duty_calc : signed(7 downto 0);
    signal req_dir : std_ulogic;
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
            min_off => x"000FF",
            min_on => x"00FF0",
            max_on => x"FF000",
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

    inner: process(pwm_state, req_dir)
    begin
        -- make sure `next_pwm_state` isn't left undefined
        next_pwm_state <= pwm_state;
            
        -- calculate state transitions
        -- (whenever directions change, a guard idle
        -- state must be entered)
        case pwm_state is
            when REVERSE_IDLE =>
                next_pwm_state <= REVERSE when req_dir = '0' else FORWARD_IDLE;
            when REVERSE =>
                next_pwm_state <= REVERSE when req_dir = '0' else REVERSE_IDLE;
            when FORWARD_IDLE =>
                next_pwm_state <= FORWARD when req_dir = '1' else REVERSE_IDLE;
            when FORWARD =>
                next_pwm_state <= FORWARD when req_dir = '1' else FORWARD_IDLE;
        end case;
    end process;

    -- (calculation of duty cycle is combinational)
    abs_duty_calc <= duty_cycle when duty_cycle > 0 else (not duty_cycle) + 1;
    abs_duty <= std_ulogic_vector(abs_duty_calc(6 downto 0)) & "0000000000000";

    -- (I don't know how to use `signed`...)
    req_dir <= not duty_cycle(7);

    -- apply Moore outputs
    en <= gen_pulse when (pwm_state = REVERSE or pwm_state = FORWARD) else '0';
    dir <= '0' when (pwm_state = REVERSE or pwm_state = REVERSE_IDLE) else '1';
end architecture behavioral;
