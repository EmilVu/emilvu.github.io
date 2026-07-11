library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity REGISTER_file is
    port(
        rst : in std_logic; 
        clk: in std_logic;
        --read signals
        rd_index1, rd_index2 : in std_logic_vector(2 downto 0);
        rd_data1, rd_data2: out std_logic_vector(15 downto 0);
        --write signals
        wr_index: in std_logic_vector(2 downto 0);
        wr_data: in std_logic_vector(15 downto 0);
        wr_enable: in std_logic
    );
end REGISTER_file;

architecture behavioural of register_file is
    type reg_array is array (integer range 0 to 7) of std_logic_vector(15 downto 0);
    --internals signals
    signal reg_file : reg_array; 
    begin
    --write operation
    process(clk)
        begin
        if(clk='1' and clk'event) then 
            if(rst='1') then
                for i in 0 to 7 loop
                    reg_file(i)<= (others => '0');
                end loop;
            else 
                case rd_index1 is
                    when "000" => rd_data1 <= reg_file(0);
                    when "001" => rd_data1 <= reg_file(1);
                    when "010" => rd_data1 <= reg_file(2);
                    when "011" => rd_data1 <= reg_file(3);
                    when "100" => rd_data1 <= reg_file(4);
                    when "101" => rd_data1 <= reg_file(5);
                    when "110" => rd_data1 <= reg_file(6);
                    when others => rd_data1 <= reg_file(7);
                end case;
                
                case rd_index2 is
                    when "000" => rd_data2 <= reg_file(0);
                    when "001" => rd_data2 <= reg_file(1);
                    when "010" => rd_data2 <= reg_file(2);
                    when "011" => rd_data2 <= reg_file(3);
                    when "100" => rd_data2 <= reg_file(4);
                    when "101" => rd_data2 <= reg_file(5);
                    when "110" => rd_data2 <= reg_file(6);
                    when others => rd_data2 <= reg_file(7);
                end case;
                
                if (wr_enable= '1') then
                    case wr_index is
                        when "000" => reg_file(0) <= wr_data;
                        when "001" => reg_file(1) <= wr_data;
                        when "010" => reg_file(2) <= wr_data;
                        when "011" => reg_file(3) <= wr_data;
                        when "100" => reg_file(4) <= wr_data;
                        when "101" => reg_file(5) <= wr_data;
                        when "110" => reg_file(6) <= wr_data;
                        when others => reg_file(7) <= wr_data;
                    end case;
                    
                    if (wr_index = rd_index1) then
                        rd_data1 <= wr_data;
                    elsif (wr_index = rd_index2) then
                        rd_data2 <= wr_data;
                    end if;
                end if;
                
                
            end if;
        end if;
    end process;
    --read operation

end behavioural;





