library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC_file is
    port(
        --input signals
        brch_addr: in std_logic_vector(15 downto 0);  
        brch_en: in std_logic;
        rst: in std_logic;  
        clk: in std_logic;  
        stall: in std_logic;
        --output signal
        CPC: out std_logic_vector(15 downto 0)
    );
end PC_file;

architecture behavioural of PC_file is

--PC signal 
signal current_PC: std_logic_vector(15 downto 0);

begin
    process (clk) begin
        -- clock changes
        if (clk = '0' and clk'event) then
            if(rst='1') then
                current_PC <= X"0000";
            else
                if (stall = '1') then
                    current_PC <= current_PC;
                else
                    if (brch_en = '1') then
                        current_PC <= brch_addr;
                    else
                        current_PC <= std_logic_vector(signed(current_PC) + 2);
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    --port signal to outputs
    CPC <= current_PC;
end behavioural;