library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;

entity RAM_file is
    port(
        --input signals       
        addr_dt: in std_logic_vector(15 downto 0); 
        addr_ins: in std_logic_vector(15 downto 0);  

        din_dt: in std_logic_vector(15 downto 0);
        
        wr_mem_en: in std_logic_vector(0 downto 0);
        rst: in std_logic;  
        clk: in std_logic;  

        --output signal
        dout_dt: out std_logic_vector(15 downto 0);  
        dout_ins: out std_logic_vector(15 downto 0)
    );
end RAM_file;


architecture behavioural of RAM_file is

begin
    -- xpm_memory_dpdistram: Dual Port Distributed RAM
    -- Xilinx Parameterized Macro, version 2018.3
    xpm_memory_dpdistram_inst : xpm_memory_dpdistram
    generic map (
    MEMORY_SIZE => 8192, -- 1024 bytes block
    CLOCKING_MODE => "common_clock", -- DEFAULT VALUE
    MEMORY_INIT_FILE => "none", -- DEFAULT VALUE
    MEMORY_INIT_PARAM => "", -- DEFAULT VALUE
    USE_MEM_INIT            => 1,              --integer; 0,1
    MESSAGE_CONTROL         => 0,              --integer; 0,1
    USE_EMBEDDED_CONSTRAINT => 0,              --integer: 0,1
    MEMORY_OPTIMIZATION     => "true",          --string; "true", "false" 

    -- Port A module generics
    WRITE_DATA_WIDTH_A      => 16,             -- 16-bit data
    READ_DATA_WIDTH_A       => 16,             -- 16-bit data
    BYTE_WRITE_WIDTH_A      => 16,             -- 16-bit data
    ADDR_WIDTH_A            => 16,             -- 16-bit addressing
    READ_RESET_VALUE_A      => "0",            --string
    READ_LATENCY_A          => 1,              --non-negative integer

    -- Port B module generics
    READ_DATA_WIDTH_B       => 16,             --positive integer
    ADDR_WIDTH_B            => 16,              --positive integer
    READ_RESET_VALUE_B      => "0",            --string
    READ_LATENCY_B          => 1               --non-negative integer
    )

    port map (
        -- Port A module ports - DATA
        clka                    => clk,
        rsta                    => rst,
        ena                     => '1',
        regcea                  => '1',   --do not change
        wea                     => wr_mem_en,
        addra                   => addr_dt,
        dina                    => din_dt,
        douta                   => dout_dt,
    
        -- Port B module ports - INSTRUCTION
        clkb                    => clk,
        rstb                    => rst,
        enb                     => '1',
        regceb                  => '1',   --do not change
        addrb                   => addr_ins,
        doutb                   => dout_ins
    );
    -- End of xpm_memory_dpdistram_inst instantiation

end behavioural;