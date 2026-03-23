library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity quad_dec is
    port (
        clk, reset          : in std_ulogic;
        ab                  : in std_ulogic_vector(1 downto 0);
        pos_inc, pos_dec    : out std_ulogic
    );
end entity quad_dec;

architecture behavioral of quad_dec is
    type q_state_t is (RESET, INIT, S0, S1, S2, S3);
    signal q_state, next_q_state : q_state_t;
    signal err : std_ulogic;
begin
    clocked: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                q_state <= RESET;
            else
                -- detect state transition to apply precise
                -- clock-enable signals on `a` and `b`
                if q_state /= next_state then
                    -- handle error case separately
                    if next_state = RESET then
                        err <= '1';
                    else
                        -- handle valid state transitions
                        case (q_state & next_state) is
                            when S0 & S1 =>
                                pos_inc <= '1';
                            when S0 & S3 =>
                                pos_dec <= '1';
                            when S1 & S0 =>
                                pos_dec <= '1';
                            when S1 & S2 =>
                                pos_inc <= '1';
                            when S2 & S1 =>
                                pos_dec <= '1';
                            when S2 & S3 =>
                                pos_inc <= '1';
                            when S3 & S0 =>
                                pos_inc <= '1';
                            when S3 & S2 =>
                                pos_dec <= '1';
                        end case;
                    end if;
                else
                    (err, pos_inc, pos_dec) <= "000";
                end if;

                q_state <= next_state;
            end if;
        end if;
    end process;

    inner: process(q_state, a, b)
    begin
        -- note that `ab` uses Gray encoding
        --
        -- also, we're using "00" as a sentinel
        -- value (though it is also a valid value)
        case q_state is
            when RESET =>
                next_state <= INIT;
            when INIT =>
                with ab select
                    next_state <=
                        S1 when "01",
                        S2 when "11",
                        S3 when "10",
                        S0 when others;
            when S0 =>
                with ab select
                    next_state <=
                        S1 when "01",
                        RESET when "11",
                        S3 when "10",
                        S0 when others;
            when S1 =>
                with ab select
                    next_state <=
                        S1 when "01",
                        S2 when "11",
                        RESET when "10",
                        S0 when others;
            when S2 =>
                with ab select
                    next_state <=
                        S1 when "01",
                        S2 when "11",
                        S3 when "10",
                        RESET when others;
            when S3 =>
                with ab select
                    next_state <=
                        RESET when "01",
                        S2 when "11",
                        S3 when "10",
                        S0 when others;
        end case;
    end process;
end architecture behavioral;
