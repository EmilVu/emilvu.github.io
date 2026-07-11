library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU_file is
    port(
        --input signals
        in1: in std_logic_vector(15 downto 0); 
        in2: in std_logic_vector(15 downto 0); 
        --alu mode signal
        alu_mode: in std_logic_vector(2 downto 0);
        shift_count: in std_logic_vector(3 downto 0);
        rst : in std_logic; --clock
        clk: in std_logic;  --reset
        hold_flag: in std_logic;
        --output signals
        result: out std_logic_vector(15 downto 0); 
        z_flag: out std_logic; 
        n_flag: out std_logic;
        o_flag: out std_logic
    );
end ALU_file; --nothing

architecture behavioural of ALU_file is

--ALU operations 
signal output   : std_logic_vector(31 downto 0);
signal z        : std_logic;
signal n        : std_logic;
signal o        : std_logic;

begin
    process(clk) begin
        if (clk ='1' and clk'event) then
            if(rst='1') then
                output <= X"00000000";
                z <= '1';
                n <= '0';
                o <= '0';
            else
                -- calculate result
                case alu_mode(2 downto 0) is
                    when "001" => --ADD
                        output <= X"0000" & std_logic_vector(signed(in1) + signed(in2));
                        -- calculate zero flag
                        if signed(in1) + signed(in2) = 0 then
                            z <= '1'; 
                        else
                            z <= '0';
                        end if;
                        -- calculate negative flag
                        if (signed(in1) + signed(in2)) < 0 then
                            n <= '1';
                        else
                            n <= '0';
                        end if;
                        -- calculate overflow flag
                        if (signed(in1) + signed(in2) > X"00007FFF" OR signed(in1) + signed(in2) < X"FFFF1000") then
                            o <= '1';
                        else 
                            o <= '0';
                        end if;
                    when "010" => --SUB
                        output <= X"0000" & std_logic_vector(signed(in1) - signed(in2));
                        -- calculate zero flag
                        if signed(in1) - signed(in2) = 0 then
                            z <= '1'; 
                        else
                            z <= '0';
                        end if;
                        -- calculate negative flag
                        if (signed(in1) + signed(in2)) < 0 then
                            n <= '1';
                        else
                            n <= '0';
                        end if;
                        -- calculate overflow flag
                        if (signed(in1) - signed(in2) > X"00007FFF" OR signed(in1) - signed(in2) < X"FFFF1000") then
                            o <= '1';
                        else 
                            o <= '0';
                        end if;
                    when "011" => --MUL
                        output <= std_logic_vector(signed(in1) * signed(in2));
                        -- calculate zero flag
                        if signed(in1) * signed(in2) = 0 then
                            z <= '1'; 
                        else
                            z <= '0';
                        end if;
                        -- calculate negative flag
                        if (signed(in1) * signed(in2)) < 0 then
                            n <= '1';
                        else
                            n <= '0';
                        end if;
                        -- calculate overflow flag
                        if (signed(in1) * signed(in2) > X"00007FFF" OR signed(in1) * signed(in2) < X"FFFF1000") then
                            o <= '1';
                        else 
                            o <= '0';
                        end if;
                    when "100" => --NAND
                        output <=  X"0000" & (in1 NAND in2);
                        -- calculate zero flag
                        if signed(in1 NAND in2) = 0 then
                            z <= '1'; 
                        else
                            z <= '0';
                        end if;
                        -- calculate negative flag
                        if signed(in1 NAND in2) < 0 then
                            n <= '1';
                        else
                            n <= '0';
                        end if;
                        -- calculate overflow flag
                        o <= '0';
                    when "101" => --SHL (2's complement)             
                        if (shift_count(3 downto 0) = "0000") then
                            output <= X"0000" & in1;
                            -- calculate zero flag
                            if (signed(in1) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1) < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            o <= '0';
                        elsif (shift_count(3 downto 0) = "0001") then
                            output <= X"0000" & in1(14 downto 0) & '0';                   
                            -- calculate zero flag
                            if (signed(in1(14 downto 0) & '0') = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(14 downto 0) & '0') < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15) = '1') then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0010") then
                            output <= X"0000" & in1(13 downto 0) & "00";                   
                            -- calculate zero flag
                            if (signed(in1(13 downto 0) & "00") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(13 downto 0) & "00") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 14) /= "00" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0011") then
                            output <= X"0000" & in1(12 downto 0) & "000";                   
                            -- calculate zero flag
                            if (signed(in1(12 downto 0) & "000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(12 downto 0) & "000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 13) /= "000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if; 
                        elsif (shift_count(3 downto 0) = "0100") then
                            output <= X"0000" & in1(11 downto 0) & "0000";                   
                            -- calculate zero flag
                            if (signed(in1(11 downto 0) & "0000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(11 downto 0) & "0000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 12) /= "0000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0101") then
                            output <= X"0000" & in1(10 downto 0) & "00000";                   
                            -- calculate zero flag
                            if (signed(in1(10 downto 0) & "00000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(10 downto 0) & "00000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 11) /= "00000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if; 
                        elsif (shift_count(3 downto 0) = "0110") then
                            output <= X"0000" & in1(9 downto 0) & "000000";                   
                            -- calculate zero flag
                            if (signed(in1(9 downto 0) & "000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(9 downto 0) & "000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 10) /= "000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0111") then
                            output <= X"0000" & in1(8 downto 0) & "0000000";                   
                            -- calculate zero flag
                            if (signed(in1(8 downto 0) & "0000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(8 downto 0) & "0000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 9) /= "0000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1000") then
                            output <= X"0000" & in1(7 downto 0) & "00000000";                   
                            -- calculate zero flag
                            if (signed(in1(7 downto 0) & "00000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(7 downto 0) & "00000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 8) /= "00000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1001") then
                            output <= X"0000" & in1(6 downto 0) & "000000000";                   
                            -- calculate zero flag
                            if (signed(in1(6 downto 0) & "000000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(6 downto 0) & "000000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 7) /= "000000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1010") then
                            output <= X"0000" & in1(5 downto 0) & "0000000000";                   
                            -- calculate zero flag
                            if (signed(in1(5 downto 0) & "0000000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(5 downto 0) & "0000000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 6) /= "0000000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1011") then
                            output <= X"0000" & in1(4 downto 0) & "00000000000";                   
                            -- calculate zero flag
                            if (signed(in1(4 downto 0) & "00000000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(4 downto 0) & "00000000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 5) /= "00000000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1100") then
                            output <= X"0000" & in1(3 downto 0) & "000000000000";                   
                            -- calculate zero flag
                            if (signed(in1(3 downto 0) & "000000000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(3 downto 0) & "000000000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 4) /= "000000000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1101") then
                            output <= X"0000" & in1(2 downto 0) & "0000000000000";                   
                            -- calculate zero flag
                            if (signed(in1(2 downto 0) & "0000000000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(2 downto 0) & "0000000000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 3) /= "0000000000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1110") then
                            output <= X"0000" & in1(1 downto 0) & "00000000000000";                   
                            -- calculate zero flag
                            if (signed(in1(1 downto 0) & "00000000000000") = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1(1 downto 0) & "00000000000000") < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 2) /= "00000000000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1111") then
                            output <= X"0000" & in1(0) & "000000000000000";                   
                            -- calculate zero flag
                            if (in1(0) = '0') then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (in1(0) = '1') then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                            -- calculate overflow flag
                            if (in1(15 downto 1) /= "000000000000000" ) then
                                o <= '1';
                            else 
                                o <= '0';
                            end if;
                        end if; 
                    when "110" => --SHR (2's complement)
                        o <= '0';
                        n <= '0';
                        if (shift_count(3 downto 0) = "0000") then
                            output <= X"0000" & in1;
                            -- calculate zero flag
                            if (signed(in1) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                            -- calculate negative flag
                            if (signed(in1) < 0) then
                                n <= '1';
                            else
                                n <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0001") then
                            output <= X"0000" & '0' & in1(15 downto 1);                   
                            -- calculate zero flag
                            if (signed('0' & in1(15 downto 1)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0010") then
                            output <= X"0000" & "00" & in1(15 downto 2);                  
                            -- calculate zero flag
                            if (signed("00" & in1(15 downto 2)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0011") then
                            output <= X"0000" & "000" & in1(15 downto 3);                  
                            -- calculate zero flag
                            if (signed("000" & in1(15 downto 3)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if; 
                        elsif (shift_count(3 downto 0) = "0100") then
                            output <= X"0000" & "0000" & in1(15 downto 4);                  
                            -- calculate zero flag
                            if (signed("0000" & in1(15 downto 4)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if; 
                        elsif (shift_count(3 downto 0) = "0101") then
                            output <= X"0000" & "00000" & in1(15 downto 5);                  
                            -- calculate zero flag
                            if (signed("00000" & in1(15 downto 5)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0110") then
                            output <= X"0000" & "000000" & in1(15 downto 6);                  
                            -- calculate zero flag
                            if (signed("000000" & in1(15 downto 6)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "0111") then
                            output <= X"0000" & "0000000" & in1(15 downto 7);                  
                            -- calculate zero flag
                            if (signed("0000000" & in1(15 downto 7)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1000") then
                            output <= X"0000" & "00000000" & in1(15 downto 8);                  
                            -- calculate zero flag
                            if (signed("00000000" & in1(15 downto 8)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1001") then
                            output <= X"0000" & "000000000" & in1(15 downto 9);                  
                            -- calculate zero flag
                            if (signed("000000000" & in1(15 downto 9)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1010") then
                            output <= X"0000" & "0000000000" & in1(15 downto 10);                  
                            -- calculate zero flag
                            if (signed("0000000000" & in1(15 downto 10)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1011") then
                            output <= X"0000" & "00000000000" & in1(15 downto 11);                  
                            -- calculate zero flag
                            if (signed("00000000000" & in1(15 downto 11)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1100") then
                            output <= X"0000" & "000000000000" & in1(15 downto 12);                  
                            -- calculate zero flag
                            if (signed("000000000000" & in1(15 downto 12)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1101") then
                            output <= X"0000" & "0000000000000" & in1(15 downto 13);                  
                            -- calculate zero flag
                            if (signed("0000000000000" & in1(15 downto 13)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1110") then
                            output <= X"0000" & "00000000000000" & in1(15 downto 14);                  
                            -- calculate zero flag
                            if (signed("00000000000000" & in1(15 downto 14)) = 0) then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        elsif (shift_count(3 downto 0) = "1111") then
                            output <= X"0000" & "000000000000000" & in1(15);                  
                            -- calculate zero flag
                            if (in1(15) = '0') then
                                z <= '1'; 
                            else
                                z <= '0';
                            end if;
                        end if;     
                    when "111" => --TEST
                        output <= X"0000" & in1;
                        -- calculate zero flag
                        if signed(in1) = 0 then
                            z <= '1'; 
                        else
                            z <= '0';
                        end if;
                        -- calculate negative flag
                        if signed(in1) < 0 then
                            n <= '1';
                        else
                            n <= '0';
                        end if;
                        -- calculate overflow flag
                        o <= '0';
                    when others => --NOP
                        output <= output;
                        z <= z;
                        n <= n;
                        o <= o;
                end case;
                if (hold_flag = '1') then
                    o <= o;
                end if;
            end if;
        end if;
    end process;
    
    --port signal to outputs
    result <= output(15 downto 0);
    z_flag <= z;
    n_flag <= n;
    o_flag <= o;
end behavioural;
