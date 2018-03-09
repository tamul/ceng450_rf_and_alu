----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:25:41 02/07/2018 
-- Design Name: 
-- Module Name:    processor - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_misc.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity processor is
	PORT(
		clk : IN std_logic;
		rst : IN std_logic;
		instruction : IN std_logic_vector(15 downto 0);
		inport: IN std_logic_vector(15 downto 0);
		outport : OUT std_logic_vector(15 downto 0)
	);
end processor;

architecture Behavioral of processor is

	constant instr_mem_size : integer := 1;
		
	function opcode(signal instr : std_logic_vector(15 downto 0)) return unsigned is
	begin
		return unsigned(instr(15 downto 9));
	end opcode;
	
	function wr_instr(signal instr : std_logic_vector(15 downto 0)) return boolean is
	begin
		return ((opcode(instr)>=1 AND opcode(instr)<=7) OR opcode(instr)=33);
	end wr_instr;
	
	function b1_instr(signal instr : std_logic_vector(15 downto 0)) return boolean is
	begin
		return (opcode(instr)=64 OR opcode(instr)=65 OR opcode(instr)=66);
	end b1_instr;
	
	function b2_instr(signal instr : std_logic_vector(15 downto 0)) return boolean is
	begin
		return (opcode(instr)=67 OR opcode(instr)=68 OR opcode(instr)=69 OR opcode(instr)=70);
	end b2_instr;
	
	function a1_instr(signal instr : std_logic_vector(15 downto 0)) return boolean is
	begin
		return (opcode(instr)>=1 AND opcode(instr)<=4);
	end a1_instr;
	
	function ra_instr(signal instr : std_logic_vector(15 downto 0)) return boolean is
	begin
		return (opcode(instr)=5 OR opcode(instr)=6 OR opcode(instr)=32 OR b2_instr(instr));
	end ra_instr;
	
	Component register_file
	PORT(
		rst : IN std_logic;
		clk : IN std_logic;
		rd_index1 : IN std_logic_vector(2 downto 0);
		rd_index2 : IN std_logic_vector(2 downto 0);
		rd_data1 : OUT std_logic_vector(15 downto 0);
		rd_data2 : OUT std_logic_vector(15 downto 0);
		wr_index : IN std_logic_vector(2 downto 0);
		wr_data : IN std_logic_vector(15 downto 0);
		wr_enable : IN std_logic;
		wr_overflow_data : IN std_logic_vector(15 downto 0);
		wr_overflow : IN std_logic
	);
	end Component;

	Component alu
	PORT(
		in1: IN std_logic_vector(15 downto 0);
		in2: IN std_logic_vector(15 downto 0);
      clk : IN std_logic;
      rst : IN std_logic;
		alu_mode : IN std_logic_vector(2 downto 0);
      result : OUT std_logic_vector(15 downto 0);
		overflow : OUT std_logic_vector(15 downto 0);
      z_flag : OUT  std_logic;
      n_flag : OUT  std_logic
	);
	end Component;
	
	Component ram
	PORT(
		rst : IN std_logic;
		clk : IN std_logic;
		wr_enable : IN std_logic;
		addr : IN std_logic_vector(6 downto 0);
		data : INOUT std_logic_vector(15 downto 0)
	);
	end Component;
	
	Component ROM_VHDL
	PORT(
		clk : IN std_logic;
		addr : IN std_logic_vector(6 downto 0);
		data : OUT std_logic_vector(15 downto 0)
	);
	end Component;
	
	type t_IF is record
		instr : std_logic_vector(15 downto 0);
		inport : std_logic_vector(15 downto 0);
		PC : std_logic_vector(6 downto 0);
		write_ignore : std_logic;
	end record t_IF;
	
	type t_ID is record
		instr : std_logic_vector(15 downto 0);
		data1 : std_logic_vector(15 downto 0);
		data2 : std_logic_vector(15 downto 0);
		PC : std_logic_vector(6 downto 0);
		write_ignore : std_logic;
	end record t_ID;
	
	type t_EX is record
		instr : std_logic_vector(15 downto 0);
		result : std_logic_vector(15 downto 0);
		overflow : std_logic_vector(15 downto 0);
		PC : std_logic_vector(6 downto 0);
		z_flag : std_logic;
		n_flag : std_logic;
		write_ignore : std_logic;
	end record t_EX;
	
	type t_WR is record
		instr : std_logic_vector(15 downto 0);
		data : std_logic_vector(15 downto 0);
		overflow : std_logic_vector(15 downto 0);
		PC : std_logic_vector(6 downto 0);
		write_ignore : std_logic;
	end record t_WR;
	
	signal reg_IF : t_IF := (instr => (others => '0'),
	                         inport => (others => '0'),
									 PC => (others => '0'),
									 write_ignore => '0');
																		  
	signal reg_ID : t_ID := (instr => (others => '0'),
	                         data1 => (others => '0'),
	                         data2 => (others => '0'),
									 PC => (others => '0'),
									 write_ignore => '0');
																			 
	signal reg_EX : t_EX := (instr => (others => '0'),
									 result => (others => '0'),
									 overflow => (others => '0'),
									 PC => (others => '0'),
									 z_flag => '0',
									 n_flag => '0',
									 write_ignore => '0');
										
	-- Connections requiring logic between
	signal rd_index1 : std_logic_vector(2 downto 0);
	signal rd_index2 : std_logic_vector(2 downto 0);
	signal rd_data1 : std_logic_vector(15 downto 0);
	signal rd_data2 : std_logic_vector(15 downto 0);
	signal wr_index : std_logic_vector(2 downto 0);
	signal wr_enable : std_logic;
	signal wr_overflow : std_logic;
		
	signal in1 : std_logic_vector(15 downto 0);
	signal in2 : std_logic_vector(15 downto 0);
	signal alu_mode : std_logic_vector(2 downto 0);
	
	signal result : std_logic_vector(15 downto 0);
	signal overflow : std_logic_vector(15 downto 0);
	signal z_flag : std_logic;
	signal n_flag : std_logic;
	
	signal branch_trigger : std_logic;
		
	signal PC : std_logic_vector(6 downto 0);
	signal PC_next : std_logic_vector(6 downto 0);
	signal rom_data : std_logic_vector(15 downto 0);

begin

	rom0 : ROM_VHDL PORT MAP (
		clk => clk,
		addr => PC,
		data => rom_data
	);

	rf0: register_file PORT MAP (
		rst => rst,
		clk => clk,
		rd_index1 => rd_index1,
		rd_index2 => rd_index2,
		rd_data1 => rd_data1,
		rd_data2 => rd_data2,
		wr_index => wr_index,
		wr_data => reg_EX.result,
		wr_enable => wr_enable,
		wr_overflow_data => reg_EX.overflow,
		wr_overflow => wr_overflow
	);
	
	alu0: alu PORT MAP (
		rst => rst,
		clk => clk,
		alu_mode => alu_mode,
		in1 => in1,
		in2 => in2,
		result => result,
		overflow => overflow,
		z_flag => z_flag,
		n_flag => n_flag
	);
	
-- COMBINATIONAL LOGIC
	                                                                                        -- add instruction on BRANCH or OUT
	alu_mode <= reg_ID.instr(11 downto 9) when (opcode(reg_ID.instr) <= 7) else "001" when ((opcode(reg_ID.instr)>=64 AND opcode(reg_ID.instr)<=71) OR opcode(reg_ID.instr)=33) else "000";

	rd_index1 <= reg_IF.instr(8 downto 6) when ra_instr(reg_IF.instr) else "111" when (opcode(reg_IF.instr)=71) else reg_IF.instr(5 downto 3);
	rd_index2 <= reg_IF.instr(2 downto 0);
	
	wr_index <= "111" when (opcode(reg_EX.instr)=70) else reg_EX.instr(8 downto 6); -- r7 when BR.SUB otherwise ra
	
	wr_enable <= '1' when (wr_instr(reg_EX.instr) AND reg_EX.write_ignore='0')	else '0';
	wr_overflow <= '1' when (wr_instr(reg_EX.instr) AND reg_EX.instr(11 downto 9)="011" AND reg_EX.write_ignore='0') else '0';
	
	-- we're branching, so PC gets set to branch address and writeback disabled for current instruction
	PC_next <= reg_EX.result(6 downto 0) when (branch_trigger='1') else std_logic_vector(unsigned(PC) + instr_mem_size);
	
	branch_trigger <= '1' when reg_EX.write_ignore='0' AND ( -- not currently branching
		(opcode(reg_EX.instr)=64 OR opcode(reg_EX.instr)=70 OR opcode(reg_EX.instr)=71) -- BRR, BR.SUB or RETURN instruction (always branch)
		OR ((opcode(reg_EX.instr)=65 OR opcode(reg_EX.instr)=68) AND reg_EX.n_flag='1') -- if NEG branch
		OR ((opcode(reg_EX.instr)=66 OR opcode(reg_EX.instr)=69) AND reg_EX.z_flag='1') -- if ZERO branch
	) else '0';
	
	-- result forwarding {
	-- (may need to add load instruction support, branch instructions should be covered by branch
	in1 <= reg_EX.overflow when ( -- check for overflow forward
		opcode(reg_EX.instr)=3 AND ( -- when last instruction was multiply
			(a1_instr(reg_ID.instr) AND reg_ID.instr(5 downto 3)="111") -- A1 instruction and rb=7
			OR (ra_instr(reg_ID.instr) AND reg_ID.instr(8 downto 6)="111") -- A2/OUT instruction and ra=7
		)
	) else reg_EX.result when ( -- check for result forward
		wr_instr(reg_EX.instr) AND ( -- last instruction is writing back
			(a1_instr(reg_ID.instr) AND reg_ID.instr(5 downto 3)=reg_EX.instr(8 downto 6)) -- A1, instruction and rb=writeback register
			OR (ra_instr(reg_ID.instr) AND reg_ID.instr(8 downto 6)=reg_EX.instr(8 downto 6)) -- A2/OUT ra=writeback register
		)
	) else reg_ID.data1;
	
	in2 <= reg_EX.overflow when ( -- check for overflow forward
		opcode(reg_EX.instr)=3 AND ( -- when last instruction was multiply
			(a1_instr(reg_ID.instr) AND reg_ID.instr(2 downto 0)="111") -- A1 instruction and rc=7
		)
	) else reg_EX.result when ( -- check for result forward
		wr_instr(reg_EX.instr) AND ( -- last instruction is writing back
			(a1_instr(reg_ID.instr) AND reg_ID.instr(2 downto 0)=reg_EX.instr(8 downto 6)) -- A1, instruction and rc=writeback register
		)
	) else reg_ID.data2;
	
	-- } end result forwarding
	
	PCUpdate: process(clk, rst) is
	begin
		if (rst='1') then
			PC <= (others => '0');
		elsif rising_edge(clk) then -- (not rst)
--			if (branch_trigger='1') then
--				PC <= reg_EX.result(6 downto 0);
--			else
--				PC <= std_logic_vector(unsigned(PC) + instr_mem_size);
--			end if;
			PC <= PC_next;
		end if;
	end process;
	
	InstructionFetch: process(clk, rst) is
	begin
		if (rst='1') then
			reg_IF.instr <= (others => '0');
			reg_IF.inport <= (others => '0');
			reg_IF.PC <= (others => '0');
		elsif rising_edge(clk) then -- (not rst)
			reg_IF.instr <= rom_data;
			reg_IF.inport <= inport;
			reg_IF.PC <= PC;
			
			-- set current instruction write ignore (if branching true, false if subsequent)
			if (branch_trigger='1') then
				reg_IF.write_ignore <= '1';
			else
				reg_IF.write_ignore <= '0';
			end if;
		end if;
	end process;
	
	InstructionDecode: process(clk, rst) is
	begin
		if (rst='1') then
			reg_ID.instr <= (others => '0');
			reg_ID.data1 <= (others => '0');
			reg_ID.data2 <= (others => '0');
			reg_ID.PC <= (others => '0');
		elsif rising_edge(clk) then -- (not rst)		
			reg_ID.instr <= reg_IF.instr;
			reg_ID.PC <= reg_IF.PC;
			reg_ID.write_ignore <= reg_IF.write_ignore;
			
			-- Determine rd_index1 and set data2 (potentially from rd_data2)
			if (opcode(reg_IF.instr)=33) then -- IN instruction (ra and 0)
				-- IN operation (IN port)
				reg_ID.data1 <= reg_IF.inport;
				reg_ID.data2 <= x"0000";
			elsif (opcode(reg_IF.instr)=71) then -- RETURN instruction, want r7 (rd_data1) and 0
				reg_ID.data1 <= rd_data1;
				reg_ID.data2 <= x"0000";
			elsif (ra_instr(reg_IF.instr)) then -- A2 instruction (A3 already checked)
				-- ra and cl (immediate)
				reg_ID.data1 <= rd_data1;
				if (opcode(reg_ID.instr)=32) then -- OUT, null cl
					reg_ID.data2 <= x"0000";
				else -- ignore cl (short to 0)
					reg_ID.data2 <= std_logic_vector(resize(signed(reg_IF.instr(3 downto 0)),16));
				end if;
			elsif (b1_instr(reg_IF.instr)) then -- B1 branch (PC and disp.l)
				reg_ID.data1 <= std_logic_vector(resize(unsigned(PC),16));
				reg_ID.data1 <= std_logic_vector(resize(signed(reg_IF.instr(8 downto 0)),16)); -- disp.l
			elsif (b2_instr(reg_IF.instr)) then -- B2 branch (ra and disp.s)
				reg_ID.data1 <= rd_data1;
				reg_ID.data1 <= std_logic_vector(resize(signed(reg_IF.instr(5 downto 0)),16)); -- disp.s
			else
				-- rb and rd_data2 (reg)
				reg_ID.data1 <= rd_data1;
				reg_ID.data2 <= rd_data2;
			end if;
			
			-- Disable writing back for this instruction if branching
			if (branch_trigger='1') then
				reg_ID.write_ignore <= '1';
			end if;
		end if;
	end process;
				
	Execution: process(clk, rst) is
	begin
		if (rst='1') then
			reg_EX.instr <= (others => '0');
			reg_EX.result <= (others => '0');
			reg_EX.overflow <= (others => '0');
			reg_EX.PC <= (others => '0');
			reg_EX.z_flag <= '0';
			reg_EX.n_flag <= '0';
		elsif rising_edge(clk) then -- (not rst)
			if (unsigned(reg_EX.instr(15 downto 9))=32) then
				outport <= reg_EX.result;
			else
				outport <= (others => '0');
			end if;
			
			reg_EX.instr <= reg_ID.instr;
			reg_EX.PC <= reg_ID.PC;
			reg_EX.write_ignore <= reg_ID.write_ignore;

			if (unsigned(reg_ID.instr(15 downto 9))=32) then
				reg_EX.result <= reg_ID.data1;
			else
				reg_EX.result <= result;
			end if;
			reg_EX.overflow <= overflow;
			reg_EX.z_flag <= z_flag;
			reg_EX.n_flag <= n_flag;
			
			-- Disable writing back for this instruction if branching
			if (branch_trigger='1') then
				reg_EX.write_ignore <= '1';
			end if;
		end if;
	end process;

end Behavioral;

