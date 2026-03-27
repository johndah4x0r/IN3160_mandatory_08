library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity self_test is
    generic (
        DATA_WIDTH          : integer := 8;             -- data width in bits
        ADDR_WIDTH          : integer := 6;             -- address width in bits (vestigial)
        MASTER_LIMIT        : integer := 5;             -- master limit value (use reasonable values in simulations)
        SLAVE_LIMIT         : integer := 6;             -- slave limit value
        MASTER_LIMIT_WIDTH  : integer := 27;
        SLAVE_LIMIT_WIDTH   : integer := 3
    );

    port (
        clk         : in std_ulogic;                                -- external clock
        reset       : in std_ulogic;                                -- active reset
        duty_cycle  : out signed(DATA_WIDTH-1 downto 0);            -- duty cycle (two's complement)
        done        : out std_ulogic;                               -- done flag
        hb          : out std_ulogic                                -- heartbeat signal
    );
end entity self_test;

architecture rtl of self_test is
    constant ROM_SIZE : integer := 2**ADDR_WIDTH;
    type rom_type is array (0 to ROM_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    impure function init_rom(hex_name : in string) return rom_type is
        FILE hex_file       : text;
        variable rom_line   : line;
        variable gen_rom    : rom_type := (others => (others => '0'));
        variable index      : integer := 0;
    begin
        file_open(hex_file, hex_name, read_mode);
        while not endfile(hex_file) loop
            if index < gen_rom'length then
                readline(hex_file, rom_line);
                hread(rom_line, gen_rom(index));
            end if;
            index := index + 1;
        end loop;
        return gen_rom;
    end function;

    -- inner ROM
    -- may be overwritten on synthesis
    signal ROM : rom_type := init_rom("rom/self_test_rom.hex");

    -- divider counter and flag
    signal master_counter : unsigned(MASTER_LIMIT_WIDTH-1 downto 0) := (others => '0');
    signal slave_counter : unsigned(SLAVE_LIMIT_WIDTH-1 downto 0) := (others => '0');
    signal index : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal ce : std_ulogic := '0';

    signal rom_out : std_logic_vector(DATA_WIDTH-1 downto 0);

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
                master_counter <= (others => '0');
                ce <= '0';
            else
                if master_counter = MASTER_LIMIT-1 then
                    master_counter <= (others => '0');
                    ce <= '1';
                else
                    master_counter <= master_counter + 1;
                    ce <= '0';
                end if;
            end if;
        end if;
    end process;

    gated: process(clk)
    begin
        -- tie execution to clock edge and enable flag
        if rising_edge(clk) then
            if reset = '1' then
                slave_counter <= (others => '0');
                rom_out <= (others => '0');
                duty_cycle <= (others => '0');
                done <= '0';
                index <= (others => '0');
                hb <= '0';
            elsif ce = '1' then
                -- tie inner execution to slave counter
                hb <= not hb;

                if slave_counter = SLAVE_LIMIT-1 then
                    slave_counter <= (others => '0');

                    -- legacy / used in simulations
                    if index /= ROM_SIZE-1 then
                        rom_out <= ROM(to_integer(index));
                        duty_cycle <= signed(rom_out);

                        -- FIXME: this might make bounds violations look "legal"
                        index <= index + 1;
                    else
                        done <= '1';
                        duty_cycle <= (others => '0');
                    end if;
                else
                    slave_counter <= slave_counter + 1;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
