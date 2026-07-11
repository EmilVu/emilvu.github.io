library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity MUX_file is
    port(
        in1: in std_logic_vector(15 downto 0);
        in2: in std_logic_vector(15 downto 0);
        sel, stall: in std_logic;
        out1: out std_logic_vector(15 downto 0)
    );
end MUX_file;

architecture behavioural of MUX_file is
    begin
    --write operation
    process(sel, in1, in2) begin
        if (stall = '1') then
            out1 <= X"0000";
        else
            if (sel = '0') then
                out1 <= in1;
            else
                out1 <= in2;
            end if;
        end if;
        
    end process;
    --read operation

end behavioural;