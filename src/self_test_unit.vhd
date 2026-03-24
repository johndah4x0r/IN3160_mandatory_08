library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity self_test_unit is
    generic (
        DATA_WIDTH      : integer := 8;             -- data width in bits
        ADDR_WIDTH      : integer := 6;             -- address width in bits
        MASTER_LIMIT    : integer := 1000;          -- master limit value (use reasonable values in simulations)
        SLAVE_LIMIT     : integer := 3;             -- slave limit value
        DISP_LIMIT      : integer := 100            -- display limit value            
    );

    port (
        -- bare minimum ports
        clk, reset      : in std_ulogic;
        a, b            : in std_ulogic;
        done            : out std_ulogic;           -- port primarily used for simulation
        dir, en         : out std_ulogic;

        -- ports for display control
        abcdefg         : out std_ulogic_vector(6 downto 0);
        c               : out std_ulogic;

        -- ports for side-loading in simulations
        data_in         : in std_logic_vector(DATA_WIDTH-1 downto 0);
        addr            : in unsigned(ADDR_WIDTH-1 downto 0);
        we              : in std_ulogic
    );
end entity self_test_unit;

architecture structural of self_test_unit is
    signal seq              : signed(DATA_WIDTH-1 downto 0);
    signal pwm_bus          : std_ulogic_vector(1 downto 0);
    signal in_bus, dec_bus  : std_ulogic_vector(1 downto 0);
    signal v_bus            : signed(7 downto 0);
    signal abs_v            : std_ulogic_vector(7 downto 0);

    function calc_abs(x : signed) return std_ulogic_vector is
    begin
        if x < 0 then
            return std_ulogic_vector((not x) + 1);
        else
            return std_ulogic_vector(x);
        end if;
    end function;
begin
    sig_gen: entity work.pulse_width_modulator(behavioral)
        -- change values, or omit the mapping outright,
        -- upon synthesis
        generic map (
            MIN_OFF => x"0000A",
            MIN_ON => x"0000A",
            MAX_ON => x"000C8"
        )

        port map (
            mclk => clk,
            reset => reset,
            duty_cycle => seq,
            dir => pwm_bus(1),
            en => pwm_bus(0)
        );
    
    seq_gen: entity work.self_test(rtl)
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH,
            MASTER_LIMIT => MASTER_LIMIT,
            SLAVE_LIMIT => SLAVE_LIMIT
        )

        port map(
            clk => clk,
            reset => reset,
            duty_cycle => seq,
            done => done,
            data_in => data_in,
            addr => addr,
            we => we
        );
    
    out_sync: entity work.synch(rtl)
        generic map (
            WIDTH => 2
        )

        port map (
            clk => clk,
            n => pwm_bus,
            n_synch(1) => dir,
            n_synch(0) => en
        );
    
    in_sync: entity work.synch(rtl)
        generic map (
            WIDTH => 2
        )

        port map (
            clk => clk,
            n => a & b,
            n_synch => in_bus
        );
    
    dec: entity work.quad_dec(behavioral)
        port map (
            clk => clk,
            reset => reset,
            ab => in_bus,
            pos_inc => dec_bus(1),
            pos_dec => dec_bus(0)
        );
    
    vr: entity work.velocity_reader(rtl)
        port map (
            mclk => clk,
            reset => reset,
            pos_inc => dec_bus(1),
            pos_dec => dec_bus(0),
            velocity => v_bus
        );

    -- for now, map each nibble to each segment
    disp: entity work.seg7ctrl(rtl)
        generic map (
            LIMIT => DISP_LIMIT
        )

        port map (
            mclk => clk,
            reset => reset,
            d0 => abs_v(3 downto 0),
            d1 => abs_v(7 downto 4),
            abcdefg => abcdefg,
            c => c
        );

    -- perform combinational calculation
    -- of velocity magnitude
    abs_v <= calc_abs(v_bus);
end architecture structural;
