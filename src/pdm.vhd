library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- (added `CTR_MAX` to introduce an artificial cap to the inner counter)
entity pdm is
    generic (
        WIDTH: natural := 8;
        CTR_MAX: natural := 65535
    );

    port(
        clk, reset, mea_req               : in std_ulogic;
        setpoint, min_off, min_on, max_on : in std_ulogic_vector(WIDTH-1 downto 0);
        mea_ack, pdm_pulse                : out std_ulogic 
    );
end entity pdm;

architecture rtl of pdm is
    -- PDM generator signals
    signal r_acc, next_acc : unsigned(WIDTH downto 0);
    alias acc_msb : std_ulogic is r_acc(r_acc'left);

    -- Timers
    signal counter : integer := 0;
    signal timer : integer := 0;
    signal next_timer : integer := 0;

    -- Control flow signals
    signal timer_zero : std_ulogic;
    signal counter_zero : std_ulogic;
    signal counter_ready : std_ulogic;

    -- State types
    type state_t is (OFF_S, ON_S, MEASURE_S);
    signal state, next_state : state_t;
begin
    -- TODO: refactor, so that everything is contained
    -- within a single clocked process, while respecting
    -- the spirit of the ASMD diagram

    -- map control flow signals
    timer_zero <= '1' when timer = 0 else '0';
    counter_zero <= '1' when counter = 0 else '0';
    counter_ready <= '1' when counter >= to_integer(unsigned(min_on)) else '0';

    -- map register inputs
    next_acc <= ("0" & unsigned(setpoint)) + ("0" & r_acc(WIDTH-1 downto 0));

    -- counter loop, as described
    -- in the ASMD diagram
    -- (the loops are fused in order to simplify
    -- resetting)
    outer_loop: process(clk)
    begin
        if rising_edge(clk) then
            -- reset should be synchronous
            if reset = '1' then
                counter <= 0;
                r_acc <= (others => '0');
            else
                -- control counter direction
                if pdm_pulse = '0' and acc_msb = '1' then
                    -- clamping the counter isn't really necessary, as it is
                    -- a 32-bit integer, meaning that it probably won't overflow
                    counter <= (counter + 1) when counter < CTR_MAX;
                elsif pdm_pulse = '1' and acc_msb = '0' then
                    counter <= (counter - 1) when counter > 0;
                end if;

                -- update registers, if any
                r_acc <= next_acc;
            end if;
        end if;
    end process;

    -- state register update and timer loop
    state_reg : process(clk, reset, next_state, next_timer)
    begin
        if rising_edge(clk) then
            -- reset should be synchronous
            if reset then
                state <= OFF_S;
                timer <= to_integer(unsigned(min_off));
            else
                state <= next_state;

                -- change timer on state transition
                if state /= next_state then
                    timer <= next_timer;
                else
                    timer <= (timer - 1) when timer > 0;
                end if;
            end if;
        end if;
    end process;

    -- state transitions
    --
    -- this state machine is indeterminate, as it is supposed
    -- to continuously map a "set point" to a PDM signal
    state_tr: process(state, mea_req, timer_zero, counter_zero, counter_ready)
    begin
        next_state <= state;
        next_timer <= timer;

        -- control output signals
        pdm_pulse <= '1' when state = ON_S else '0';
        mea_ack <= '1' when state = MEASURE_S else '0';

        case state is
            when OFF_S =>
                if mea_req = '1' then
                    next_state <= MEASURE_S;
                elsif timer_zero = '1' and counter_ready = '1' then
                    next_timer <= to_integer(unsigned(max_on));
                    next_state <= ON_S;
                end if;
                -- fall-through to sustain OFF_S

            when ON_S =>
                if timer_zero = '1' or counter_zero = '1' then
                    next_timer <= to_integer(unsigned(min_off));
                    next_state <= OFF_S;
                end if;
                -- no legal transition to MEASURE_S
                -- fall-through to sustain ON_S

            when MEASURE_S =>
                if mea_req = '0' then
                    next_state <= OFF_s;
                    next_timer <= timer;
                end if;
                -- no legal transition to ON_S
                -- fall-through to sustain MEASURE_S
        end case;
    end process;
end architecture rtl; -- rtl
