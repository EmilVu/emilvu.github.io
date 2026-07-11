library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity console is
    Port (

--
-- Stage 1 Fetch
--
        s1_pc : in STD_LOGIC_VECTOR ( 15 downto 0 );
        s1_inst : in STD_LOGIC_VECTOR ( 15 downto 0 );


--
-- Stage 2 Decode
--
        s2_pc : in STD_LOGIC_VECTOR ( 15 downto 0 );
        s2_inst : in STD_LOGIC_VECTOR ( 15 downto 0 );

        s2_reg_a : in STD_LOGIC_VECTOR( 2 downto 0 );
        s2_reg_b : in STD_LOGIC_VECTOR( 2 downto 0 );
        s2_reg_c : in STD_LOGIC_VECTOR( 2 downto 0 );

        s2_reg_a_data : in STD_LOGIC_VECTOR( 15 downto 0 );
        s2_reg_b_data : in STD_LOGIC_VECTOR( 15 downto 0 );
        s2_reg_c_data : in STD_LOGIC_VECTOR( 15 downto 0 );

        s2_immediate : in STD_LOGIC_VECTOR( 15 downto 0 );


--
-- Stage 3 Execute
--
        s3_pc : in STD_LOGIC_VECTOR ( 15 downto 0 );
        s3_inst : in STD_LOGIC_VECTOR ( 15 downto 0 );

        s3_reg_a : in STD_LOGIC_VECTOR( 2 downto 0 );
        s3_reg_b : in STD_LOGIC_VECTOR( 2 downto 0 );
        s3_reg_c : in STD_LOGIC_VECTOR( 2 downto 0 );

        s3_reg_a_data : in STD_LOGIC_VECTOR( 15 downto 0 );
        s3_reg_b_data : in STD_LOGIC_VECTOR( 15 downto 0 );
        s3_reg_c_data : in STD_LOGIC_VECTOR( 15 downto 0 );

        s3_immediate : in STD_LOGIC_VECTOR( 15 downto 0 );

--
-- Branch and memory operation
--
        s3_r_wb : in STD_LOGIC;
        s3_r_wb_data : in STD_LOGIC_VECTOR( 15 downto 0 );

        s3_br_wb : in STD_LOGIC;
        s3_br_wb_address : in STD_LOGIC_VECTOR( 15 downto 0 );

        s3_mr_wr : in STD_LOGIC;
        s3_mr_wr_address : in STD_LOGIC_VECTOR( 15 downto 0 );
        s3_mr_wr_data : in STD_LOGIC_VECTOR( 15 downto 0 );

        s3_mr_rd : in STD_LOGIC;
        s3_mr_rd_address : in STD_LOGIC_VECTOR( 15 downto 0 );

--
-- Stage 4 Memory
--
        s4_pc : in STD_LOGIC_VECTOR( 15 downto 0 );
        s4_inst : in STD_LOGIC_VECTOR( 15 downto 0 );

        s4_reg_a : in STD_LOGIC_VECTOR( 2 downto 0 );

        s4_r_wb : in STD_LOGIC;
        s4_r_wb_data : in STD_LOGIC_VECTOR( 15 downto 0 );

--
-- CPU registers
--

        register_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
        register_1 : in STD_LOGIC_VECTOR ( 15 downto 0 );
        register_2 : in STD_LOGIC_VECTOR ( 15 downto 0 );
        register_3 : in STD_LOGIC_VECTOR ( 15 downto 0 );
        register_4 : in STD_LOGIC_VECTOR ( 15 downto 0 );
        register_5 : in STD_LOGIC_VECTOR ( 15 downto 0 );
        register_6 : in STD_LOGIC_VECTOR ( 15 downto 0 );
        register_7 : in STD_LOGIC_VECTOR ( 15 downto 0 );

--
-- CPU registers overflow flags
--
        register_0_of : in STD_LOGIC;
        register_1_of : in STD_LOGIC;
        register_2_of : in STD_LOGIC;
        register_3_of : in STD_LOGIC;
        register_4_of : in STD_LOGIC;
        register_5_of : in STD_LOGIC;
        register_6_of : in STD_LOGIC;
        register_7_of : in STD_LOGIC;

--
-- CPU Flags
--
        zero_flag : in STD_LOGIC;
        negative_flag : in STD_LOGIC;
        overflow_flag : in STD_LOGIC;

--
-- Debug screen enable
--
        debug : in STD_LOGIC;

--
-- Text console display memory access signals ( clk is the processor clock )
--
        addr_write : in  STD_LOGIC_VECTOR (15 downto 0);
        clk : in  STD_LOGIC;
        data_in : in  STD_LOGIC_VECTOR (15 downto 0);
        en_write : in  STD_LOGIC;

--
-- Video related signals
--
        board_clock : in STD_LOGIC;
        v_sync_signal : out STD_LOGIC;
        h_sync_signal : out STD_LOGIC;
        vga_red : out STD_LOGIC_VECTOR( 3 downto 0 );
        vga_green : out STD_LOGIC_VECTOR( 3 downto 0 );
        vga_blue : out STD_LOGIC_VECTOR( 3 downto 0 )

    );
end console;

architecture Behavioral of console is

--
-- Board related clock settings
--

constant BASYS_3_CLOCK_DIVIDER : INTEGER range 1 to 2 := 2;
constant CYCLONE_II_CLOCK_DIVIDER : INTEGER range 1 to 2 := 1;
constant BOARD_DIVIDER : INTEGER range 0 to 3 := BASYS_3_CLOCK_DIVIDER;

--
-- Instruction Set
--

constant INST_NOP : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 0, 7 ));
constant INST_ADD : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 1, 7 ));
constant INST_SUB : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 2, 7 ));
constant INST_MUL : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 3, 7 ));
constant INST_NAND : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 4, 7 ));

constant INST_SHL : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 5, 7 ));
constant INST_SHR : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 6, 7 ));

constant INST_TEST : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 7, 7 ));
constant INST_OUT : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 32, 7 ));
constant INST_IN : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 33, 7 ));

constant INST_LOAD : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 16, 7 ));
constant INST_STORE : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 17, 7 ));
constant INST_LOADIMM : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 18, 7 ));
constant INST_MOV : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 19, 7 ));

constant INST_BRR : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 64, 7 ));
constant INST_BRR_N : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 65, 7 ));
constant INST_BRR_Z : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 66, 7 ));
constant INST_BR : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 67, 7 ));
constant INST_BR_N : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 68, 7 ));
constant INST_BR_Z : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 69, 7 ));

constant INST_BR_SUB : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 70, 7 ));
constant INST_RETURN : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 71, 7 ));

constant INST_PUSH : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 96, 7 ));
constant INST_POP : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 97, 7 ));
constant INST_LOAD_SP : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 98, 7 ));
constant INST_RTI : STD_LOGIC_VECTOR( 6 downto 0 ) := STD_LOGIC_VECTOR( to_unsigned( 99, 7 ));


--
-- Video timing options
--
-- 800 x 600 @ 50.000MHz
--

constant VSYNC_50_000MHZ_800_600_72 : INTEGER := 72;
constant HSYNC_FRONT_PORCH_50_000MHZ_800_600_72 : INTEGER := 56;
constant HSYNC_SYNC_PULSE_50_000MHZ_800_600_72 : INTEGER := 120;
constant HSYNC_LINE_WIDTH_50_000MHZ_800_600_72 : INTEGER := 1040;
constant HSYNC_POLARITY_50_000MHZ_800_600_72 : STD_LOGIC := '1';


constant VSYNC_FRONT_PORCH_50_000MHZ_800_600_72 : INTEGER := 37;
constant VSYNC_SYNC_PULSE_50_000MHZ_800_600_72 : INTEGER := 6;
constant VSYNC_FRAME_WIDTH_50_000MHZ_800_600_72 : INTEGER := 666;
constant VSYNC_POLARITY_50_000MHZ_800_600_72 : STD_LOGIC := '1';

--
-- 640 x 480 @ 25.000Mhz
--

constant VSYNC_25_000MHZ_640_480_60 : INTEGER := 60;
constant HSYNC_FRONT_PORCH_25_000MHZ_640_480_60 : INTEGER := 16;
constant HSYNC_SYNC_PULSE_25_000MHZ_640_480_60 : INTEGER := 96;
constant HSYNC_LINE_WIDTH_25_000MHZ_640_480_60 : INTEGER := 800;
constant HSYNC_POLARITY_25_000MHZ_640_480_60 : STD_LOGIC := '0';

constant VSYNC_FRONT_PORCH_25_000MHZ_640_480_60 : INTEGER := 10;
constant VSYNC_SYNC_PULSE_25_000MHZ_640_480_60 : INTEGER := 2;
constant VSYNC_FRAME_WIDTH_25_000MHZ_640_480_60 : INTEGER := 521;
constant VSYNC_POLARITY_25_000MHZ_640_480_60 : STD_LOGIC := '0';


--
-- Current video settings
--

constant VSYNC : INTEGER := VSYNC_25_000MHZ_640_480_60;
constant HSYNC_FRONT_PORCH : INTEGER := HSYNC_FRONT_PORCH_25_000MHZ_640_480_60;
constant HSYNC_SYNC_PULSE : INTEGER := HSYNC_SYNC_PULSE_25_000MHZ_640_480_60;
constant HSYNC_LINE_WIDTH : INTEGER := HSYNC_LINE_WIDTH_25_000MHZ_640_480_60;
constant HSYNC_POLARITY : STD_LOGIC := HSYNC_POLARITY_25_000MHZ_640_480_60;

constant VSYNC_FRONT_PORCH : INTEGER := VSYNC_FRONT_PORCH_25_000MHZ_640_480_60;
constant VSYNC_SYNC_PULSE : INTEGER := VSYNC_SYNC_PULSE_25_000MHZ_640_480_60;
constant VSYNC_FRAME_WIDTH : INTEGER := VSYNC_FRAME_WIDTH_25_000MHZ_640_480_60;
constant VSYNC_POLARITY : STD_LOGIC := VSYNC_POLARITY_25_000MHZ_640_480_60;

--
-- Buffer type definition
--

type character_generator is array( 0 to 95 ) of std_logic_vector( 0 to 55);
type video_debug_buffer is array( 0 to 1199 ) of std_logic_vector( 6 downto 0 );
type video_main_buffer is array( 0 to 299 ) of std_logic_vector( 15 downto 0 );
type instruction_set_type is array( 0 to 207 ) of std_logic_vector( 6 downto 0 );


constant SCREEN_X_SIZE_INT : INTEGER := 640;
constant SCREEN_Y_SIZE_INT : INTEGER := 480;
constant SCREEN_X_SIZE : UNSIGNED( 10 downto 0 ) := to_unsigned( SCREEN_X_SIZE_INT, 11 );
constant SCREEN_Y_SIZE : UNSIGNED( 9 downto 0 ) := to_unsigned( 480, 10 );

constant DISPLAY_20_BY_15 : string := "20x15";
constant DISPLAY_40_BY_30 : string := "40x30";

constant DISPLAY_MEMORY_SIZE_20_BY_15 : integer := 20 * 15 * 16;
constant DISPLAY_MEMORY_SIZE_40_BY_30 : integer := 40 * 30 * 16;

constant DISPLAY_MEMORY_LENGTH_20_BY_15 : integer := 9;
constant DISPLAY_MEMORY_LENGTH_40_BY_30 : integer := 11;

constant DEBUG_MEMORY_LENGTH : integer := DISPLAY_MEMORY_LENGTH_40_BY_30;
constant DISPLAY_RESOLUTION : string := DISPLAY_40_BY_30;
constant DISPLAY_MEMORY_SIZE : integer := DISPLAY_MEMORY_SIZE_40_BY_30;
constant DISPLAY_MEMORY_LENGTH : integer := DISPLAY_MEMORY_LENGTH_40_BY_30;

constant instruction_set : instruction_set_type := (
    000 => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    001 => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    002 => STD_LOGIC_VECTOR( to_unsigned(character'pos('P') - 32, 7 )),
    003 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    004 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    005 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    006 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    007 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    008 => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),
    009 => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    010 => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    011 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    012 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    013 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    014 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    015 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    016 => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    017 => STD_LOGIC_VECTOR( to_unsigned(character'pos('U') - 32, 7 )),
    018 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    019 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    020 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    021 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    022 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    023 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    024 => STD_LOGIC_VECTOR( to_unsigned(character'pos('M') - 32, 7 )),
    025 => STD_LOGIC_VECTOR( to_unsigned(character'pos('U') - 32, 7 )),
    026 => STD_LOGIC_VECTOR( to_unsigned(character'pos('L') - 32, 7 )),
    027 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    028 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    029 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    030 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    031 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    032 => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    033 => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),
    034 => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    035 => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    036 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    037 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    038 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    039 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    040 => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    041 => STD_LOGIC_VECTOR( to_unsigned(character'pos('H') - 32, 7 )),
    042 => STD_LOGIC_VECTOR( to_unsigned(character'pos('L') - 32, 7 )),
    043 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    044 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    045 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    046 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    047 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    048 => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    049 => STD_LOGIC_VECTOR( to_unsigned(character'pos('H') - 32, 7 )),
    050 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    051 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    052 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    053 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    054 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    055 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    056 => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    057 => STD_LOGIC_VECTOR( to_unsigned(character'pos('E') - 32, 7 )),
    058 => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    059 => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    060 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    061 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    062 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    063 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    064 => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    065 => STD_LOGIC_VECTOR( to_unsigned(character'pos('U') - 32, 7 )),
    066 => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    067 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    068 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    069 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    070 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    071 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    072 => STD_LOGIC_VECTOR( to_unsigned(character'pos('I') - 32, 7 )),
    073 => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    074 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    075 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    076 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    077 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    078 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    079 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    080 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    081 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    082 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    083 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    084 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    085 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    086 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    087 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    088 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    089 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    090 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    091 => STD_LOGIC_VECTOR( to_unsigned(character'pos('.') - 32, 7 )),
    092 => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    093 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    094 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    095 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    096 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    097 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    098 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    099 => STD_LOGIC_VECTOR( to_unsigned(character'pos('.') - 32, 7 )),
    100 => STD_LOGIC_VECTOR( to_unsigned(character'pos('Z') - 32, 7 )),
    101 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    102 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    103 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    104 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    105 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    106 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    107 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    108 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    109 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    110 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    111 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    112 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    113 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    114 => STD_LOGIC_VECTOR( to_unsigned(character'pos('.') - 32, 7 )),
    115 => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    116 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    117 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    118 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    119 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    120 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    121 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    122 => STD_LOGIC_VECTOR( to_unsigned(character'pos('.') - 32, 7 )),
    123 => STD_LOGIC_VECTOR( to_unsigned(character'pos('Z') - 32, 7 )),
    124 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    125 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    126 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    127 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    128 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    129 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    130 => STD_LOGIC_VECTOR( to_unsigned(character'pos('.') - 32, 7 )),
    131 => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    132 => STD_LOGIC_VECTOR( to_unsigned(character'pos('U') - 32, 7 )),
    133 => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    134 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    135 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    136 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    137 => STD_LOGIC_VECTOR( to_unsigned(character'pos('E') - 32, 7 )),
    138 => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    139 => STD_LOGIC_VECTOR( to_unsigned(character'pos('U') - 32, 7 )),
    140 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    141 => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    142 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    143 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    144 => STD_LOGIC_VECTOR( to_unsigned(character'pos('L') - 32, 7 )),
    145 => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    146 => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),
    147 => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    148 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    149 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    150 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    151 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    152 => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    153 => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    154 => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    155 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    156 => STD_LOGIC_VECTOR( to_unsigned(character'pos('E') - 32, 7 )),
    157 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    158 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    159 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    160 => STD_LOGIC_VECTOR( to_unsigned(character'pos('L') - 32, 7 )),
    161 => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    162 => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),
    163 => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    164 => STD_LOGIC_VECTOR( to_unsigned(character'pos('I') - 32, 7 )),
    165 => STD_LOGIC_VECTOR( to_unsigned(character'pos('M') - 32, 7 )),
    166 => STD_LOGIC_VECTOR( to_unsigned(character'pos('M') - 32, 7 )),
    167 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    168 => STD_LOGIC_VECTOR( to_unsigned(character'pos('M') - 32, 7 )),
    169 => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    170 => STD_LOGIC_VECTOR( to_unsigned(character'pos('V') - 32, 7 )),
    171 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    172 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    173 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    174 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    175 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    176 => STD_LOGIC_VECTOR( to_unsigned(character'pos('P') - 32, 7 )),
    177 => STD_LOGIC_VECTOR( to_unsigned(character'pos('U') - 32, 7 )),
    178 => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    179 => STD_LOGIC_VECTOR( to_unsigned(character'pos('H') - 32, 7 )),
    180 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    181 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    182 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    183 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    184 => STD_LOGIC_VECTOR( to_unsigned(character'pos('P') - 32, 7 )),
    185 => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    186 => STD_LOGIC_VECTOR( to_unsigned(character'pos('P') - 32, 7 )),
    187 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    188 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    189 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    190 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    191 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    192 => STD_LOGIC_VECTOR( to_unsigned(character'pos('L') - 32, 7 )),
    193 => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    194 => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),
    195 => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    196 => STD_LOGIC_VECTOR( to_unsigned(character'pos('.') - 32, 7 )),
    197 => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    198 => STD_LOGIC_VECTOR( to_unsigned(character'pos('P') - 32, 7 )),
    199 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    200 => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    201 => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    202 => STD_LOGIC_VECTOR( to_unsigned(character'pos('I') - 32, 7 )),
    203 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    204 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    205 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    206 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    207 => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 ))
);


constant characters : character_generator  :=  (

0000 => "00000000000000000000000000000000000000000000000000000000",
0001 => "00100000001000000010000000100000001000000000000000100000",
0002 => "01010000010100000101000000000000000000000000000000000000",
0003 => "01010000010100001111100001010000111110000101000001010000",
0004 => "00100000011110001010000001110000001010001111000000100000",
0005 => "11000000110010000001000000100000010000001001100000011000",
0006 => "01100000100100001010000001000000101010001001000001101000",
0007 => "01100000001000000100000000000000000000000000000000000000",
0008 => "00010000001000000100000001000000010000000010000000010000",
0009 => "01000000001000000001000000010000000100000010000001000000",
0010 => "00000000001000001010100001110000101010000010000000000000",
0011 => "00000000001000000010000011111000001000000010000000000000",
0012 => "00000000000000000000000000000000011000000010000001000000",
0013 => "00000000000000000000000011111000000000000000000000000000",
0014 => "00000000000000000000000000000000000000000110000001100000",
0015 => "00000000000010000001000000100000010000001000000000000000",
0016 => "01110000100010001001100010101000110010001000100001110000",
0017 => "00100000011000000010000000100000001000000010000001110000",
0018 => "01110000100010000000100000010000001000000100000011111000",
0019 => "11111000000100000010000000010000000010001000100001110000",
0020 => "00010000001100000101000010010000111110000001000000010000",
0021 => "11111000100000001111000000001000000010001000100001110000",
0022 => "00110000010000001000000011110000100010001000100001110000",
0023 => "11111000100010000000100000010000001000000010000000100000",
0024 => "01110000100010001000100001110000100010001000100001110000",
0025 => "01110000100010001000100001111000000010000001000001100000",
0026 => "00000000011000000110000000000000011000000110000000000000",
0027 => "00000000011000000110000000000000011000000010000001000000",
0028 => "00010000001000000100000010000000010000000010000000010000",
0029 => "00000000000000001111100000000000111110000000000000000000",
0030 => "01000000001000000001000000001000000100000010000001000000",
0031 => "01110000100010000000100000010000001000000000000000100000",
0032 => "01110000100010000000100001101000101010001010100001110000",
0033 => "01110000100010001000100010001000111110001000100010001000",
0034 => "11110000100010001000100011110000100010001000100011110000",
0035 => "01110000100010001000000010000000100000001000100001110000",
0036 => "11100000100100001000100010001000100010001001000011100000",
0037 => "11111000100000001000000011110000100000001000000011111000",
0038 => "11111000100000001000000011110000100000001000000010000000",
0039 => "01110000100010001000000010111000100010001000100001111000",
0040 => "10001000100010001000100011111000100010001000100010001000",
0041 => "01110000001000000010000000100000001000000010000011111000",
0042 => "00111000000100000001000000010000000100001001000001100000",
0043 => "10001000100100001010000011000000101000001001000010001000",
0044 => "10000000100000001000000010000000100000001000000011111000",
0045 => "10001000110110001010100010101000100010001000100010001000",
0046 => "10001000100010001100100010101000100110001000100010001000",
0047 => "01110000100010001000100010001000100010001000100001110000",
0048 => "11110000100010001000100011110000100000001000000010000000",
0049 => "01110000100010001000100010001000101010001001000001101000",
0050 => "11110000100010001000100011110000101000001001000010001000",
0051 => "01111000100000001000000001110000000010000000100011110000",
0052 => "11111000001000000010000000100000001000000010000000100000",
0053 => "10001000100010001000100010001000100010001000100001110000",
0054 => "10001000100010001000100010001000100010000101000000100000",
0055 => "10001000100010001000100010101000101010001010100001010000",
0056 => "10001000100010000101000000100000010100001000100010001000",
0057 => "10001000100010001000100001010000001000000010000000100000",
0058 => "11111000000010000001000000100000010000001000000011111000",
0059 => "11000000100000001000000010000000100000001000000011000000",
0060 => "10001000010100001111100000100000111110000010000000100000",
0061 => "00011000000010000000100000001000000010000000100000011000",
0062 => "00100000010100001000100000000000000000000000000000000000",
0063 => "00000000000000000000000000000000000000000000000011111000",
0064 => "01000000001000000001000000000000000000000000000000000000",
0065 => "00000000000000000111000000001000011110001000100001111000",
0066 => "10000000100000001011000011001000100010001000100011110000",
0067 => "00000000000000000111000010000000100000001000100001110000",
0068 => "00001000000010000110100010011000100010001000100001111000",
0069 => "00000000000000000111000010001000111110001000000001110000",
0070 => "00110000010010000100000011100000010000000100000001000000",
0071 => "00000000011110001000100010001000011110000000100001110000",
0072 => "10000000100000001011000011001000100010001000100010001000",
0073 => "00100000000000000110000000100000001000000010000001110000",
0074 => "00010000000000000011000000010000000100001001000001100000",
0075 => "10000000100000001001000010100000110000001010000010010000",
0076 => "01100000001000000010000000100000001000000010000001110000",
0077 => "00000000000000001101000010101000101010001000100010001000",
0078 => "00000000000000001011000011001000100010001000100010001000",
0079 => "00000000000000000111000010001000100010001000100001110000",
0080 => "00000000000000001111000010001000111100001000000010000000",
0081 => "00000000000000000110100010011000011110000000100000001000",
0082 => "00000000000000001011000011001000100000001000000010000000",
0083 => "00000000000000000111000010000000011100000000100011110000",
0084 => "01000000010000001110000001000000010000000100100000110000",
0085 => "00000000000000001000100010001000100010001001100001101000",
0086 => "00000000000000001000100010001000100010000101000000100000",
0087 => "00000000000000001000100010101000101010001010100001010000",
0088 => "00000000000000001000100001010000001000000101000010001000",
0089 => "00000000000000001000100010001000011110000000100001110000",
0090 => "00000000000000001111100000010000001000000100000011111000",
0091 => "00010000001000000010000001000000001000000010000000010000",
0092 => "00100000001000000010000000100000001000000010000000100000",
0093 => "01000000001000000010000000010000001000000010000001000000",
0094 => "00000000001000000001000011111000000100000010000000000000",
0095 => "00000000001000000100000011111000010000000010000000000000"
);


component video_timing is
    generic (
        HSYNC_POLARITY : STD_LOGIC;
        VSYNC_POLARITY : STD_LOGIC;
        HSYNC_FRONT_PORCH : integer;
        HSYNC_SYNC_PULSE : integer;
        HSYNC_LINE_WIDTH : integer;

        VSYNC_FRONT_PORCH : integer;
        VSYNC_SYNC_PULSE : integer;
        VSYNC_FRAME_WIDTH : integer;

        BOARD_DIVIDER : INTEGER range 0 to 3;
        SCREEN_X_SIZE : UNSIGNED( 10 downto 0 );
        SCREEN_Y_SIZE : UNSIGNED( 9 downto 0 )
    );
    port (
        clock : in STD_LOGIC;
        h_sync : out STD_LOGIC;
        v_sync : out STD_LOGIC;
        h_dot : out UNSIGNED( 10 downto 0 );
        v_line : out UNSIGNED( 9 downto 0 );
        video_clock : out STD_LOGIC
    );
end component;

component word_to_ascii is
    generic (
        enabled : STD_LOGIC := '1'
    );
    port (
       value : in STD_LOGIC_VECTOR (15 downto 0);
       d1 : out STD_LOGIC_VECTOR (6 downto 0);
       d2 : out STD_LOGIC_VECTOR (6 downto 0);
       d3 : out STD_LOGIC_VECTOR (6 downto 0);
       d4 : out STD_LOGIC_VECTOR (6 downto 0)
    );
end component;

component byte_to_ascii is
    generic (
        enabled : STD_LOGIC := '1'
    );
    port (
       value : in STD_LOGIC_VECTOR (7 downto 0);
       d1 : out STD_LOGIC_VECTOR (6 downto 0);
       d2 : out STD_LOGIC_VECTOR (6 downto 0)
    );
end component;

component nibble_to_ascii is
    generic (
        enabled : STD_LOGIC := '1'
    );
    port (
        value : in STD_LOGIC_VECTOR( 3 downto 0);
        d1 : out STD_LOGIC_VECTOR (6 downto 0)
    );
end component;

component bit_to_ascii is
    generic (
        enabled : STD_LOGIC := '1'
    );
    port (
        value : in STD_LOGIC;
        d1 : out STD_LOGIC_VECTOR (6 downto 0)
    );
end component;


signal offset : unsigned( 9 downto 0 );
signal char_data : integer;

signal display_address : STD_LOGIC_VECTOR( ( DEBUG_MEMORY_LENGTH -1 ) downto 0 ) := ( others => '0' );
signal display_data : STD_LOGIC_VECTOR( 15 downto 0 );

signal Hdot : UNSIGNED ( 10 downto 0);
signal Vline : UNSIGNED (9 downto 0);

signal Hdot_delayed : UNSIGNED ( 10 downto 0);
signal Vline_delayed : UNSIGNED (9 downto 0);
signal Active : STD_LOGIC;

signal h_sync : STD_LOGIC;
signal v_sync : STD_LOGIC;
signal video_clock : STD_LOGIC;
signal ram_write_enable : STD_LOGIC_VECTOR( 0 downto 0 ) := "1";

--
-- 40 x 32 text character buffer
--
signal main_buffer : video_main_buffer;

--
-- initialize debug display static text
--

signal debug_buffer : video_debug_buffer := (
    (( 2*40) +  2) => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    (( 2*40) +  3) => STD_LOGIC_VECTOR( to_unsigned(character'pos('P') - 32, 7 )),
    (( 2*40) +  4) => STD_LOGIC_VECTOR( to_unsigned(character'pos('C') - 32, 7 )),
    (( 2*40) +  5) => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    (( 2*40) +  7) => STD_LOGIC_VECTOR( to_unsigned(character'pos('I') - 32, 7 )),
    (( 2*40) +  8) => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    (( 2*40) +  9) => STD_LOGIC_VECTOR( to_unsigned(character'pos('S') - 32, 7 )),
    (( 2*40) + 10) => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),

    (( 1*40) + 12) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    (( 2*40) + 12) => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),

    (( 1*40) + 13) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    (( 2*40) + 13) => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),

    (( 1*40) + 14) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    (( 2*40) + 14) => STD_LOGIC_VECTOR( to_unsigned(character'pos('C') - 32, 7 )),

    (( 1*40) + 17) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    (( 1*40) + 18) => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),

    (( 1*40) + 22) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    (( 1*40) + 23) => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),

    (( 1*40) + 27) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    (( 1*40) + 28) => STD_LOGIC_VECTOR( to_unsigned(character'pos('C') - 32, 7 )),


    (( 2*40) + 16) => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    (( 2*40) + 17) => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),
    (( 2*40) + 18) => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    (( 2*40) + 19) => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),

    (( 2*40) + 21) => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    (( 2*40) + 22) => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),
    (( 2*40) + 23) => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    (( 2*40) + 24) => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),

    (( 2*40) + 26) => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    (( 2*40) + 27) => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),
    (( 2*40) + 28) => STD_LOGIC_VECTOR( to_unsigned(character'pos('T') - 32, 7 )),
    (( 2*40) + 29) => STD_LOGIC_VECTOR( to_unsigned(character'pos('A') - 32, 7 )),

    (( 2*40) + 31) => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),
    (( 2*40) + 32) => STD_LOGIC_VECTOR( to_unsigned(character'pos('I') - 32, 7 )),
    (( 2*40) + 33) => STD_LOGIC_VECTOR( to_unsigned(character'pos('M') - 32, 7 )),
    (( 2*40) + 34) => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 )),

    (( 4*40) +  0) => STD_LOGIC_VECTOR( to_unsigned(character'pos('F') - 32, 7 )),
    (( 4*40) +  1) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),


    (( 8*40) +  0) => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    (( 8*40) +  1) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((12*40) +  0) => STD_LOGIC_VECTOR( to_unsigned(character'pos('E') - 32, 7 )),
    ((12*40) +  1) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((13*40) +  8) => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    ((13*40) +  9) => STD_LOGIC_VECTOR( to_unsigned(character'pos('W') - 32, 7 )),
    ((13*40) + 10) => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    ((13*40) + 11) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((13*40) + 20) => STD_LOGIC_VECTOR( to_unsigned(character'pos('M') - 32, 7 )),
    ((13*40) + 21) => STD_LOGIC_VECTOR( to_unsigned(character'pos('W') - 32, 7 )),
    ((13*40) + 22) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((13*40) + 23) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((14*40) +  8) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((14*40) +  9) => STD_LOGIC_VECTOR( to_unsigned(character'pos('W') - 32, 7 )),
    ((14*40) + 10) => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    ((14*40) + 11) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((14*40) + 20) => STD_LOGIC_VECTOR( to_unsigned(character'pos('M') - 32, 7 )),
    ((14*40) + 21) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((14*40) + 22) => STD_LOGIC_VECTOR( to_unsigned(character'pos('D') - 32, 7 )),
    ((14*40) + 23) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((17*40) +  8) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((17*40) +  9) => STD_LOGIC_VECTOR( to_unsigned(character'pos('W') - 32, 7 )),
    ((17*40) + 10) => STD_LOGIC_VECTOR( to_unsigned(character'pos('B') - 32, 7 )),
    ((17*40) + 11) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),


    ((16*40) +  0) => STD_LOGIC_VECTOR( to_unsigned(character'pos('M') - 32, 7 )),
    ((16*40) +  1) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((26*40) +  14) => STD_LOGIC_VECTOR( to_unsigned(character'pos('Z') - 32, 7 )),
    ((26*40) +  15) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((26*40) +  18) => STD_LOGIC_VECTOR( to_unsigned(character'pos('N') - 32, 7 )),
    ((26*40) +  19) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((26*40) +  22) => STD_LOGIC_VECTOR( to_unsigned(character'pos('O') - 32, 7 )),
    ((26*40) +  23) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),


    ((28*40) +  0) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((28*40) +  1) => STD_LOGIC_VECTOR( to_unsigned(character'pos('0') - 32, 7 )),
    ((28*40) +  2) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((28*40) + 10) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((28*40) + 11) => STD_LOGIC_VECTOR( to_unsigned(character'pos('1') - 32, 7 )),
    ((28*40) + 12) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((28*40) + 20) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((28*40) + 21) => STD_LOGIC_VECTOR( to_unsigned(character'pos('2') - 32, 7 )),
    ((28*40) + 22) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((28*40) + 30) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((28*40) + 31) => STD_LOGIC_VECTOR( to_unsigned(character'pos('3') - 32, 7 )),
    ((28*40) + 32) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((29*40) +  0) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((29*40) +  1) => STD_LOGIC_VECTOR( to_unsigned(character'pos('4') - 32, 7 )),
    ((29*40) +  2) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((29*40) + 10) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((29*40) + 11) => STD_LOGIC_VECTOR( to_unsigned(character'pos('5') - 32, 7 )),
    ((29*40) + 12) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((29*40) + 20) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((29*40) + 21) => STD_LOGIC_VECTOR( to_unsigned(character'pos('6') - 32, 7 )),
    ((29*40) + 22) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    ((29*40) + 30) => STD_LOGIC_VECTOR( to_unsigned(character'pos('R') - 32, 7 )),
    ((29*40) + 31) => STD_LOGIC_VECTOR( to_unsigned(character'pos('7') - 32, 7 )),
    ((29*40) + 32) => STD_LOGIC_VECTOR( to_unsigned(character'pos(':') - 32, 7 )),

    others => STD_LOGIC_VECTOR( to_unsigned(character'pos(' ') - 32, 7 ))
);


signal opcode_index : integer range 0 to 256;

signal s1_opcode : STD_LOGIC_VECTOR( 6 downto 0 );
signal s2_opcode : STD_LOGIC_VECTOR( 6 downto 0 );
signal s3_opcode : STD_LOGIC_VECTOR( 6 downto 0 );
signal s4_opcode : STD_LOGIC_VECTOR( 6 downto 0 );
signal opcode : STD_LOGIC_VECTOR( 6 downto 0 );

begin

s1_opcode <= s1_inst( 15 downto 9 );
s2_opcode <= s2_inst( 15 downto 9 );
s3_opcode <= s3_inst( 15 downto 9 );
s4_opcode <= s4_inst( 15 downto 9 );

--
-- Update the instruction text based on the current vertical line being displayed
--

debug_buffer(( 5*40) +  0) <= instruction_set( opcode_index );
debug_buffer(( 5*40) +  1) <= instruction_set( opcode_index + 1 );
debug_buffer(( 5*40) +  2) <= instruction_set( opcode_index + 2 );
debug_buffer(( 5*40) +  3) <= instruction_set( opcode_index + 3 );
debug_buffer(( 5*40) +  4) <= instruction_set( opcode_index + 4 );
debug_buffer(( 5*40) +  5) <= instruction_set( opcode_index + 5 );
debug_buffer(( 5*40) +  6) <= instruction_set( opcode_index + 6 );
debug_buffer(( 5*40) +  7) <= instruction_set( opcode_index + 7 );

debug_buffer(( 9*40) +  0) <= instruction_set( opcode_index );
debug_buffer(( 9*40) +  1) <= instruction_set( opcode_index + 1 );
debug_buffer(( 9*40) +  2) <= instruction_set( opcode_index + 2 );
debug_buffer(( 9*40) +  3) <= instruction_set( opcode_index + 3 );
debug_buffer(( 9*40) +  4) <= instruction_set( opcode_index + 4 );
debug_buffer(( 9*40) +  5) <= instruction_set( opcode_index + 5 );
debug_buffer(( 9*40) +  6) <= instruction_set( opcode_index + 6 );
debug_buffer(( 9*40) +  7) <= instruction_set( opcode_index + 7 );

debug_buffer(( 13*40) +  0) <= instruction_set( opcode_index );
debug_buffer(( 13*40) +  1) <= instruction_set( opcode_index + 1 );
debug_buffer(( 13*40) +  2) <= instruction_set( opcode_index + 2 );
debug_buffer(( 13*40) +  3) <= instruction_set( opcode_index + 3 );
debug_buffer(( 13*40) +  4) <= instruction_set( opcode_index + 4 );
debug_buffer(( 13*40) +  5) <= instruction_set( opcode_index + 5 );
debug_buffer(( 13*40) +  6) <= instruction_set( opcode_index + 6 );
debug_buffer(( 13*40) +  7) <= instruction_set( opcode_index + 7 );

debug_buffer(( 17*40) +  0) <= instruction_set( opcode_index );
debug_buffer(( 17*40) +  1) <= instruction_set( opcode_index + 1 );
debug_buffer(( 17*40) +  2) <= instruction_set( opcode_index + 2 );
debug_buffer(( 17*40) +  3) <= instruction_set( opcode_index + 3 );
debug_buffer(( 17*40) +  4) <= instruction_set( opcode_index + 4 );
debug_buffer(( 17*40) +  5) <= instruction_set( opcode_index + 5 );
debug_buffer(( 17*40) +  6) <= instruction_set( opcode_index + 6 );
debug_buffer(( 17*40) +  7) <= instruction_set( opcode_index + 7 );


--
-- Determine the instruction text to display based on the opcode
--

process( opcode )
begin
    if ( opcode = INST_NOP ) then
        opcode_index <= 0;
    elsif ( opcode = INST_ADD ) then
        opcode_index <= 8;

    elsif ( opcode = INST_SUB ) then
        opcode_index <= 16;

    elsif ( opcode = INST_MUL ) then
        opcode_index <= 24;

    elsif ( opcode = INST_NAND ) then
        opcode_index <= 32;

    elsif ( opcode = INST_SHL ) then
        opcode_index <= 40;

    elsif ( opcode = INST_SHR ) then
        opcode_index <= 48;

    elsif ( opcode = INST_TEST ) then
        opcode_index <= 56;

    elsif ( opcode = INST_OUT ) then
        opcode_index <= 64;

    elsif ( opcode = INST_IN ) then
        opcode_index <= 72;

    elsif ( opcode = INST_BRR ) then
        opcode_index <= 80;

    elsif ( opcode = INST_BRR_N ) then
        opcode_index <= 88;

    elsif ( opcode = INST_BRR_Z ) then
        opcode_index <= 96;

    elsif ( opcode = INST_BR ) then
        opcode_index <= 104;

    elsif ( opcode = INST_BR_N ) then
        opcode_index <= 112;

    elsif ( opcode = INST_BR_Z ) then
        opcode_index <= 120;

    elsif ( opcode = INST_BR_SUB ) then
        opcode_index <= 128;

    elsif ( opcode = INST_RETURN ) then
        opcode_index <= 136;

    elsif ( opcode = INST_LOAD ) then
        opcode_index <= 144;

    elsif( opcode = INST_STORE ) then
        opcode_index <= 152;

    elsif ( opcode = INST_LOADIMM ) then
        opcode_index <= 160;

    elsif (  opcode = INST_MOV ) then
        opcode_index <= 168;

    elsif (  opcode = INST_PUSH ) then
        opcode_index <= 176;

    elsif (  opcode = INST_POP ) then
        opcode_index <= 184;

    elsif (  opcode = INST_LOAD_SP ) then
        opcode_index <= 192;

    elsif (  opcode = INST_RTI ) then
        opcode_index <= 200;

    else
        opcode_index <= 0;
    end if;
end process;



h_sync_signal <= h_sync;
v_sync_signal <= v_sync;

timing : video_timing
generic map
(

    HSYNC_FRONT_PORCH => HSYNC_FRONT_PORCH,
    HSYNC_SYNC_PULSE => HSYNC_SYNC_PULSE,
    HSYNC_LINE_WIDTH => HSYNC_LINE_WIDTH,
    HSYNC_POLARITY => HSYNC_POLARITY,

    VSYNC_FRONT_PORCH => VSYNC_FRONT_PORCH,
    VSYNC_SYNC_PULSE => VSYNC_SYNC_PULSE,
    VSYNC_FRAME_WIDTH => VSYNC_FRAME_WIDTH,
    VSYNC_POLARITY => VSYNC_POLARITY,

    BOARD_DIVIDER => BOARD_DIVIDER,
    SCREEN_X_SIZE => SCREEN_X_SIZE,
    SCREEN_Y_SIZE => SCREEN_Y_SIZE
)
port map
(
    clock => board_clock,
    h_sync => h_sync,
    v_sync => v_sync,
    h_dot => Hdot,
    v_line => Vline,
    video_clock => video_clock
);


--
-- Write data to the main display buffer
--

w1 : process( clk, addr_write, data_in, en_write )
begin
    if ( rising_edge( clk )) then
        if (( addr_write( 15 downto 9 ) = "1111110" ) and ( en_write = '1' )) then
            main_buffer(to_integer(unsigned(addr_write( 8 downto 0 )))) <= data_in( 15 downto 8 ) & STD_LOGIC_VECTOR( UNSIGNED( data_in( 7 downto 0 )) - to_unsigned( 32, 8 ));
        end if;
    end if;
end process;

--
-- Stage 1 fetch
--

s1_pc_map : word_to_ascii port map (
    value => s1_pc,
    d1 => debug_buffer(( 4*40 ) + 2 ),
    d2 => debug_buffer(( 4*40 ) + 3 ),
    d3 => debug_buffer(( 4*40 ) + 4 ),
    d4 => debug_buffer(( 4*40 ) + 5 )
);

s1_inst_map : word_to_ascii port map (
    value => s1_inst,
    d1 => debug_buffer(( 4*40 ) + 7 ),
    d2 => debug_buffer(( 4*40 ) + 8 ),
    d3 => debug_buffer(( 4*40 ) + 9 ),
    d4 => debug_buffer(( 4*40 ) +10 )
);


--
-- Stage 2 decode
--

s2_pc_map : word_to_ascii port map (
    value => s2_pc,
    d1 => debug_buffer(( 8*40 ) + 2 ),
    d2 => debug_buffer(( 8*40 ) + 3 ),
    d3 => debug_buffer(( 8*40 ) + 4 ),
    d4 => debug_buffer(( 8*40 ) + 5 )
);

s2_inst_map : word_to_ascii port map (
    value => s2_inst,
    d1 => debug_buffer(( 8*40 ) + 7 ),
    d2 => debug_buffer(( 8*40 ) + 8 ),
    d3 => debug_buffer(( 8*40 ) + 9 ),
    d4 => debug_buffer(( 8*40 ) +10 )
);

s2_reg_a_map : nibble_to_ascii port map (
    value(3) => '0',
    value( 2  downto 0 ) => s2_reg_a,
    d1 => debug_buffer(( 8*40 ) +12 )
);


s2_reg_b_map : nibble_to_ascii port map (
    value(3) => '0',
    value( 2  downto 0 ) => s2_reg_b,
    d1 => debug_buffer(( 8*40 ) +13 )
);


s2_reg_c_map : nibble_to_ascii port map (
    value(3) => '0',
    value( 2  downto 0 ) => s2_reg_c,
    d1 => debug_buffer(( 8*40 ) +14 )
);

s2_reg_a_data_map : word_to_ascii port map (
    value => s2_reg_a_data,
    d1 => debug_buffer(( 8*40 ) +16 ),
    d2 => debug_buffer(( 8*40 ) +17 ),
    d3 => debug_buffer(( 8*40 ) +18 ),
    d4 => debug_buffer(( 8*40 ) +19 )
);

s2_reg_b_data_map : word_to_ascii port map (
    value => s2_reg_b_data,
    d1 => debug_buffer(( 8*40 ) +21 ),
    d2 => debug_buffer(( 8*40 ) +22 ),
    d3 => debug_buffer(( 8*40 ) +23 ),
    d4 => debug_buffer(( 8*40 ) +24 )
);

s2_reg_c_data_map : word_to_ascii port map (
    value => s2_reg_c_data,
    d1 => debug_buffer(( 8*40 ) +26 ),
    d2 => debug_buffer(( 8*40 ) +27 ),
    d3 => debug_buffer(( 8*40 ) +28 ),
    d4 => debug_buffer(( 8*40 ) +29 )
);

s2_reg_immediate_map : word_to_ascii port map (
    value => s2_immediate,
    d1 => debug_buffer(( 8*40 ) +31 ),
    d2 => debug_buffer(( 8*40 ) +32 ),
    d3 => debug_buffer(( 8*40 ) +33 ),
    d4 => debug_buffer(( 8*40 ) +34 )
);



--
-- Stage 3 Execute
--

s3_pc_map : word_to_ascii port map (
    value => s3_pc,
    d1 => debug_buffer((12*40 ) + 2 ),
    d2 => debug_buffer((12*40 ) + 3 ),
    d3 => debug_buffer((12*40 ) + 4 ),
    d4 => debug_buffer((12*40 ) + 5 )
);

s3_inst_map : word_to_ascii port map (
    value => s3_inst,
    d1 => debug_buffer(( 12*40 ) + 7 ),
    d2 => debug_buffer(( 12*40 ) + 8 ),
    d3 => debug_buffer(( 12*40 ) + 9 ),
    d4 => debug_buffer(( 12*40 ) +10 )
);

s3_reg_a_map : nibble_to_ascii port map (
    value(3) => '0',
    value( 2  downto 0 ) => s3_reg_a,
    d1 => debug_buffer((12*40 ) +12 )
);

s3_reg_b_map : nibble_to_ascii port map (
    value(3) => '0',
    value( 2  downto 0 ) => s3_reg_b,
    d1 => debug_buffer((12*40 ) +13 )
);

s3_reg_c_map : nibble_to_ascii port map (
    value(3) => '0',
    value( 2  downto 0 ) => s3_reg_c,
    d1 => debug_buffer((12*40 ) +14 )
);

s3_reg_a_data_map : word_to_ascii port map (
    value => s3_reg_a_data,
    d1 => debug_buffer((12*40 ) +16 ),
    d2 => debug_buffer((12*40 ) +17 ),
    d3 => debug_buffer((12*40 ) +18 ),
    d4 => debug_buffer((12*40 ) +19 )
);

s3_reg_b_data_map : word_to_ascii port map (
    value => s3_reg_b_data,
    d1 => debug_buffer((12*40 ) +21 ),
    d2 => debug_buffer((12*40 ) +22 ),
    d3 => debug_buffer((12*40 ) +23 ),
    d4 => debug_buffer((12*40 ) +24 )
);

s3_reg_c_data_map : word_to_ascii port map (
    value => s3_reg_c_data,
    d1 => debug_buffer((12*40 ) +26 ),
    d2 => debug_buffer((12*40 ) +27 ),
    d3 => debug_buffer((12*40 ) +28 ),
    d4 => debug_buffer((12*40 ) +29 )
);

s3_reg_immediate_map : word_to_ascii port map (
    value => s3_immediate,
    d1 => debug_buffer((12*40 ) +31 ),
    d2 => debug_buffer((12*40 ) +32 ),
    d3 => debug_buffer((12*40 ) +33 ),
    d4 => debug_buffer((12*40 ) +34 )
);

s3_br_wb_map : bit_to_ascii port map (
    value => s3_br_wb,
    d1 => debug_buffer(( 13*40 ) + 12 )
);

s3_br_wr_address_map : word_to_ascii port map (
    value => s3_br_wb_address,
    d1 => debug_buffer(( 13*40 ) +14 ),
    d2 => debug_buffer(( 13*40 ) +15 ),
    d3 => debug_buffer(( 13*40 ) +16 ),
    d4 => debug_buffer(( 13*40 ) +17 )
);

s3_mr_wr_map : bit_to_ascii port map (
    value => s3_mr_wr,
    d1 => debug_buffer(( 13*40 ) + 24 )
);

s3_mr_wr_address_map : word_to_ascii port map (
    value => s3_mr_wr_address,
    d1 => debug_buffer(( 13*40 ) +26 ),
    d2 => debug_buffer(( 13*40 ) +27 ),
    d3 => debug_buffer(( 13*40 ) +28 ),
    d4 => debug_buffer(( 13*40 ) +29 )
);

s3_mr_wr_data_map : word_to_ascii port map (
    value => s3_mr_wr_data,
    d1 => debug_buffer(( 13*40 ) +31 ),
    d2 => debug_buffer(( 13*40 ) +32 ),
    d3 => debug_buffer(( 13*40 ) +33 ),
    d4 => debug_buffer(( 13*40 ) +34 )
);

s3_r_wb_map : bit_to_ascii port map (
    value => s3_r_wb,
    d1 => debug_buffer(( 14*40 ) + 12 )
);

s3_r_wb_data_map : word_to_ascii port map (
    value => s3_r_wb_data,
    d1 => debug_buffer(( 14*40 ) +14 ),
    d2 => debug_buffer(( 14*40 ) +15 ),
    d3 => debug_buffer(( 14*40 ) +16 ),
    d4 => debug_buffer(( 14*40 ) +17 )
);

s3_mr_rd_map : bit_to_ascii port map (
    value => s3_mr_rd,
    d1 => debug_buffer(( 14*40 ) + 24 )
);

s3_mr_rd_address_map : word_to_ascii port map (
    value => s3_mr_rd_address,
    d1 => debug_buffer(( 14*40 ) +26 ),
    d2 => debug_buffer(( 14*40 ) +27 ),
    d3 => debug_buffer(( 14*40 ) +28 ),
    d4 => debug_buffer(( 14*40 ) +29 )
);

--
--
-- Stage 4 Memory

s4_pc_map : word_to_ascii port map (
    value => s4_pc,
    d1 => debug_buffer((16*40 ) + 2 ),
    d2 => debug_buffer((16*40 ) + 3 ),
    d3 => debug_buffer((16*40 ) + 4 ),
    d4 => debug_buffer((16*40 ) + 5 )
);

s4_inst_map : word_to_ascii port map (
    value => s4_inst,
    d1 => debug_buffer(( 16*40 ) + 7 ),
    d2 => debug_buffer(( 16*40 ) + 8 ),
    d3 => debug_buffer(( 16*40 ) + 9 ),
    d4 => debug_buffer(( 16*40 ) +10 )
);

s4_reg_a_map : nibble_to_ascii port map (
    value(3) => '0',
    value( 2  downto 0 ) => s4_reg_a,
    d1 => debug_buffer((16*40 ) +12 )
);

s4_r_wb_map : bit_to_ascii port map (
    value => s4_r_wb,
    d1 => debug_buffer(( 17*40 ) + 12 )
);

s4_r_wb_data_map : word_to_ascii port map (
    value => s4_r_wb_data,
    d1 => debug_buffer(( 17*40 ) +14 ),
    d2 => debug_buffer(( 17*40 ) +15 ),
    d3 => debug_buffer(( 17*40 ) +16 ),
    d4 => debug_buffer(( 17*40 ) +17 )
);

--
-- CPU flags
--

zero_flag_map : bit_to_ascii port map (
    value => zero_flag,
    d1 => debug_buffer(( 26*40 ) + 16 )
);

negative_flag_map : bit_to_ascii port map (
    value => zero_flag,
    d1 => debug_buffer(( 26*40 ) + 20 )
);

overflow_flag_map : bit_to_ascii port map (
    value => overflow_flag,
    d1 => debug_buffer(( 26*40 ) + 24 )
);

--
-- CPU registers
--

register_0_of_map : bit_to_ascii port map (
    value => register_0_of,
    d1 => debug_buffer(( 28*40 ) + 3 )
);

register_0_map : word_to_ascii port map (
    value => register_0,
    d1 => debug_buffer(( 28*40 ) + 5 ),
    d2 => debug_buffer(( 28*40 ) + 6 ),
    d3 => debug_buffer(( 28*40 ) + 7 ),
    d4 => debug_buffer(( 28*40 ) + 8 )
);

register_1_of_map : bit_to_ascii port map (
    value => register_1_of,
    d1 => debug_buffer(( 28*40 ) + 13 )
);

register_1_map : word_to_ascii port map (
    value => register_1,
    d1 => debug_buffer(( 28*40 ) +15 ),
    d2 => debug_buffer(( 28*40 ) +16 ),
    d3 => debug_buffer(( 28*40 ) +17 ),
    d4 => debug_buffer(( 28*40 ) +18 )
);

register_2_of_map : bit_to_ascii port map (
    value => register_2_of,
    d1 => debug_buffer(( 28*40 ) + 23 )
);

register_2_map : word_to_ascii port map (
    value => register_2,
    d1 => debug_buffer(( 28*40 ) +25 ),
    d2 => debug_buffer(( 28*40 ) +26 ),
    d3 => debug_buffer(( 28*40 ) +27 ),
    d4 => debug_buffer(( 28*40 ) +28 )
);

register_3_of_map : bit_to_ascii port map (
    value => register_3_of,
    d1 => debug_buffer(( 28*40 ) + 33 )
);

register_3_map : word_to_ascii port map (
    value => register_3,
    d1 => debug_buffer(( 28*40 ) +35 ),
    d2 => debug_buffer(( 28*40 ) +36 ),
    d3 => debug_buffer(( 28*40 ) +37 ),
    d4 => debug_buffer(( 28*40 ) +38 )
);

register_4_of_map : bit_to_ascii port map (
    value => register_4_of,
    d1 => debug_buffer(( 29*40 ) + 3 )
);

register_4_map : word_to_ascii port map (
    value => register_4,
    d1 => debug_buffer(( 29*40 ) + 5 ),
    d2 => debug_buffer(( 29*40 ) + 6 ),
    d3 => debug_buffer(( 29*40 ) + 7 ),
    d4 => debug_buffer(( 29*40 ) + 8 )
);

register_5_of_map : bit_to_ascii port map (
    value => register_5_of,
    d1 => debug_buffer(( 29*40 ) + 13 )
);

register_5_map : word_to_ascii port map (
    value => register_5,
    d1 => debug_buffer(( 29*40 ) +15 ),
    d2 => debug_buffer(( 29*40 ) +16 ),
    d3 => debug_buffer(( 29*40 ) +17 ),
    d4 => debug_buffer(( 29*40 ) +18 )
);

register_6_of_map : bit_to_ascii port map (
    value => register_6_of,
    d1 => debug_buffer(( 29*40 ) + 23 )
);

register_6_map : word_to_ascii port map (
    value => register_6,
    d1 => debug_buffer(( 29*40 ) +25 ),
    d2 => debug_buffer(( 29*40 ) +26 ),
    d3 => debug_buffer(( 29*40 ) +27 ),
    d4 => debug_buffer(( 29*40 ) +28 )
);

register_7_of_map : bit_to_ascii port map (
    value => register_7_of,
    d1 => debug_buffer(( 29*40 ) + 33 )
);

register_7_map : word_to_ascii port map (
    value => register_7,
    d1 => debug_buffer(( 29*40 ) +35 ),
    d2 => debug_buffer(( 29*40 ) +36 ),
    d3 => debug_buffer(( 29*40 ) +37 ),
    d4 => debug_buffer(( 29*40 ) +38 )
);



delay_signals : process ( video_clock, Hdot, Vline )
begin
    if ( rising_edge( video_clock )) then
        Hdot_delayed <= Hdot;
        Vline_delayed <= Vline;
    end if;
end process;

display_data <= main_buffer(to_integer(unsigned(display_address)));

select_display : process(  Hdot_delayed, Vline_delayed, display_data, display_address, debug, debug_buffer )
begin
    if ( debug = '0' ) then
        offset <= ( "00" & Vline_delayed( 6 downto 2 ) & Hdot_delayed( 4 downto 2 ));
    else
            offset <= ( "00" & Vline_delayed( 5 downto 1 ) & Hdot_delayed( 3 downto 1 ));
    end if;

    if ( debug = '0' ) then
        char_data <= to_integer( unsigned( display_data( 7 downto 0 )));
    else
        char_data <= to_integer( unsigned( debug_buffer(to_integer(unsigned(display_address)))( 6 downto 0 )));
    end if;
end process;


update_address : process( video_clock, display_address, v_sync, Hdot, Vline )

variable address : unsigned ( ( DEBUG_MEMORY_LENGTH -1 ) downto 0 );
variable offset : unsigned ( ( DEBUG_MEMORY_LENGTH -1 ) downto 0 );

begin
    if ( rising_edge( video_clock )) then

        if ( debug =  '0' ) then

            if ( v_sync = '0' ) then
                address := ( others => '0' );
                offset := to_unsigned( -20, offset'LENGTH ); -- "000000000";
            end if;

            if (( Hdot < 640 ) and ( Hdot(4 downto 0 ) = "00000" )) then

                if ( Hdot =  0 ) then
                    address := ( others => '0' );
                    if (( Vline( 4 downto 0 ) = "00000" ) and ( Vline < 480 )) then
                        offset := offset + 20;
                    end if;
                else
                    address := address + 1;
                end if;

                display_address <= STD_LOGIC_VECTOR( address + offset );
            end if;

        else

            if ( v_sync = '0' ) then
                address := ( others => '0' );
                offset := to_unsigned( -40, offset'LENGTH ); -- "000000000";
            end if;

            if (( Hdot < 640 ) and ( Hdot(3 downto 0 ) = "00000" )) then

                if ( Hdot =  0 ) then
                    address := ( others => '0' );
                    if (( Vline( 3 downto 0 ) = "00000" ) and ( Vline < 480 )) then
                        offset := offset + 40;
                    end if;
                else
                    address := address + 1;
                end if;

                display_address <= STD_LOGIC_VECTOR( address + offset );
            end if;
        end if;
    end if;
end process;


--
-- During horizontal sync test the vertical line and select the appropriate opcode to display
--

process ( h_sync, Vline, s1_opcode, s2_opcode, s3_opcode, s4_opcode )
begin
    if ( falling_edge( h_sync )) then

--
-- Stage 1 Fetch
--

        if ( Vline = (( 5 *16 ) -1 )) then
            opcode <= s1_opcode;

--
-- Stage 2 Decode
--
        elsif ( Vline = ((  9 *16 ) -1 )) then
            opcode <= s2_opcode;

--
-- Stage 3 Execute
--
        elsif ( Vline = (( 13 *16 ) -1 )) then
            opcode <= s3_opcode;

--
-- Stage 4 Memory
--
        elsif ( Vline = (( 17 * 16 ) -1 )) then
            opcode <= s4_opcode;

        end if;
    end if;
end process;



DisplayText: process ( Hdot_delayed, Vline_delayed, offset, char_data, Hdot, Vline, debug )
begin
    if ( debug = '0' ) then
        if (( Hdot < ( 640 )) and ( Vline < 480 )) then
            if (( Hdot_delayed( 1 downto 0 ) < "11" ) and ( Vline_delayed( 1 downto 0 ) < "11" )) then
                Active <=  characters( char_data )(to_integer( offset ));
            else
                Active <= '0';
            end if;
        else
           Active <= '0';
        end if;

    else
        if (( Vline = 0 ) and (( Hdot = 0 ) or ( HDot = 639 ))) then
           Active <= '1';
        elsif (( Hdot < ( 640 )) and ( Vline < 480 ) and ( Vline_delayed( 3 downto 1 ) /= "111" )) then
           Active <=  characters( char_data )(to_integer( offset ));
        else
           Active <= '0';
        end if;
    end if;
end process;


text_color : process ( video_clock, Active, display_data )

variable red : STD_LOGIC;
variable green : STD_LOGIC;
variable blue : STD_LOGIC;

begin
    if ( rising_edge( video_clock )) then
        if ( Active = '1' ) then
            if ((( display_data(15) = '0' ) or ( debug = '1' ))) then
                vga_red <= "1111";
                vga_blue <= "1111";
                vga_green <= "1111";
            else
                red := display_data(13) or display_data(12);
                green := display_data(11) or display_data(10);
                blue := display_data(9) or display_data(8);
                vga_red <= display_data( 13 downto 12 ) & red & red;
                vga_green <= display_data( 11 downto 10 ) & green & green;
                vga_blue <= display_data( 9 downto 8 ) & blue & blue;
            end if;
        else
            vga_red <= "0000";
            vga_blue <= "0000";
            vga_green <= "0000";
        end if;

    end if;

end process;

end Behavioral;