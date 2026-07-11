library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity CONTROLLER_file is 
	port(
		--input signals
		rst: in std_logic;  
		clk: in std_logic;
--		clk_display: in std_logic; -- was clk_display -> board_clock
		btn,num: in std_logic_vector(3 downto 0);
		input_port: in std_logic_vector(9 downto 0);
		-- output signals
        an: out std_logic_vector(3 downto 0);
        sseg: out std_logic_vector(6 downto 0);
		z, n, o_led: out std_logic;
		output_port: out std_logic;
		
		-- NEW
		
		        debug_console : in STD_LOGIC;
                board_clock: in std_logic;
        
                vga_red : out std_logic_vector( 3 downto 0 );
                vga_green : out std_logic_vector( 3 downto 0 );
                vga_blue : out std_logic_vector( 3 downto 0 );
        
                h_sync_signal : out std_logic;
                v_sync_signal : out std_logic
		
		-- END

	);
end CONTROLLER_file;

architecture behavioural of CONTROLLER_file is
    -- NEW
    
    component console is
        port (
    
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
    
            s3_reg_a : in STD_LOGIC_VECTOR( 2 downto 0 ); -- original 2
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
    end component;
    
    -- END


	component ALU_file port (
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
	end component;

	component PC_file port (
		--input signals
        brch_addr: in std_logic_vector(15 downto 0);  
        brch_en: in std_logic;
        rst: in std_logic;  
        clk: in std_logic;  
        stall: in std_logic;
        --output signal
        CPC: out std_logic_vector(15 downto 0)
	);
	end component;

	component REGISTER_file port (
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
	
	end component;
	
	component SIGNEXT_file port (
		--input signals
        raw_addr: in std_logic_vector(8 downto 0); 
        rst : in std_logic; --clock
        clk: in std_logic;  --reset
        --output signals
        ext_addr: out std_logic_vector(15 downto 0)
	);
    end component;
    
	component RAM_file port (
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
	end component;
	
	component ROM_file port(
        --input signals       
        addr: in std_logic_vector(15 downto 0); 

        rst: in std_logic;  
        clk: in std_logic; 

        -- output signal
        dout: out std_logic_vector(15 downto 0)
    );
    end component;
    
    component MUX_file port(
        in1: in std_logic_vector(15 downto 0);
        in2: in std_logic_vector(15 downto 0);
        sel, stall: in std_logic;
        out1: out std_logic_vector(15 downto 0)
    );
    end component;
    
    component display_controller port(
        clk, reset: in std_logic;
        hex3, hex2, hex1, hex0: in std_logic_vector(3 downto 0);
        an: out std_logic_vector(3 downto 0);
        sseg: out std_logic_vector(6 downto 0)
    );
    end component;

    signal CPU_output: std_logic_vector(15 downto 0);
	signal digit3, digit2, digit1, digit0: std_logic_vector(3 downto 0);
	signal o: std_logic;
	-- FETCH
	signal brch_addr, CPC, IR_ROM, IR_RAM, IR: std_logic_vector(15 downto 0);
	signal brch_en, stall: std_logic;
	-- DECODE
	signal ra_idx, rb_idx, rc_idx: std_logic_vector(2 downto 0);
	signal ra_val, rb_val, rc_val, CPC_decode: std_logic_vector(15 downto 0);
    signal wr_en: std_logic;
    signal short_addr: std_logic_vector(8 downto 0);
	-- EXECUTE
	signal ra_idx_execute, rb_idx_execute, rc_idx_execute: std_logic_vector(3 downto 0);
	signal in1, in2, IR_execute, ext_addr, CPC_execute, CPC_execute_stage: std_logic_vector(15 downto 0);
	signal z_flag, n_flag, o_flag, stall_MUX, hold_flag: std_logic;
	signal alu_mode: std_logic_vector(2 downto 0);
	signal shift_count: std_logic_vector(3 downto 0);
	-- MEMORY ACCESS
	signal ra_idx_memoryaccess, rb_idx_memoryaccess, rc_idx_memoryaccess: std_logic_vector(3 downto 0);
	signal IR_memoryaccess, out1, out2, CPC_memoryaccess: std_logic_vector(15 downto 0);
	signal addr_dt, din_dt: std_logic_vector(15 downto 0);
	signal s3_br_wb_sig : std_logic;
	signal s3_mr_wr_sig : std_logic;
	signal s3_mr_rd_sig : std_logic;
	-- WRITE BACK
	signal ra_idx_writeback, rb_idx_writeback, rc_idx_writeback: std_logic_vector(3 downto 0);
	signal IR_writeback, alu_dt, mem_dt: std_logic_vector(15 downto 0);
	signal rst_clk, regcea, regceb, s4_r_wb_sig: std_logic;
	signal wr_mem_en: std_logic_vector(0 downto 0);
	type reg_array is array (0 to 7) of std_logic_vector(15 downto 0);
    signal registers : reg_array;
    type o_array is array (0 to 7) of std_logic;
    signal o_flags : o_array;

	begin
	PC_module : PC_file port map(brch_addr, brch_en, rst, clk, stall, CPC);	
	-- ra for WRITE only, rb, rc for READ only
	REGISTER_module: REGISTER_file port map(rst, clk, rb_idx, rc_idx, rb_val, rc_val, ra_idx, ra_val, wr_en);
    ALU_module: ALU_file port map(in1, in2, alu_mode, shift_count, rst, clk, hold_flag, out1, z_flag, n_flag, o_flag);
    SIGNEXT_module: SIGNEXT_file port map(short_addr, rst, clk, ext_addr);
    RAM_module: RAM_file port map(addr_dt, CPC, din_dt, wr_mem_en, rst, clk, mem_dt, IR_RAM);
    ROM_module: ROM_file port map(CPC, rst, clk, IR_ROM);
    MUX_ROMRAM: MUX_file port map(IR_ROM, IR_RAM, stall_MUX, CPC(10), IR);
    DISPLAY_module: display_controller port map(board_clock, rst, digit3, digit2, digit1, digit0, an, sseg); 
    -- NEW
    
    console_display : console
    port map
    (
    --
    -- Stage 1 Fetch
    --
        s1_pc => CPC, 
        s1_inst =>  IR,
    --
    -- Stage 2 Decode
    --
    
        s2_pc => CPC_decode,
        
        s2_inst => IR,
    
        s2_reg_a => ra_idx,
        s2_reg_b => rb_idx,
        s2_reg_c => rc_idx,
    
        s2_reg_a_data => ra_val,
        s2_reg_b_data => rb_val,
        s2_reg_c_data => rc_val,
        s2_immediate => ext_addr,
    
    --
    -- Stage 3 Execute
    --
    
        s3_pc => CPC_execute_stage,
        s3_inst => IR_execute,
    
        s3_reg_a => ra_idx_execute(2 downto 0),
        s3_reg_b => ra_idx_execute(2 downto 0),
        s3_reg_c => ra_idx_execute(2 downto 0),
    
        s3_reg_a_data => alu_dt,
        s3_reg_b_data => in1,
        s3_reg_c_data => in2,
        s3_immediate => ext_addr,
    
        s3_r_wb => wr_en,
        s3_r_wb_data => alu_dt,
    
        s3_br_wb => s3_br_wb_sig,
        s3_br_wb_address => out1,
    
        s3_mr_wr => s3_mr_wr_sig,
        s3_mr_wr_address => out1,
        s3_mr_wr_data => out2,
    
        s3_mr_rd => s3_mr_rd_sig,
        s3_mr_rd_address => out1,
    
    --
    -- Stage 4 Memory
    --
    
        s4_pc => CPC_memoryaccess,
        s4_inst => IR_memoryaccess,
        s4_reg_a => ra_idx_memoryaccess(2 downto 0),
        s4_r_wb => s4_r_wb_sig,
        s4_r_wb_data => ra_val,
    
    --
    -- CPU registers
    --
    
        register_0 => registers(0),
        register_1 => registers(1),
        register_2 => registers(2),
        register_3 => registers(3),
        register_4 => registers(4),
        register_5 => registers(5),
        register_6 => registers(6),
        register_7 => registers(7),
    
        register_0_of => o_flags(0),
        register_1_of => o_flags(1),
        register_2_of => o_flags(2),
        register_3_of => o_flags(3),
        register_4_of => o_flags(4),
        register_5_of => o_flags(5),
        register_6_of => o_flags(6),
        register_7_of => o_flags(7),
    
    --
    -- CPU Flags
    --
        zero_flag => z_flag,
        negative_flag => n_flag,
        overflow_flag => o_flag,
    
    --
    -- Debug screen enable
    --
        debug => debug_console,
    --
    -- Text console display memory access signals ( clk is the processor clock )
    --
    
        clk => clk,
        addr_write => IR_writeback,
        data_in => IR,
        en_write => wr_en,
    
    --
    -- Video related signals
    --
    
        board_clock => board_clock,
        h_sync_signal => h_sync_signal,
        v_sync_signal => v_sync_signal,
        vga_red => vga_red,
        vga_green => vga_green,
        vga_blue => vga_blue
    );
    
    -- END
    --      clk_display
	process(board_clock) begin
	    -- 0000: CPC
	    -- 0001: IR
	    -- 0010: num
	    -- 0011: CPU_output
	    -- 0100: rb_idx
	    -- 0101: rc_idx
	    -- 0110: rb_val
	    -- 0111: rc_val
	    -- 1000: in1
	    -- 1001: in2
	    -- 1010: alu_mode, shift_count
	    -- 1011: out1
	    -- 1100: brch_en, stall
	    -- 1101: brch_addr
	    -- 1110: wr_en, ra_idx
	    -- 1111: ra_val
		if (board_clock = '0' and board_clock'event) then
			if (btn = "0000") then			-- CPC
                digit3 <= CPC(15 downto 12);
                digit2 <= CPC(11 downto 8);
                digit1 <= CPC(7 downto 4);
                digit0 <= CPC(3 downto 0);
            elsif (btn = "0001") then		-- IR
                digit3 <= IR(15 downto 12);
                digit2 <= IR(11 downto 8);
                digit1 <= IR(7 downto 4);
                digit0 <= IR(3 downto 0);
            elsif (btn = "0010") then		-- num
                digit3 <= X"0";
                digit2 <= X"0";
                digit1 <= X"0";
                digit0 <= num;
			elsif (btn = "0011") then		-- CPU_output
                digit3 <= CPU_output(15 downto 12);
                digit2 <= CPU_output(11 downto 8);
                digit1 <= CPU_output(7 downto 4);
                digit0 <= CPU_output(3 downto 0);
			elsif (btn = "0100") then		-- rb index
				digit3 <= "0000";
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= '0' & rb_idx;
			elsif (btn = "0101") then		-- rc index
				digit3 <= "0000";
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= '0' & rc_idx;
			elsif (btn = "0110") then		-- rb value
				digit3 <= rb_val(15 downto 12);
				digit2 <= rb_val(11 downto 8);
				digit1 <= rb_val(7 downto 4);
				digit0 <= rb_val(3 downto 0);
			elsif (btn = "0111") then		-- rc value
				digit3 <= rc_val(15 downto 12);
				digit2 <= rc_val(11 downto 8);
				digit1 <= rc_val(7 downto 4);
				digit0 <= rc_val(3 downto 0);
			elsif (btn = "1000") then		-- in1 of ALU
				digit3 <= in1(15 downto 12);
				digit2 <= in1(11 downto 8);
				digit1 <= in1(7 downto 4);
				digit0 <= in1(3 downto 0);
			elsif (btn = "1001") then		-- in2 of ALU
				digit3 <= in2(15 downto 12);
				digit2 <= in2(11 downto 8);
				digit1 <= in2(7 downto 4);
				digit0 <= in2(3 downto 0);
			elsif (btn = "1010") then		-- alu_mode, shift_count of ALU
				digit3 <= '0' & alu_mode;
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= shift_count; 	
			elsif (btn = "1011") then		-- out1 of ALU
				digit3 <= out1(15 downto 12);
                digit2 <= out1(11 downto 8);
                digit1 <= out1(7 downto 4);
                digit0 <= out1(3 downto 0);
			elsif (btn = "1100") then		-- brch_en, stall
				digit3 <= "000" & brch_en;
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= "000" & stall;
			elsif (btn = "1101") then		-- brch_addr
				digit3 <= brch_addr(15 downto 12);
				digit2 <= brch_addr(11 downto 8);
				digit1 <= brch_addr(7 downto 4);
				digit0 <= brch_addr(3 downto 0);
			elsif (btn = "1110") then		-- wr_en, ra_idx
				digit3 <= "000" & wr_en;
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= '0' & ra_idx;
			elsif (btn = "1111") then		-- ra_val
				digit3 <= ra_val(15 downto 12);
				digit2 <= ra_val(11 downto 8);
				digit1 <= ra_val(7 downto 4);
				digit0 <= ra_val(3 downto 0);
			end if;
		end if;
	end process;

	process (clk) begin
        if(clk = '0' and clk'event) then
            if wr_en = '1' and to_integer(unsigned(ra_idx)) < 8 then
                registers(to_integer(unsigned(ra_idx(2 downto 0)))) <= ra_val;
            end if;
             -- Set overflow flags per-instruction
               case IR_writeback(15 downto 9) is
                   when "0000001" | -- ADD
                        "0000010" | -- SUB
                        "0000011" => -- MUL
                       o_flags(to_integer(unsigned(ra_idx))) <= o_flag;
                    when others =>
                       o_flags(to_integer(unsigned(ra_idx))) <= '0'; -- Optional clear
                end case;
               
		brch_addr <= X"0000";
			brch_en <= '0';
			shift_count <= "0000";
			ra_val <= X"0000";
			ra_idx <= "000";
			rb_idx <= "000";
            rc_idx <= "000";
            in1 <= X"0000";
			in2 <= X"0000";
			hold_flag <= '0';
			stall <= '0';
			wr_en <= '0';
			ra_idx_execute <= "1000";
			rb_idx_execute <= "1000";
			rc_idx_execute <= "1000";
            stall_MUX <= '0';
			if (rst='1') then
				o_led <= '0';
				stall_MUX <= '1';
				IR_writeback <= X"0000";
				IR_memoryaccess <= X"0000";
				IR_execute <= X"0000";
				n <= '0';
				z <= '0';
				o <= '0';
				CPU_output <= X"0000";
				alu_mode <= "000";
				ra_idx_memoryaccess <= "1000";
				rb_idx_memoryaccess <= "1000";
				rc_idx_memoryaccess <= "1000";
				ra_idx_writeback <= "1000";
				rb_idx_writeback <= "1000";
				rc_idx_writeback <= "1000";
				-- ? Reset overflow flags and registers
                for i in 0 to 7 loop
                    registers(i) <= (others => '0');
                    o_flags(i) <= '0';
                end loop;
			else
				-- code for WRITE BACK stage
				case IR_writeback(15 downto 9) is
					when "0000000" => --NOP
					when "0000001" => -- ADD
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000010" => -- SUB
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000011" => -- MUL
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000100" => -- NAND
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000101" => -- SHL
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000110" => -- SHR
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000111" => -- TEST
						NULL;
					when "0100000" => -- OUT
						NULL;
					when "0100001" => -- IN
						ra_idx <= ra_idx_writeback(2 downto 0);	
						ra_val <= input_port & "000000";
						wr_en <= '1';	
					when "1000000" => -- BRR
					    NULL;
					when "1000001" => -- BRR.N
					    NULL;
					when "1000010" => -- BRR.Z
					    NULL;
					when "1000011" => -- BR
					    NULL;
					when "1000100" => -- BR.N
					    NULL;
					when "1000101" => -- BR.Z
					    NULL;
					when "1000110" => -- BR.SUB
					    wr_en <= '1';
					    ra_idx <= ra_idx_writeback(2 downto 0);	
					    ra_val <= alu_dt;
					when "1000111" => -- RETURN
					    NULL;
					when "0010000" => -- LOAD
						if (alu_dt = X"FFF0") then
							ra_val <= X"000" & num;
						else
							ra_val <= mem_dt;
						end if;
						ra_idx <= ra_idx_writeback(2 downto 0);
						wr_en <= '1';
					when "0010001" => -- STORE
						NULL;
					when "0010010" => --LOADIMM
						ra_idx <= "111";
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0010011" => --MOV
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when others => NULL;
					
					case IR(15 downto 9) is
                                             when "1000000" | "1000001" | "1000010" | "1000011" |
                                                   "1000100" | "1000101" | "1000110" | "1000111" =>
                                                   s3_br_wb_sig <= '1';
                                             when others =>
                                                   s3_br_wb_sig <= '0';
                                                   
                                        end case;
                                        if IR(15 downto 9) = "0010001" then
                                            s3_mr_wr_sig <= '1';
                                        else
                                             s3_mr_wr_sig <= '0';
                                        end if;
                                                            
                                        if IR(15 downto 9) = "0010000" then
                                             s3_mr_rd_sig <= '1';
                                        else
                                             s3_mr_rd_sig <= '0';
                                        end if;            
                                 
                                        case IR_memoryaccess(15 downto 9) is
                                             when "0000001"| "0000010"| "0000011"|"0000100"| "0000101"| "0000110"|  -- ALU ops
                                                  "0100001"|  -- IN
                                                  "0010000"|  -- LOAD
                                                  "0010010"|  -- LOADIMM
                                                  "0010011"|  -- MOV
                                                  "1000110" =>  -- BR.SUB 
                                                  s4_r_wb_sig <= '1';
                                              when others =>
                                                  s4_r_wb_sig <= '0';
                                        end case;
					
				end case;
				
				-- code for MEMORY ACCESS stage
				IR_writeback <= IR_memoryaccess;
				ra_idx_writeback <= ra_idx_memoryaccess;
				rb_idx_writeback <= rb_idx_memoryaccess;
				rc_idx_writeback <= rc_idx_memoryaccess;
				CPC_memoryaccess <= CPC;
				alu_dt <= out1;
				wr_mem_en <= "0";
				
				case IR_memoryaccess(15 downto 9) is
					when "0000000" => --NOP
						NULL;
					when "0000001" => -- ADD
						NULL;
					when "0000010" => -- SUB
						NULL;			
					when "0000011" => -- MUL
						NULL;				
					when "0000100" => -- NAND
						NULL;				
					when "0000101" => -- SHL
						NULL;				
					when "0000110" => -- SHR
						NULL;			
					when "0000111" => -- TEST
						NULL;				
					when "0100000" => -- OUT
						output_port <= out1(0);
					when "0100001" => -- IN
						NULL;
					when "1000000" => -- BRR
						NULL;
					when "1000001" => -- BRR.N
						NULL;
					when "1000010" => -- BRR.Z
						NULL;
					when "1000011" => -- BR
						NULL;
					when "1000100" => -- BR.N
						NULL;
					when "1000101" => -- BR.Z
						NULL;
					when "1000110" => -- BR.SUB
						NULL;
					when "1000111" => -- RETURN
					    NULL;
					when "0010000" => -- LOAD
						addr_dt <= out1;
						alu_dt <= out1;
					when "0010001" => -- STORE
						if (out1 = X"FFF2") then
							CPU_output <= out2;
							if (out2 = X"0000") then
							     z <= '1';
							else
							     z <= '0';
							end if;
							n <= out2(15);
						else
							addr_dt <= out1;	-- dest
							din_dt <= out2;		-- src
							wr_mem_en <= "1";
						end if;
						
					when "0010010" => --LOADIMM
						alu_dt <= out1;
					when "0010011" => --MOV
						alu_dt <= out1;
					when others => NULL;
				end case;
					case IR_memoryaccess(15 downto 9) is
                         when "0000001"| "0000010"| "0000011"|"0000100"| "0000101"| "0000110"|  -- ALU ops
                               "0100001"|  -- IN
                               "0010000"|  -- LOAD
                               "0010010"|  -- LOADIMM
                               "0010011"|  -- MOV
                               "1000110" =>  -- BR.SUB 
                               s4_r_wb_sig <= '1';
                         when others =>
                               s4_r_wb_sig <= '0';
                         end case;
                         
                    case IR(15 downto 9) is
                          when "1000000" | "1000001" | "1000010" | "1000011" |
                                "1000100" | "1000101" | "1000110" | "1000111" =>
                                 s3_br_wb_sig <= '1';
                           when others =>
                                  s3_br_wb_sig <= '0';                                
                    end case;
                    
                    if IR(15 downto 9) = "0010001" then
                          s3_mr_wr_sig <= '1';
                    else
                          s3_mr_wr_sig <= '0';
                    end if;
                                                                 
                    if IR(15 downto 9) = "0010000" then
                          s3_mr_rd_sig <= '1';
                    else
                          s3_mr_rd_sig <= '0';
                    end if;            
				
				-- code for EXECUTE stage
				IR_memoryaccess <= IR_execute;
				CPC_execute_stage <= CPC;
				ra_idx_memoryaccess <= ra_idx_execute;
				rb_idx_memoryaccess <= rb_idx_execute;
				rc_idx_memoryaccess <= rc_idx_execute;
				brch_addr <= out1;
				case IR_execute(15 downto 9) is
					when "0000000" => --NOP
						alu_mode <= "000";
						hold_flag <= '1';
					when "0000001" => -- ADD
						alu_mode <= "001";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in2 <= X"000" & num;
								else
									in2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in2 <= input_port & "000000";
							end if;
						else
							in2 <= rc_val;	
						end if;
					when "0000010" => -- SUB
						alu_mode <= "010";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in2 <= X"000" & num;
								else
									in2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in2 <= input_port & "000000";
							end if;
						else
							in2 <= rc_val;	
						end if;		
					when "0000011" => -- MUL
						alu_mode <= "011";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in2 <= X"000" & num;
								else
									in2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in2 <= input_port & "000000";
							end if;
						else
							in2 <= rc_val;	
						end if;			
					when "0000100" => -- NAND
						alu_mode <= "100";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in2 <= X"000" & num;
								else
									in2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in2 <= input_port & "000000";
							end if;
						else
							in2 <= rc_val;	
						end if;			
					when "0000101" => -- SHL
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "101";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;
					when "0000110" => -- SHR
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "110";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;			
					when "0000111" => -- TEST
						alu_mode <= "111";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;				
					when "0100000" => -- OUT
						alu_mode <= "111";	
						hold_flag <= '1';
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;			
					when "0100001" => -- IN
						alu_mode <= "111";	
						hold_flag <= '1';
					when "1000000" => -- BRR
					    alu_mode <= "001";
					    hold_flag <= '1';
					    in1 <= CPC_execute;
					    in2 <= ext_addr;
						stall_MUX <= '1';	
					when "1000001" => -- BRR.N
					    alu_mode <= "001";
						hold_flag <= '1';
					    in1 <= CPC_execute;
					    if (n_flag = '0') then
                            in2 <= X"0002";
					    else
					       in2 <= ext_addr;
						   stall_MUX <= '1';
					    end if;
					when "1000010" => -- BRR.Z
					    alu_mode <= "001";
						hold_flag <= '1';
					    in1 <= CPC_execute;
					    if (z_flag = '0') then
                            in2 <= X"0002";
					    else
					       in2 <= ext_addr;
						   stall_MUX <= '1';
					    end if;
					when "1000011" => -- BR
					    alu_mode <= "001";
					    hold_flag <= '1';
					    in1 <= rb_val;
					    in2 <= ext_addr;
						stall_MUX <= '1';	
					when "1000100" => -- BR.N
					    alu_mode <= "001";
						hold_flag <= '1';
					    if (n_flag = '0') then
					       in1 <= CPC_execute;
					       in2 <= X"0002";
					    else
							if (rb_idx_execute = ra_idx_memoryaccess) then
								if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
									stall <= '1';
									alu_mode <= "000";
									IR_memoryaccess <= X"0000";
									ra_idx_memoryaccess <= "1000";
									rb_idx_memoryaccess <= "1000";
									rc_idx_memoryaccess <= "1000";

									IR_execute <= IR_execute;
									ra_idx_execute <= ra_idx_execute;
									rb_idx_execute <= rb_idx_execute;
									rc_idx_execute <= rc_idx_execute;
								elsif (IR_memoryaccess(15 downto 9) = "0010010") then
									if (IR_memoryaccess(8) = '1') then
										in1 <=  IR_memoryaccess(7 downto 0) & alu_dt(7 downto 0);
									else
										in1 <= alu_dt(15 downto 8) & IR_memoryaccess(7 downto 0);
									end if;
								else
									in1 <= out1;
								end if;
							elsif (rb_idx_execute = ra_idx_writeback) then
								in1 <= alu_dt;
								if (IR_writeback(15 downto 9) = "0010000") then
									if (out1 = X"FFF0") then
										in1 <= X"000" & num;
									else
										in1 <= mem_dt;
									end if;
								elsif (IR_writeback(15 downto 9) = "0100001") then
									in1 <= input_port & "000000";
								end if;
							else
								in1 <= rb_val;	
							end if;
					       in2 <= ext_addr;
						   stall_MUX <= '1';
					    end if;
					when "1000101" => -- BR.Z
					    alu_mode <= "001";
						hold_flag <= '1';
					    if (z_flag = '0') then
					       in1 <= CPC_execute;
					       in2 <= X"0002";
					    else
							if (rb_idx_execute = ra_idx_memoryaccess) then
								if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
									stall <= '1';
									alu_mode <= "000";
									IR_memoryaccess <= X"0000";
									ra_idx_memoryaccess <= "1000";
									rb_idx_memoryaccess <= "1000";
									rc_idx_memoryaccess <= "1000";

									IR_execute <= IR_execute;
									ra_idx_execute <= ra_idx_execute;
									rb_idx_execute <= rb_idx_execute;
									rc_idx_execute <= rc_idx_execute;
								else
									in1 <= out1;
								end if;
							elsif (rb_idx_execute = ra_idx_writeback) then
								in1 <= alu_dt;
								if (IR_writeback(15 downto 9) = "0010000") then
									if (out1 = X"FFF0") then
										in1 <= X"000" & num;
									else
										in1 <= mem_dt;
									end if;
								elsif (IR_writeback(15 downto 9) = "0100001") then
									in1 <= input_port & "000000";
								end if;
							else
								in1 <= rb_val;	
							end if;
					       in2 <= ext_addr;
						   stall_MUX <= '1';
					    end if;
					when "1000110" => -- BR.SUB
						stall_MUX <= '1';
						hold_flag <= '1';
					    alu_mode <= "001";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;
					    in2 <= ext_addr;
					when "1000111" => -- RETURN
						stall_MUX <= '1';
                        hold_flag <= '1';
					    alu_mode <= "111";
					    if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;
					when "0010000" => -- LOAD
						alu_mode <= "111";
						hold_flag <= '1';
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;	
					when "0010001" => -- STORE
						alu_mode <= "111";
						hold_flag <= '1';
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;	
						
						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								out2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							out2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									out2 <= X"000" & num;
								else
									out2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								out2 <= input_port & "000000";
							end if;
						else
							out2 <= rc_val;	
						end if;	
					when "0010010" => --LOADIMM
						alu_mode <= "001";	
						hold_flag <= '1';
                        if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								if (IR_execute(8) = '1') then
									in1 <= X"00" & out1(7 downto 0);
									in2 <= IR_execute(7 downto 0) & X"00";
								else
									in1 <= out1(15 downto 8) & X"00";
									in2 <= X"00" & IR_execute(7 downto 0);
								end if;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							if (IR_execute(8) = '1') then
								in1 <= X"00" & alu_dt(7 downto 0);
								in2 <= IR_execute(7 downto 0) & X"00";
							else
								in1 <= alu_dt(15 downto 8) & X"00";
								in2 <= X"00" & IR_execute(7 downto 0);
							end if;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									if (IR_execute(8) = '1') then
										in1 <= X"000" & num;
										in2 <= IR_execute(7 downto 0) & X"00";
									else
										in1 <= X"0000";
										in2 <= X"00" & IR_execute(7 downto 0);
									end if;
								else
									if (IR_execute(8) = '1') then
										in1 <= X"00" & mem_dt(7 downto 0);
										in2 <= IR_execute(7 downto 0) & X"00";
									else
										in1 <= mem_dt(15 downto 8) & X"00";
										in2 <= X"00" & IR_execute(7 downto 0);
									end if;
								end if;
								
							elsif (IR_writeback(15 downto 9) = "0100001") then
								if (IR_execute(8) = '1') then
									in1 <= X"00" & input_port(1 downto 0) & "000000";
									in2 <= IR_execute(7 downto 0) & X"00";
								else
									in1 <= input_port(9 downto 2) & X"00";
									in2 <= X"00" & IR_execute(7 downto 0);
								end if;
							end if;
						else
							if (IR_execute(8) = '1') then
								in1 <= X"00" & rb_val(7 downto 0);
								in2 <= IR_execute(7 downto 0) & X"00";
							else
								in1 <= rb_val(15 downto 8) & X"00";
								in2 <= X"00" & IR_execute(7 downto 0);
							end if;
						end if;	
					when "0010011" => --MOV
						alu_mode <= "111";
						hold_flag <= '1';
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;		
					when others => NULL;	
					case IR(15 downto 9) is
                         when "1000000" | "1000001" | "1000010" | "1000011" |
                               "1000100" | "1000101" | "1000110" | "1000111" =>
                               s3_br_wb_sig <= '1';
                         when others =>
                               s3_br_wb_sig <= '0';
                               
                    end case;
                    if IR(15 downto 9) = "0010001" then
                        s3_mr_wr_sig <= '1';
                    else
                         s3_mr_wr_sig <= '0';
                    end if;
                                        
                    if IR(15 downto 9) = "0010000" then
                         s3_mr_rd_sig <= '1';
                    else
                         s3_mr_rd_sig <= '0';
                    end if;			
             
                    case IR_memoryaccess(15 downto 9) is
                         when "0000001"| "0000010"| "0000011"|"0000100"| "0000101"| "0000110"|  -- ALU ops
                              "0100001"|  -- IN
                              "0010000"|  -- LOAD
                              "0010010"|  -- LOADIMM
                              "0010011"|  -- MOV
                              "1000110" =>  -- BR.SUB 
                              s4_r_wb_sig <= '1';
                          when others =>
                              s4_r_wb_sig <= '0';
                    end case;
				end case;

				-- code for DECODE stage
                IR_execute <= IR;
                CPC_decode <= CPC;
                case IR(15 downto 9) is
                    when "0000001" => -- ADD
                        rb_idx <= IR(5 downto 3);
                        rc_idx <= IR(2 downto 0);    
                        ra_idx_execute <= '0' & IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(5 downto 3);
                        rc_idx_execute <= '0' & IR(2 downto 0);    
                    when "0000010" => -- SUB
                        rb_idx <= IR(5 downto 3);    
                        rc_idx <= IR(2 downto 0);    
                        ra_idx_execute <= '0' & IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(5 downto 3);
                        rc_idx_execute <= '0' & IR(2 downto 0); 
                    when "0000011" => -- MUL
                        rb_idx <= IR(5 downto 3);    
                        rc_idx <= IR(2 downto 0);
                        ra_idx_execute <= '0' & IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(5 downto 3);
                        rc_idx_execute <= '0' & IR(2 downto 0);                    
                    when "0000100" => -- NAND
                        rb_idx <= IR(5 downto 3);    
                        rc_idx <= IR(2 downto 0);
                        ra_idx_execute <= '0' & IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(5 downto 3);
                        rc_idx_execute <= '0' & IR(2 downto 0);    
                    when "0000101" => -- SHL
                        rb_idx <= IR(8 downto 6);
                        ra_idx_execute <= '0' & IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(8 downto 6);
                    when "0000110" => -- SHR
                        rb_idx <= IR(8 downto 6);
                        ra_idx_execute <= '0' & IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(8 downto 6);
                    when "0000111" => -- TEST
                        rb_idx <= IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(8 downto 6);
                    when "0100000" => -- OUT
                        rb_idx <= IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(8 downto 6);
                    when "0100001" => -- IN
                        ra_idx_execute <= '0' & IR(8 downto 6);
                    when "1000000" => -- BRR
                        short_addr <= IR(8 downto 0);
                    when "1000001" => -- BRR.N
                        short_addr <= IR(8 downto 0);
                    when "1000010" => -- BRR.Z
                        short_addr <= IR(8 downto 0);
                    when "1000011" => -- BR
                        rb_idx <= IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(8 downto 6);
                        short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
                    when "1000100" => -- BR.N
                        rb_idx <= IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(8 downto 6);
                        short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
                    when "1000101" => -- BR.Z
                        rb_idx <= IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(8 downto 6);
                        short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
                    when "1000110" => -- BR.SUB
                        rb_idx <= IR(8 downto 6);
                        rb_idx_execute <= '0' & IR(8 downto 6);
                        ra_idx_execute <= "0111";
                        short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
                    when "1000111" => -- RETURN
                        rb_idx <= "111";
                        rb_idx_execute <= "0111";
                    when "0010000" => -- LOAD
                        rb_idx <= IR(5 downto 3);
                        rb_idx_execute <= '0' & IR(5 downto 3);
                        ra_idx_execute <= '0' & IR(8 downto 6);
                    when "0010001" => -- STORE
                        rb_idx <= IR(8 downto 6);    -- dest
                        rb_idx_execute <= '0' & IR(8 downto 6);
                        rc_idx <= IR(5 downto 3);    -- src
                        rc_idx_execute <= '0' & IR(5 downto 3);
                    when "0010010" => --LOADIMM
                        rb_idx <= "111";
                        rb_idx_execute <= "0111";
                        ra_idx_execute <= "0111";
                    when "0010011" => --MOV
                        rb_idx <= IR(5 downto 3);
                        rb_idx_execute <= '0' & IR(5 downto 3);
                        ra_idx_execute <= '0' & IR(8 downto 6);
                    when others => NULL;
					if (stall_MUX = '1') then
					    stall_MUX <= '0';
					    hold_flag <= '1';
						brch_en <= '1';
						-- clear instruction in previous stages as we have branched
						IR_memoryaccess <= X"0000";
						ra_idx_memoryaccess <= "1000";
						rb_idx_memoryaccess <= "1000";
						rc_idx_memoryaccess <= "1000";
	
						IR_execute <= X"0000";
						ra_idx_execute <= "1000";
						rb_idx_execute <= "1000";
						rc_idx_execute <= "1000";
					end if;   
					
					case IR(15 downto 9) is
                        when "1000000" | "1000001" | "1000010" | "1000011" |
                             "1000100" | "1000101" | "1000110" | "1000111" =>
                            s3_br_wb_sig <= '1';
                        when others =>
                            s3_br_wb_sig <= '0';
                    end case;
                    
                    if IR(15 downto 9) = "0010001" then
                        s3_mr_wr_sig <= '1';
                    else
                        s3_mr_wr_sig <= '0';
                    end if;
                    
                    if IR(15 downto 9) = "0010000" then
                        s3_mr_rd_sig <= '1';
                    else
                        s3_mr_rd_sig <= '0';
                    end if;
                    
                    case IR_memoryaccess(15 downto 9) is
                        when "0000001"| "0000010"| "0000011"|"0000100"| "0000101"| "0000110"|  -- ALU ops
                        "0100001"|  -- IN
                        "0010000"|  -- LOAD
                        "0010010"|  -- LOADIMM
                        "0010011"|  -- MOV
                        "1000110" =>  -- BR.SUB 
                            s4_r_wb_sig <= '1';
                         when others =>
                            s4_r_wb_sig <= '0';
                     end case;
                   end case;
                if (o = '1') then
                    o <= '1';
                    o_led <= '1';
                else
                    o <= o_flag;
                end if;
			end if;
		end if;
    end process;
 end behavioural;