Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY ctr449 IS
PORT(
		RESET : IN std_logic;
		XDSD,DIF0,DIF1,DIF2,ESMUTE,DEM0,GC : IN std_logic;
		SD,SLOW,MONO,DSDSEL0,DSDSEL1,DSDF : IN std_logic;
		SSLOW,DSDD,SC0,SC1,SC2,RACSEL,AK4499 : IN std_logic;
		CLK_10M : IN std_logic;
		DATA_DSDL,LRCK_DSDR,CLK_SEL,BCK_DSDCLK,LRCK0 : IN std_logic;
		CLK_22M,CLK_24M,CPOK : IN std_logic;
		PHA : IN std_logic;
		PHB : IN std_logic;
		MUTE_IN : std_logic;
		DISPSW : IN std_logic;
		CSN,CCLK,CDTI : OUT std_logic;
		MCLK,SCK,BCLK,DATA,LRCK,ENCLK_22M,ENCLK_24M : OUT std_logic;
		LED_DSD : OUT std_logic;
		LED_PCM : OUT std_logic;
		LED_96K : OUT std_logic;
		MUTE : OUT std_logic;
		LED_DSD_P : OUT std_logic;
		LED_PCM_P : OUT std_logic;
		COMSEL : OUT std_logic_vector(3 downto 0);
		LED : OUT std_logic_vector(7 downto 0));
END ctr449;

ARCHITECTURE RTL OF ctr449 IS

component regctr
	PORT(
		RESET : IN std_logic;
		CLK : IN std_logic;
		CLK_MSEC : IN std_logic;
		XDSD : IN std_logic;
		DIF0 : IN std_logic;
		DIF1 : IN std_logic;
		DIF2 : IN std_logic;
		SMUTE : IN std_logic;
		DEM0 : IN std_logic;
		GC : IN std_logic;
		SD : IN std_logic;
		SLOW : IN std_logic;
		MONO : IN std_logic;
		DSDSEL0 : IN std_logic;
		DSDSEL1 : IN std_logic;
		DSDF : IN std_logic;
		SSLOW : IN std_logic;
		DSDD : IN std_logic;
		SC0 : IN std_logic;
		SC1 : IN std_logic;
		SC2 : IN std_logic;
		AK4490 : IN std_logic;
		AK4499 : IN std_logic;
		ATTCOUNT : IN std_logic_vector(7 downto 0);
		CSN : OUT std_logic;
		CCLK : OUT std_logic;
		CDTI : OUT std_logic);
end component;

component clkgen 
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
end component;

component attcnt
	port(
			CLK : IN std_logic;
			RESET_N : IN std_logic;
			A : IN std_logic;
			B : IN std_logic;
			CNTUP : OUT std_logic;
			CNTDWN : OUT std_logic;
			Q : OUT std_logic_vector(7 downto 0));
end component;

component detect_fs
	PORT(
			XDSD : in std_logic;
			MCLK : in std_logic;
			LRCK : in std_logic;
			CK_SEL : in std_logic;
			CPOK : in std_logic;
			OV96K : out std_logic);
end component;

component dispctr
	PORT(
		RESET : IN std_logic;
		CLK : IN std_logic;
		CHAT_CLK : IN std_logic;
		ENDIVCLK : IN std_logic;
		ATTDWN : IN std_logic;
		ATTUP : IN std_logic;
		DISPSW : IN std_logic;
		DIN : IN std_logic_vector(7 downto 0);
		COMSEL : OUT std_logic_vector(3 downto 0);
		LED : OUT std_logic_vector(7 downto 0));
end component;

component BcdDigit
	Port ( Clk :    in  STD_LOGIC;
		  Init :   in  STD_LOGIC;
		  DoneIn:  in  STD_LOGIC;
		  ModIn :  in  STD_LOGIC;
		  ModOut : out  STD_LOGIC;
		  Q :      out  STD_LOGIC_VECTOR (3 downto 0));
end component;

component seven_segdec
	port (
		DIN   : in	std_logic_vector(3 downto 0);
		DOUT  : out std_logic_vector(7 downto 0) );
end component;

signal clk,clk_msec,iMCLK,iSCK,ilrck,iMUTE,ov96k : std_logic;
signal chat_clk,endivclk,attdwn,attup : std_logic;
signal ak4490,smute : std_logic;
signal attcount : std_logic_vector(7 downto 0);

begin

	R1 : regctr port map (RESET => cpok,CLK => CLK_10M,CLK_MSEC => clk_msec,XDSD => xdsd,
								DIF0 => dif0,DIF1 => dif1,DIF2 => dif2,SMUTE => smute,
								DEM0 => dem0,GC => gc,SD => sd,SLOW => slow,
								MONO => mono,DSDSEL0 => dsdsel0,DSDSEL1 => dsdsel1,DSDF => dsdf,
								SSLOW => sslow,DSDD => dsdd,SC0 => sc0,SC1 => sc1,SC2 => sc2,AK4490 => ak4490,AK4499 => ak4499,
								ATTCOUNT => attcount,CSN => csn,CCLK => cclk,CDTI => cdti); 

	C1 : clkgen port map (RESET => cpok,CLK => CLK_10M,CLK_24M => clk_24m,CLK_22M => clk_22m,
								CPOK => cpok,CLK_SEL => clk_sel,CLK_MSEC => clk_msec,
								ENCLK_22M => enclk_22m,ENCLK_24M => enclk_24m,MCLK => iMCLK,SCK => iSCK,
								CLK_FIL => chat_clk,ENDIVCLK => endivclk);--,CLK_10M => clk_10m);
								
	A1 : attcnt port map (CLK => CLK_10M,RESET_N => cpok,A => PHA, B => PHB,CNTUP => attup,CNTDWN => attdwn,
								Q => attcount);
	
	D1 : detect_fs port map (XDSD => xdsd,MCLK => isck,LRCK => ilrck,CK_SEL => clk_sel,CPOK => CPOK,OV96K => ov96k );

	D2 : dispctr port map (RESET => cpok,CLK => clk_10M,CHAT_CLK => chat_clk,ENDIVCLK => endivclk,ATTDWN => attdwn,
								ATTUP => attup,DISPSW => DISPSW,DIN => attcount,COMSEL => comsel,LED => LED);
	ak4490 <= not RACSEL;	
	
	ilrck <= LRCK0 when XDSD = '1' else LRCK_DSDR;
	LRCK <= ilrck;
	DATA <= DATA_DSDL;
	BCLK <= BCK_DSDCLK;

	MCLK <= iMCLK when CPOK = '1' else 'Z';
	SCK <= iSCK when CPOK = '1' else 'Z';
	
	LED_DSD <= XDSD when CPOK = '1' else '1';	--RESET to CPOK
	LED_PCM <= not XDSD when CPOK = '1' else '1';	--RESET to CPOK
	LED_96K <= ov96k when CPOK = '1' else '1';	--RESET to CPOK
	
	LED_DSD_P <= XDSD when CPOK = '1' else '1';	--RESET to CPOK
	LED_PCM_P <= not XDSD when CPOK = '1' else '1';	--RESET to CPOK
	
	MUTE <= 'Z' when (CPOK and not MUTE_IN) = '1' else '0';	--RESET to CPOK
	smute <= '0' when ESMUTE = '0' else MUTE_IN;
	

end RTL;