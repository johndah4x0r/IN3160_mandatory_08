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
    type q_state_t is (S_RESET, S_INIT, S0, S1, S2, S3);
    signal q_state, next_q_state : q_state_t;
    signal err : std_ulogic;
begin
    transition: process(q_state, next_q_state)
    begin
        err <= '0';
        pos_inc <= '0';
        pos_dec <= '0';

        case q_state is
            when S0 =>
                case next_q_state is
                    when S1 => pos_inc <= '1';
                    when S3 => pos_dec <= '1';
                    when S_RESET => err <= '1';
                    when others => null;
                end case;

            when S1 =>
                case next_q_state is
                    when S0 => pos_dec <= '1';
                    when S2 => pos_inc <= '1';
                    when S_RESET => err <= '1';
                    when others => null;
                end case;

            when S2 =>
                case next_q_state is
                    when S1 => pos_dec <= '1';
                    when S3 => pos_inc <= '1';
                    when S_RESET => err <= '1';
                    when others => null;
                end case;

            when S3 =>
                case next_q_state is
                    when S0 => pos_inc <= '1';
                    when S2 => pos_dec <= '1';
                    when S_RESET => err <= '1';
                    when others => null;
                end case;
            when others => null;
        end case;
    end process;

    state_reg: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                q_state  <= S_RESET;
            else
                q_state <= next_q_state;
            end if;
        end if;
    end process;

    next_state: process(q_state, ab)
    begin
        -- note that `ab` uses Gray encoding
        --
        -- also, we're using "00" as a sentinel
        -- value (though it is also a valid value)
        case q_state is
            when S_RESET =>
                next_q_state <= S_INIT;
            when S_INIT =>
                with ab select
                    next_q_state <=
                        S1 when "01",
                        S2 when "11",
                        S3 when "10",
                        S0 when others;
            when S0 =>
                with ab select
                    next_q_state <=
                        S1 when "01",
                        S_RESET when "11",
                        S3 when "10",
                        S0 when others;
            when S1 =>
                with ab select
                    next_q_state <=
                        S1 when "01",
                        S2 when "11",
                        S_RESET when "10",
                        S0 when others;
            when S2 =>
                with ab select
                    next_q_state <=
                        S1 when "01",
                        S2 when "11",
                        S3 when "10",
                        S_RESET when others;
            when S3 =>
                with ab select
                    next_q_state <=
                        S_RESET when "01",
                        S2 when "11",
                        S3 when "10",
                        S0 when others;
        end case;
    end process;
end architecture behavioral;
