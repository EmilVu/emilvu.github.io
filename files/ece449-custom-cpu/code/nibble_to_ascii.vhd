----------------------------------------------------------------------------------
--
-- ECE 449
--
-- Convert nibble to ASCII text
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

entity nibble_to_ascii is
    Generic (
        enabled : STD_LOGIC := '1'
    );
    Port ( value : in STD_LOGIC_VECTOR (3 downto 0);
           d1 : out STD_LOGIC_VECTOR (6 downto 0));
end nibble_to_ascii;

architecture Behavioral of nibble_to_ascii is

begin


process( value )

variable digit : unsigned( 3 downto 0 );

begin
    if ( enabled = '1' ) then
        digit := unsigned( value( 3 downto 0 ));
        if ( digit > 9 ) then
           d1 <= STD_LOGIC_VECTOR( to_unsigned( to_integer( digit ) +16 +7 , 7 ));
        else
           d1 <= STD_LOGIC_VECTOR( to_unsigned( to_integer( digit ) +16, 7 ));
        end if;
    end if;
end process;

end Behavioral;