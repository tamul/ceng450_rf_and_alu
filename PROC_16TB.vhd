--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:05:12 02/15/2018
-- Design Name:   
-- Module Name:   /home/mtayler/ceng450/processor/PROC_16TB.vhd
-- Project Name:  processor
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: processor
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_misc.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY PROC_16TB IS
END PROC_16TB;
 
ARCHITECTURE behavior OF PROC_16TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT processor
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
			inport : IN std_logic_vector(15 downto 0);
			outport : OUT std_logic_vector(15 downto 0)
        );
    END COMPONENT;

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
	signal inport : std_logic_vector(15 downto 0) := (others => '0');

 	--Outputs
   signal outport : std_logic_vector(15 downto 0);
--	signal display : std_logic_vector(15 downto 0);
--	signal an : std_logic_vector(3 downto 0);
--	signal sseg : std_logic_vector(6 downto 0);

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: processor PORT MAP (
          clk => clk,
          rst => rst,
			 inport => inport,
			 outport => outport
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	
--	disp_proc: process(clk, outport)
--	begin
--		if rising_edge(clk) then
--			if or_reduce(outport) /= '0' then
--				display <= outport;
--			end if;
--		end if;
--	end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns
		rst <= '1';
		inport <= x"0004";
      wait for 95 ns;
		
--		wait until falling_edge(clk); wait for clk_period/4;
		rst <= '0';

      wait;
   end process;

END;
