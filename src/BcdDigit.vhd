----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:39:38 10/11/2007 
-- Design Name: 
-- Module Name:    BcdDigit - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity BcdDigit is
    Port ( Clk :    in  STD_LOGIC;
           Init :   in  STD_LOGIC;
			  DoneIn:  in  STD_LOGIC;
           ModIn :  in  STD_LOGIC;
           ModOut : out  STD_LOGIC;
           Q :      out  STD_LOGIC_VECTOR (3 downto 0));
end BcdDigit;

architecture Behavioral of BcdDigit is
   signal Bcd: STD_LOGIC_VECTOR (3 downto 0);
begin
   process( Clk,Init)
	begin
	   if rising_edge( Clk) then
		   if Init='1' then
			   Bcd <= "0000";
			elsif DoneIn='0' then
				case Bcd is
					when "0000" => Bcd <= "000" & ModIn;  -- 0*2 + ModIn
					when "0001" => Bcd <= "001" & ModIn;  -- 1*2 + ModIn
					when "0010" => Bcd <= "010" & ModIn;  -- 2*2 + ModIn
					when "0011" => Bcd <= "011" & ModIn;  -- 3*2 + ModIn						
					when "0100" => Bcd <= "100" & ModIn;  -- 4*2 + ModIn
					when "0101" => Bcd <= "000" & ModIn;  -- 5*2 + ModIn (ModOut=1)
					when "0110" => Bcd <= "001" & ModIn;  -- 6*2 + ModIn (ModOut=1)
					when "0111" => Bcd <= "010" & ModIn;  -- 7*2 + ModIn (ModOut=1)
					when "1000" => Bcd <= "011" & ModIn;  -- 8*2 + ModIn (ModOut=1)						
					when "1001" => Bcd <= "100" & ModIn;  -- 9*2 + ModIn (ModOut=1)
					when others => Bcd <= "0000";						
				end case;
			end if;
		end if;	
	end process;
	
	ModOut <= '1' when Bcd>=5 else '0';
	Q      <= Bcd;

end Behavioral;