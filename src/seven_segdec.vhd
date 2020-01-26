library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

entity seven_segdec is
	port (
		DIN   : in	std_logic_vector( 3 downto 0);
		DOUT  : out std_logic_vector( 7 downto 0) );
end seven_segdec;

architecture rtl of seven_segdec is
begin
  process( DIN )
  begin
   case  DIN is	-- Low active 
     when "0000" => DOUT <= "00000010";	-- 0:abcdef-
     when "0001" => DOUT <= "10011110";	-- 1:-bc----
     when "0010" => DOUT <= "00100100";	-- 2:ab-de-g
     when "0011" => DOUT <= "00001100";	-- 3:abcd--g
     when "0100" => DOUT <= "10011000";	-- 4:-bc--fg
     when "0101" => DOUT <= "01001000";	-- 5:a-cd-fg
     when "0110" => DOUT <= "01000000";	-- 6:a-cdefg
     when "0111" => DOUT <= "00011110";	-- 7:abc----
     when "1000" => DOUT <= "00000000";	-- 8:abcdefg
     when "1001" => DOUT <= "00001000";	-- 9:abcd-fg
     when "1010" => DOUT <= "00000100";	-- a:abcde-g
     when "1011" => DOUT <= "11000000";	-- b:--cdefg
     when "1100" => DOUT <= "01100010";	-- C:a--def-
     when "1101" => DOUT <= "10000100";	-- d:-bcde-g
     when "1110" => DOUT <= "01100000";	-- E:-bc----
     when "1111" => DOUT <= "01110000";	-- F:a--defg
     when others => DOUT <= "11111111";
--									  abcdefg.

						--High active
--		when "0000" => DOUT <= "11111100";
--		when "0001" => DOUT <= "01100000";
--		when "0010" => DOUT <= "11011010";
--		when "0011" => DOUT <= "11110010";
--		when "0100" => DOUT <= "01100110";
--		when "0101" => DOUT <= "10110110";
--    when "0110" => DOUT <= "10111110";
--		when "0111" => DOUT <= "11100000";
--		when "1000" => DOUT <= "11111110";
--		when "1001" => DOUT <= "11110110";
--		when "1010" => DOUT <= "11101110";
--		when "1011" => DOUT <= "00111110";
--		when "1100" => DOUT <= "10011100";
--		when "1101" => DOUT <= "01111010";
--		when "1110" => DOUT <= "10011110";
--		when "1111" => DOUT <= "10001110";
--		when others => DOUT <= "00000000";
--										abcdefg.
   end case;
  end process;
end rtl; 
                   
     
      
