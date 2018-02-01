----------------------------------------------------------------------------------
-- ALU8_16.vhd
-- Implements an ALU unit for a 16 bit processor.
-- Inputs:
--		[in]	in1		- operand register 1
--		[in]	in2		- operand register 2
--		[in]	alu_mode	- operation to perform
--		[in]	clk		- clk signal
--		[in]	rst		- reset signal
--
--		[out]	result	- result of operation
--		[out]	z_flag	- zero test flag
--		[out]	n_flag	- negative test flag
--
--	Operations:
--		MODE	OP		DESCRIPTION
--		000	NOP	Do nothing
--		001	ADD	Add `in1` to `in2`
--		002	SUB	Subtract `in2` from `in1`
--		003	MUL	Multiply `in1` with `in2`
--		004	NAND	Bitwise NAND operation between `in1` and `in2`
--		005	SHL	Logically shift `in1` left by `in2`
--		006	SHR	Logically shift `in1` right by `in2`
--		007	TEST	Test properties of `in1` (`in2` ignored)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port ( in1 : in  STD_LOGIC_VECTOR (15 downto 0);
           in2 : in  STD_LOGIC_VECTOR (15 downto 0);
           alu_mode : in  STD_LOGIC_VECTOR (2 downto 0);
           clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           result : out  STD_LOGIC_VECTOR (15 downto 0);
           z_flag : out  STD_LOGIC;	-- zero
           n_flag : out  STD_LOGIC); -- negative
end alu;

architecture Behavioral of alu is

begin

-- add
result <= (others => '0') when (rst='1') else
		std_logic_vector(signed(in1) + signed(in2)) when (alu_mode = "001") else
		-- sub
		std_logic_vector(signed(in1) - signed(in2)) when (alu_mode = "010") else
		-- mult
		std_logic_vector(resize(signed(in1) * signed(in2), 16)) when (alu_mode = "011") else
		-- nand
		in1 nand in2 when (alu_mode = "100") else
		-- shl
		std_logic_vector(shift_left(unsigned(in1), to_integer(signed(in2)))) when (alu_mode = "101") else
		-- shr
		std_logic_vector(shift_right(unsigned(in1), to_integer(signed(in2)))) when (alu_mode = "110") else
		-- default
		(others => '0');

process(clk, rst) begin
	if (rst='1') then
		n_flag <= '0'; z_flag <= '0';
	elsif (clk = '1' and clk'event and alu_mode = "111") then
		if (signed(in1) < 0) then
			n_flag <= '1'; z_flag <= '0';
		elsif (signed(in1) = 0) then
			n_flag <= '0'; z_flag <= '1';
		else
			n_flag <= '0'; z_flag <= '0';
		end if;
	end if;
end process;

end Behavioral;

