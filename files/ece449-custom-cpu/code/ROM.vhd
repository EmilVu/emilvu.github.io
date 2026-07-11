library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;


entity ROM_file is
    port(
        --input signals       
        addr: in std_logic_vector(15 downto 0); 

        rst: in std_logic;  
        clk: in std_logic;  

        -- output signal
        dout: out std_logic_vector(15 downto 0)
    );
end ROM_file;

architecture behavioural of ROM_file is
    begin

    xpm_memory_sprom_inst : xpm_memory_sprom
    generic map (

        -- Common module generics
        MEMORY_SIZE             => 8192,            -- 1024 bytes block
        MEMORY_PRIMITIVE        => "auto",          --string; "auto", "distributed", or "block";
        MEMORY_INIT_FILE        => "factorial.mem",          --string; "none" or "<filename>.mem" 
        MEMORY_INIT_PARAM       => "",              --string;
        USE_MEM_INIT            => 1,               --integer; 0,1
        WAKEUP_TIME             => "disable_sleep", --string; "disable_sleep" or "use_sleep_pin" 
        MESSAGE_CONTROL         => 0,               --integer; 0,1
        ECC_MODE                => "no_ecc",        --string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
        AUTO_SLEEP_TIME         => 0,               --Do not Change
        MEMORY_OPTIMIZATION     => "true",          --string; "true", "false" 

        -- Port A module generics
        READ_DATA_WIDTH_A       => 16,              --positive integer
        ADDR_WIDTH_A            => 16,               --positive integer
        READ_RESET_VALUE_A      => "0",             --string
        READ_LATENCY_A          => 1                --non-negative integer
    )
    port map (

        -- Common module ports
        sleep                   => '0',

        -- Port A module ports
        clka                    => clk,
        rsta                    => rst,
        ena                     => '1',
        regcea                  => '1',
        addra                   => addr,
        injectsbiterra          => '0',   --do not change
        injectdbiterra          => '0',   --do not change
        douta                   => dout,
        sbiterra                => open,  --do not change
        dbiterra                => open   --do not change
    );

    -- End of xpm_memory_sprom_inst instance declaration

end behavioural;