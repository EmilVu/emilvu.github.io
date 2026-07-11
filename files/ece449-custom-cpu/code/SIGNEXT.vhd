library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SIGNEXT_file is
    port(
        --input signals
        raw_addr: in std_logic_vector(8 downto 0); 
        rst : in std_logic; --clock
        clk: in std_logic;  --reset
        --output signals
        ext_addr: out std_logic_vector(15 downto 0)
    );
end SIGNEXT_file;

architecture behavioural of SIGNEXT_file is

--ALU operations 
signal addr   : std_logic_vector(15 downto 0);

begin
    process(clk) begin
       if(clk='1' and clk'event) then 
            if(rst='1') then
                addr <= X"0000";
            else
                addr <= raw_addr(8) & raw_addr(8) & raw_addr(8) & raw_addr(8) & raw_addr(8) & raw_addr(8) & raw_addr & '0';
            end if; 
        end if;
        
        
    end process;
    
    --port signal to outputs
    ext_addr <= addr;
end behavioural;