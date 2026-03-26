library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity self_test is
    generic (
        SIM_MODE            : boolean := true;          -- simulation mode
        DATA_WIDTH          : integer := 8;             -- data width in bits
        ADDR_WIDTH          : integer := 6;             -- address width in bits
        MASTER_LIMIT        : integer := 5;            -- master limit value (use reasonable values in simulations)
        SLAVE_LIMIT         : integer := 6;             -- slave limit value
        MASTER_LIMIT_WIDTH  : integer := 27;
        SLAVE_LIMIT_WIDTH   : integer := 3
    );

    port (
        clk         : in std_ulogic;                                -- external clock
        reset       : in std_ulogic;                                -- active reset
        duty_cycle  : out signed(DATA_WIDTH-1 downto 0);            -- duty cycle (two's complement)
        done        : out std_ulogic;                               -- done flag
        hb          : out std_ulogic;                               -- heartbeat signal

        -- ports for side-loading in simulations
        data_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);   -- input data
        addr        : in unsigned(ADDR_WIDTH-1 downto 0);           -- ROM address
        we          : in std_ulogic                                 -- write-enable flag
    );
end entity self_test;

architecture rtl of self_test is
    constant ROM_SIZE : integer := 2**ADDR_WIDTH;
    type rom_type is array (0 to ROM_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    -- inner ROM
    -- may be overwritten on synthesis
    signal ROM : rom_type := (
        0 => x"3F",
        1 => x"7F",
        2 => x"00",
        3 => x"C1",
        4 => x"81",
        others => (others => '0')
        );

    attribute ram_init_file : string;
    attribute ram_init_file of ROM : signal is "rom/self_test_rom.hex";

    attribute ram_style : string;
    attribute ram_style of ROM : signal is "block";

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
            -- synthesis translate_off
            elsif SIM_MODE and we = '1' then
                ROM(to_integer(addr)) <= data_in;

                -- reset master counter and enable flag
                master_counter <= (others => '0');
                ce <= '0';
            -- synthesis translate_on
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
            elsif ce = '1' and we = '0' then
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
