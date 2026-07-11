----------------------------------------------------------------------------------
--
-- ECE 449
--
-- Generate video signals for 640x480 graphics screen
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

entity video_timing is
    generic (
        HSYNC_FRONT_PORCH : integer;
        HSYNC_SYNC_PULSE : integer;
        HSYNC_LINE_WIDTH : integer;
        HSYNC_POLARITY : STD_LOGIC;

        VSYNC_FRONT_PORCH : integer;
        VSYNC_SYNC_PULSE : integer;
        VSYNC_FRAME_WIDTH : integer;
        VSYNC_POLARITY : STD_LOGIC;

        BOARD_DIVIDER : INTEGER range 0 to 3;
        SCREEN_X_SIZE : UNSIGNED( 10 downto 0 );
        SCREEN_Y_SIZE : UNSIGNED( 9 downto 0 )
    );
    Port (
        clock : in STD_LOGIC;
        h_sync : out STD_LOGIC;
        v_sync : out STD_LOGIC;
        h_dot : out UNSIGNED( 10 downto 0 );
        v_line : out UNSIGNED( 9 downto 0 );
        video_clock : out STD_LOGIC
    );
end video_timing;

architecture Behavioral of video_timing is

signal clock_25Mhz : STD_LOGIC;

begin


divide_by : process ( clock, clock_25Mhz )

variable count : integer range 0 to 2 := 0;

begin
    if ( rising_edge( clock )) then
        count := count + 1;
        if ( count = BOARD_DIVIDER ) then
            count := 0;
            clock_25Mhz <= not clock_25Mhz;
        end if;
    end if;
end process;



--
-- 640x480
--
-- Horizontal
--    Sync-
--    Visible 640
--    Front porch 16
--    Sync pulse 96
--    Whole line 800
--
-- Vertical
--    Sync-
--    Visible 480
--    Front porch 10
--    Sync pulse 2
--    Whole line 521
--
--
-- 800x600
--
-- Horizontal
--    Sync+
--    Visible 800
--    Front porch 56
--    Sync pulse 120
--    Whole line 1040
--
-- Vertical
--    Sync+
--    Visible 600
--    Front porch 37
--    Sync pulse 6
--    Whole line 666
---
--
--
--

video_clock <= clock_25Mhz;

process ( clock_25Mhz )

variable h_dot_int : UNSIGNED ( 10 downto 0 ) := "00000000000";
variable v_line_int : UNSIGNED ( 9 downto 0 ) := "0000000000";

begin
    if ( rising_edge( clock_25Mhz )) then

        h_dot_int := h_dot_int + "1";


        if (( h_dot_int >= ( SCREEN_X_SIZE + HSYNC_FRONT_PORCH )) and ( h_dot_int < ( SCREEN_X_SIZE + HSYNC_FRONT_PORCH + HSYNC_SYNC_PULSE ))) then
            h_sync <= HSYNC_POLARITY;
        else
            h_sync <= NOT HSYNC_POLARITY;
        end if;

        if ( h_dot_int = ( HSYNC_LINE_WIDTH )) then
            h_dot_int := "00000000000";

            v_line_int := v_line_int + "1";

            if (( v_line_int >= ( SCREEN_Y_SIZE + VSYNC_FRONT_PORCH )) and ( v_line_int < ( SCREEN_Y_SIZE + VSYNC_FRONT_PORCH + VSYNC_SYNC_PULSE ))) then
                v_sync <= VSYNC_POLARITY;
            else
                v_sync <= NOT VSYNC_POLARITY;
            end if;

--
-- For clock of 25.000Mhz use 521 lines as the screen size
-- For clock of 25.175Mhz use 525 lines as the screen size
--
            if ( v_line_int = ( VSYNC_FRAME_WIDTH )) then
                v_line_int := "0000000000";
            end if;

        end if;

        h_dot <= h_dot_int;
        v_line <= v_line_int;
    end if;
end process;

end Behavioral;