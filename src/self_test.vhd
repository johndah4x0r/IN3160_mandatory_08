library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity self_test is
    generic (
        DATA_WIDTH      : integer := 8;             -- data width in bits
        ADDR_WIDTH      : integer := 8;             -- address width in bits
        MASTER_LIMIT    : integer := 10;            -- master limit value (use reasonable values in simulations)
        SLAVE_LIMIT     : integer := 3              -- slave limit value
    );

    port (
        clk         : in std_ulogic;
        reset       : in std_ulogic;
        duty_cycle  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        done        : out std_ulogic;

        -- ports for side-loading in simulations
        data_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
        addr        : in unsigned(ADDR_WIDTH-1 downto 0);
        we          : in std_ulogic
    );
end self_test;

architecture rtl of self_test is
    constant ROM_SIZE : integer := 2**ADDR_WIDTH;
    type rom_type is array (0 to ROM_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    -- inner ROM
    -- may be overwritten on synthesis
    signal ROM : rom_type := (others => (others => '0'));
    signal DYN_ROM_SIZE : integer := 0;

    -- divider counter and flag
    signal master_counter : integer := 0;
    signal slave_counter : integer := 0;
    signal index : integer := 0;
    signal ce : std_ulogic := '0';

    function max(a: integer; b: integer) return integer is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end function;
begin
    clocked: process(clk)
    begin
        if rising_edge(clk) then
            -- tie clock-enable flag to divider counter
            if reset = '1' then
                master_counter <= 0;
                ce <= '0';
            elsif we = '1' then
                ROM(to_integer(addr)) <= data_in;
                DYN_ROM_SIZE <= max(DYN_ROM_SIZE, to_integer(addr)+1);

                -- reset master counter and enable flag
                master_counter <= 0;
                ce <= '0';
            else
                if master_counter < MASTER_LIMIT-1 then
                    master_counter <= master_counter + 1;
                    ce <= '0';
                else 
                    master_counter <= 0;
                    ce <= '1';
                end if;
            end if;
        end if;
    end process;

    gated: process(clk)
    begin
        -- tie execution to clock edge and enable flag
        if rising_edge(clk) then
            if reset = '1' then
                slave_counter <= 0;
                duty_cycle <= (others => '0');
                done <= '0';
            elsif ce = '1' and we = '0'then
                -- tie inner execution to slave counter
                if slave_counter < SLAVE_LIMIT-1 then
                    slave_counter <= slave_counter + 1;
                else
                    slave_counter <= 0;
                    if index < DYN_ROM_SIZE then
                        duty_cycle <= ROM(index);

                        -- FIXME: this might make bounds violations look "legal"
                        index <= index + 1;
                    else
                        done <= '1';
                        duty_cycle <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;
