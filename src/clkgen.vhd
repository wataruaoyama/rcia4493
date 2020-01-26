Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY clkgen IS
PORT(
		RESET : IN std_logic;
		CLK : IN std_logic;
		CLK_24M : IN std_logic;
		CLK_22M : IN std_logic;
		CPOK : IN std_logic;
		CLK_SEL : IN std_logic;
		CLK_MSEC : OUT std_logic;
		ENCLK_24M : OUT std_logic;
		ENCLK_22M : OUT std_logic;
		MCLK : OUT std_logic;
		SCK : OUT std_logic;
		CLK_FIL : OUT std_logic;
		ENDIVCLK : OUT std_logic);
--		CLK_10M : OUT std_logic);
END clkgen;

ARCHITECTURE RTL OF clkgen IS

signal iMCLK,iSCK : std_logic;
signal counter_msec : std_logic_vector(19 downto 0);
--signal counter_msec : std_logic_vector(21 downto 0);

constant sim : integer := 0;

BEGIN

--Use 10MHz OSC
--Generate 100msec timer
process(RESET,CLK) BEGIN
	if(RESET = '0') then
		counter_msec <= "00000000000000000000";
	elsif(CLK'event and CLK='1') then
		counter_msec <= counter_msec + '1';
	end if;
end process;

COMPILE : if sim /= 1 generate
CLK_MSEC <= counter_msec(19);	-- about 100msec. 
end generate;
--End Use 10MHz OSC

--Use MCLK
--process(RESET,iMCLK) BEGIN
--	if(RESET = '0') then
--		counter_msec <= "0000000000000000000000";
--	elsif(iMCLK'event and iMCLK='1') then
--		counter_msec <= counter_msec + '1';
--	end if;
--end process;

--COMPILE : if sim /= 1 generate
--CLK_MSEC <= counter_msec(21);	-- about 100msec. 
--end generate;
--End Use MCLK

SIMULATION : if sim = 1 generate
CLK_MSEC <= counter_msec(13);	
end generate;

ENCLK_22M <= not CLK_SEL;
ENCLK_24M <= CLK_SEL;

iMCLK <= CLK_22M when CLK_SEL = '0' else CLK_24M;
MCLK <= iMCLK;
SCK <= iMCLK;

--Use 10MHz OSC
CLK_FIL <= counter_msec(17);	-- Clock for chattering canceller: about 25ms
ENDIVCLK <= counter_msec(14);	-- about 610Hz
--End Use 10MHz OSC

--Use MCLK
--CLK_FIL <= counter_msec(19);	-- Clock for chattering canceller: about 40ms
--ENDIVCLK <= counter_msec(14);	-- about 7000Hz

--CLK_10M <= counter_msec(1);	-- about 6MHz clodk at 24/22MHz MCLK
--End Use MCLK

end RTL;