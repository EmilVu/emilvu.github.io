----------------------------------------------------------------------------------
--
-- ECE 449
--
-- Convert bit to ASCII text
--
-- Version 1.00
--
-- (c)2024 B. Sirna         Dept. of ECE
--                          University of Victoria
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity bit_to_ascii is
    Generic (
        enabled : STD_LOGIC := '1'
    );
    Port ( value : in STD_LOGIC;
        d1 : out STD_LOGIC_VECTOR (6 downto 0));
end bit_to_ascii;

architecture Behavioral of bit_to_ascii is

begin


process( value )

begin
    if ( enabled = '1' ) then
        if ( value = '1' ) then
            d1 <= STD_LOGIC_VECTOR( to_unsigned(character'pos('1') - 32, 7 ));
        else
            d1 <= STD_LOGIC_VECTOR( to_unsigned(character'pos('0') - 32, 7 ));
        end if;
    end if;
end process;

end Behavioral;