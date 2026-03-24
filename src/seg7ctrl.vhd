library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.seg7_pkg.all;

entity seg7ctrl is
    -- generic `LIMIT` added for easier verification
    generic
    (
        LIMIT : integer := 1000000                              -- each display is tended to 50 times a second
    );

    port
    (
        mclk      : in std_ulogic;                              -- 100MHz, rising edge
        reset     : in std_ulogic;                              -- synchronous reset, active high
        d0        : in std_ulogic_vector(3 downto 0);
        d1        : in std_ulogic_vector(3 downto 0);
        abcdefg   : out std_ulogic_vector(6 downto 0);
        c         : out std_ulogic
    );
end entity seg7ctrl;

-- TODO: finish the architecture before
-- the TA's whoop yo ass
architecture rtl of seg7ctrl is
    signal ctr : std_ulogic_vector(19 downto 0);
    signal next_ctr : u_unsigned(19 downto 0);
    signal cs : std_ulogic;
    signal next_cs : std_ulogic;
    signal d_used : std_ulogic_vector(3 downto 0);
begin
    -- timer combinational process
    next_ctr <= 
        (others => '0') when unsigned(ctr) = LIMIT - 1 else     -- increments to `LIMIT - 1` then overflows artificially
        unsigned(ctr) + 1;
    next_cs <=
        not cs when unsigned(next_ctr) = 0 else                 -- toggles if `ctr` overflows
        cs;

    -- timer register process
    clocked: process (mclk) is
    begin
        -- (not quite sure whether to make
        --  reset asynchronous, as originally
        --  intended...)
        if rising_edge(mclk) then
            ctr <=
                (others => '0') when reset else
                std_ulogic_vector(next_ctr);

            cs <= '0' when reset else
                next_cs;
        end if;
    end process;

    -- port mapping
    -- TODO: make the pipe dream real!
    c <= cs;

    d_used <=
        d0 when cs = '0' else
        d1;

    abcdefg <= bin2ssd(d_used);
end architecture rtl;
