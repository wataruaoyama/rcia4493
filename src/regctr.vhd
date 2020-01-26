  Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY regctr IS
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
END regctr;

ARCHITECTURE RTL OF regctr IS


signal icclk,d_csn,cen,edge_timer,rstn,ddp,delay_clk_msec : std_logic;
signal attenup,attendwn,endivclk,enatt3rddig,enatt4thdig,regaddrcnt_en : std_logic;
signal dcounter_sys5,icsn,rstdp,chipaddr,vlmbp : std_logic;
signal sellr1,sellr2,mono1,mono2,invl1,invr1,invl2,invr2 : std_logic;
signal counter_sys : std_logic_vector(10 downto 0);
signal delay,detswdwn,detswup : std_logic_vector(1 downto 0);
signal regaddrcnt : std_logic_vector(4 downto 0);
signal regd : std_logic_vector(7 downto 0);
signal siftreg : std_logic_vector(15 downto 0);

type states IS ( clear,count1,count2);
signal present_state: states;
signal next_state: states;

constant ak4490_stereo : std_logic_vector(11 downto 0) := "001001100000";
constant ak4490_mono : std_logic_vector(11 downto 0) := "010011000000";
--constant ak4497_stereo : std_logic_vector(11 downto 0) := "010101100000";	-- 1376
--constant ak4497_mono : std_logic_vector(11 downto 0) := "101011000000";		-- 2752
constant ak4497_stereo : std_logic_vector(11 downto 0) := "001111100000";	-- 992
constant ak4497_mono : std_logic_vector(11 downto 0) := "011111000000";		-- 1984
constant regaddr_ak4490 : std_logic_vector(4 downto 0) := "01001";
constant regaddr_ak4497 : std_logic_vector(4 downto 0) := "01111";
constant regaddr_zero : std_logic_vector(4 downto 0) := "00000";

-- Register address
constant Control1 : std_logic_vector(4 downto 0) := "00000";
constant Control2 : std_logic_vector(4 downto 0) := "00001";
constant Control3 : std_logic_vector(4 downto 0) := "00010";
constant L1ch_ATT : std_logic_vector(4 downto 0) := "00011";
constant R1ch_ATT : std_logic_vector(4 downto 0) := "00100";
constant Control4 : std_logic_vector(4 downto 0) := "00101";
constant DSD1 : std_logic_vector(4 downto 0) := "00110";
constant Control5 : std_logic_vector(4 downto 0) := "00111";
constant Sound_Control : std_logic_vector(4 downto 0) := "01000";
constant DSD2 : std_logic_vector(4 downto 0) := "01001";
constant Control6 : std_logic_vector(4 downto 0) := "01010";
constant Control7 : std_logic_vector(4 downto 0) := "01011";
constant L2ch_ATT : std_logic_vector(4 downto 0) := "01100";
constant R2ch_ATT : std_logic_vector(4 downto 0) := "01101";
constant Reserved1 : std_logic_vector(4 downto 0) := "01110";
constant Reserved2 : std_logic_vector(4 downto 0) := "01111";
constant Reserved3 : std_logic_vector(4 downto 0) := "10000";
constant Reserved4 : std_logic_vector(4 downto 0) := "10001";
constant Reserved5 : std_logic_vector(4 downto 0) := "10010";
constant Reserved6 : std_logic_vector(4 downto 0) := "10011";
constant Reserved7 : std_logic_vector(4 downto 0) := "10100";
constant DFS_read : std_logic_vector(4 downto 0) := "10101";

BEGIN

CCLK <= icclk;
CSN <= icsn;

--Generate CSN
process(RESET,CLK) BEGIN
	if(RESET = '0') then
		counter_sys <= "01111111111";
	elsif(CLK'event and CLK='1') then
		if(cen = '1') then
			if(AK4490 = '1') then	-- AK4490/95
				if(counter_sys = ak4490_stereo) then	-- Stereo mode
					counter_sys <= counter_sys;
				else
					counter_sys <= counter_sys + '1';
				end if;
			else	-- AK4497
				if(counter_sys = ak4497_stereo) then	-- Stereo mode
					counter_sys <= counter_sys;
				else
					counter_sys <= counter_sys + '1';
				end if;
			end if;
		else
			counter_sys <= "11111111111";
		end if;
	end if;
end process;

process(RESET,CLK) begin
	if(RESET = '0') then
		dcounter_sys5 <= '1';
	elsif(CLK'event and CLK = '1') then
		dcounter_sys5 <= counter_sys(5);
	end if;
end process;

icsn <= counter_sys(5) and dcounter_sys5;

--Generate ICCLK
process(RESET,CLK) begin
	if(RESET = '0') then
		icclk <= '1';
	elsif(CLK'event and CLK='1') then
		if(cen = '1' and counter_sys(5) = '0') then
			icclk <= not icclk;
		else
			icclk <= '1';
		end if;
	end if;
end process;

process(CLK) begin
	if(CLK'event and CLK='1') then
		delay(1) <= delay(0);
		delay(0) <= XDSD;
	end if;
end process;

ddp <= delay(1) xor delay(0);

process(CLK) begin
	if(CLK'event and CLK='1') then
		delay_clk_msec <= clk_msec;
	end if;
end process;

edge_timer <= clk_msec and not delay_clk_msec;

--State machime to generate count enable signal for counter_sys
process(CLK,RESET) begin
	if (RESET = '0') then
		present_state <= clear;
	elsif (CLK'event and CLK = '1') then
		present_state <= next_state;
	end if;
end process;


--2020/01/15
process(present_state,ddp,delay_clk_msec,counter_sys,edge_timer,AK4490,MONO) begin
	case present_state is
		when clear => 
			cen <= '0';
			rstn <= '1';
			if(ddp = '1' and delay_clk_msec = '1') then
				next_state <= count1;
			elsif(ddp = '0' and edge_timer = '1') then
				next_state <= count2;
			elsif(ddp = '1' and edge_timer = '0') then
				next_state <= count1;
			else
				next_state <= present_state;
			end if;
		when count1 => 
			cen <= '1';
			rstn <= '0';
			if(AK4490 = '1') then	--AK4490/95
				if(counter_sys = ak4490_stereo) then	--CLK*2*32*10-32=608
					next_state <= clear;
				else
					next_state <= present_state;
				end if;
			else	--AK4497
				if(counter_sys = ak4497_stereo) then	--CLK*2*32*16-32=992
					next_state <= clear;
				else
					next_state <= present_state;
				end if;
			end if;
		when count2 =>
			cen <= '1';
			rstn <= '1';
			if(AK4490 = '1') then
				if(counter_sys = ak4490_stereo) then
					next_state <= clear;
				else
					next_state <= present_state;
				end if;
			else
				if(counter_sys = ak4497_stereo) then
					next_state <= clear;
				else
					next_state <= present_state;
				end if;
			end if;
	end case;
end process;

process(regaddrcnt,rstn) begin
	if(regaddrcnt = regaddr_zero) then
		rstdp <= rstn;
	else
		rstdp <= '1';
	end if;
end process;

--Resister address counter enable signal
Process(counter_sys(5 downto 0),MONO) begin
	if(counter_sys(5 downto 0) = "100000") then
		regaddrcnt_en <= '1';
	else
		regaddrcnt_en <= '0';
	end if;
end process;

--Resister address counter
process(RESET,CLK) begin
	if(RESET = '0') then
		regaddrcnt <= regaddr_zero;
	elsif(CLK'event and CLK = '1') then
		if(regaddrcnt_en = '1' and cen = '1') then
			if(AK4490 = '1' and regaddrcnt = regaddr_ak4490) then	--AK4490/AK4495
				regaddrcnt <= regaddr_zero;
			elsif(AK4490 = '0' and regaddrcnt = regaddr_ak4497) then	--AK4497/AK4493
				regaddrcnt <= regaddr_zero;
			else
				regaddrcnt <= regaddrcnt + '1';
			end if;
		else
			regaddrcnt <= regaddrcnt;
		end if;
	end if;
end process;
			

process (MONO,ak4499,chipaddr) begin
	if(ak4499 = '0') then
		if(MONO = '0') then
			mono1 <= '0';
			invl1 <= '0';
		else
			if(chipaddr = '0') then
				mono1 <= '1';
				sellr1 <= '0';
				invl1 <= '1';
			else
				sellr1 <= '1';
			end if;
		end if;
	else
		if(MONO = '0') then
			mono1 <= '1';
			sellr1 <= '0';
			invl1 <= '0';
			invr1 <= '0';
			mono2 <= '1';
			sellr2 <= '1';
			invl2 <= '0';
			invr2 <= '0';
		else
			if(chipaddr = '0') then
				mono1 <= '1';
				sellr1 <= '0';
				invl1 <= '0';
				invr1 <= '0';
				mono2 <= '1';
				sellr2 <= '0';
				invl2 <= '0';
				invr2 <= '0';
			else
				mono1 <= '1';
				sellr1 <= '1';
				invl1 <= '0';
				invr1 <= '0';
				mono2 <= '1';
				sellr2 <= '1';
				invl2 <= '0';
				invr2 <= '0';
			end if;
		end if;
	end if;
end process;


process (XDSD,DSDD) begin
	if(XDSD = '1') then
		vlmbp <= '0';
	else
		vlmbp <= DSDD;
	end if;
end process;
			
--Select external jumper status
process(regaddrcnt,DIF2,DIF1,DIF0,rstdp,SD,GC,DEM0,SMUTE,
		XDSD,MONO,sellr1,ak4499,SLOW,ATTCOUNT,SSLOW,vlmbp,DSDSEL0,SC0,SC1,SC2,DSDF,DSDSEL1) begin
	if(regaddrcnt = Control1) then
		regd(7) <= '1';	--ACKS ;Auto mode
		regd(6) <= '0';	--EXDF
		regd(5) <= '0';	--ECS
		regd(4) <= '0';
		regd(3) <= DIF2;	--DIF2
		regd(2) <= DIF1;	--DIF1
		regd(1) <= DIF0;	--DIF0
		regd(0) <= rstdp;	--RSTN
	elsif(regaddrcnt = Control2) then
		regd(7) <= '0';	--DZFE
		regd(6) <= '0';	--DZFM
		regd(5) <= SD;		--SD
		regd(4) <= '0';	--DFS1
		regd(3) <= '1';	--DFS0
		regd(2) <= '0';	--DEM1 ;Default off '0'
		regd(1) <= not DEM0;	--DEM0 ;Default off '1'
		regd(0) <= SMUTE;	--SMUTE
	elsif(regaddrcnt = Control3) then
		regd(7) <= not XDSD;	--DP
		regd(6) <= '0';
		regd(5) <= '0';		--DCKS
		regd(4) <= '0';		--DCKB
		regd(3) <= mono1;		--MONO1
		regd(2) <= '0';		--DZFB
		regd(1) <= sellr1;		--SELLR1
		regd(0) <= not SLOW;		--SLOW
	elsif(regaddrcnt = L1ch_ATT) then
		regd <= ATTCOUNT;	--ATT(7:0)
	elsif(regaddrcnt = R1ch_ATT) then
		regd <= ATTCOUNT;	--ATT(7:0)
	elsif(regaddrcnt = Control4) then
		regd(7) <= invl1;	--INVL1
		regd(6) <= invr1;	--INVR1
		regd(5) <= invl2;	--INVL2
		regd(4) <= invr2;	--INVR2
		regd(3) <= sellr2;	--SELLR2
		regd(2) <= '0';
		regd(1) <= '1';	--DFS2
		regd(0) <= not SSLOW;	--SSLOW
	elsif(regaddrcnt = DSD1) then
		regd(7) <= '1';		--DDM  Change "0" to "1" at Revision 1.1
		regd(6) <= '1';		--DML
		regd(5) <= '1';		--DMR
		regd(4) <= '0';		--DMC/DDMOE
		regd(3) <= '0';		--DMRE/DDMT1
		regd(2) <= '0';		-- _/DDMT0
		regd(1) <= vlmbp;		--DSDD
		regd(0) <= DSDSEL0;	--DSDSEL0
	elsif(regaddrcnt = Control5) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';	--_/GC2
		regd(2) <= GC;		--_/GC1
		regd(1) <= '1';	--_/GC0
		regd(0) <= '0';	--SYNCE
	elsif(regaddrcnt = Sound_Control) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';	--HLOAD at ak4497
		regd(2) <= SC2;	--SC2 at ak4495/97
		regd(1) <= SC1;	--SC1
		regd(0) <= SC0;	--SC0
	elsif(regaddrcnt = DSD2) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= ak4499;		--DSDPATH at ak4497/99
		regd(1) <= DSDF;		-- _/DSDF
		regd(0) <= not DSDSEL1;	--DSDSEL1
-- From resister address "0AH" to "0FH" is about for AK4497/AK4493
	elsif(regaddrcnt = Control6) then
		regd(7) <= '0';	--TDM1
		regd(6) <= '0';	--TDM0
		regd(5) <= '0';	--SDS1
		regd(4) <= '0';	--SDS2
		regd(3) <= '1';	--PW2
		regd(2) <= '1';	--PW1
		regd(1) <= '0';	--DEM2[1]
		regd(0) <= '1';	--DEM2[0]
	elsif(regaddrcnt = Control7) then
		regd(7) <= '0';	--ATS1
		regd(6) <= '0';	--ATS0
		regd(5) <= mono2;	--MONO2
		regd(4) <= '0';	--SDS0
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';	--DCHAIN
		regd(0) <= '0';	--TEST
	elsif(regaddrcnt = L2ch_ATT) then
		regd <= ATTCOUNT;	--ATT(7:0)
	elsif(regaddrcnt = R2ch_ATT) then
		regd <= ATTCOUNT;	--ATT(7:0)
	elsif(regaddrcnt = Reserved1) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = Reserved2) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
-- From resister address "10H" to "15H" can not use.
		elsif(regaddrcnt = Reserved3) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = Reserved4) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = Reserved5) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = Reserved6) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = Reserved7) then
		regd(7) <= '0';
		regd(6) <= '0';
		regd(5) <= '0';
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';
		regd(1) <= '0';
		regd(0) <= '0';
	elsif(regaddrcnt = DFS_read) then
		regd(7) <= '0';	--ADPE
		regd(6) <= '0';	--ADPT1
		regd(5) <= '0';	--ADPT0
		regd(4) <= '0';
		regd(3) <= '0';
		regd(2) <= '0';	--ADFS2
		regd(1) <= '0';	--ADFS1
		regd(0) <= '0';	--ADFS0
	else
--		regd <= regd;
		regd <= "11111111";
	end if;
end process;


--2020/01/15
process(reset,clk) begin
	if(reset = '0') then
		chipaddr <= '0';
	elsif(clk'event and clk='1') then
		if (MONO = '1') then
			if(edge_timer = '1') then
				chipaddr <= not chipaddr;
			else
				chipaddr <= chipaddr;
			end if;
		else
			chipaddr <= '0';
		end if;
	end if;
end process;

--Parallel to serial convetor to generate CDTI
process(RESET,CLK) begin
	if(RESET = '0') then
		siftreg <= "1111111111111111";
	elsif(CLK'event and CLK = '1') then
		if(counter_sys(5) = '1') then
			siftreg(15) <= chipaddr;	--Chip Address
			siftreg(14) <= '0';
			siftreg(13) <= '1';
			siftreg(12) <= regaddrcnt(4);
			siftreg(11) <= regaddrcnt(3);
			siftreg(10) <= regaddrcnt(2);
			siftreg(9) <= regaddrcnt(1);
			siftreg(8) <= regaddrcnt(0);
			siftreg(7) <= regd(7);
			siftreg(6) <= regd(6);
			siftreg(5) <= regd(5);
			siftreg(4) <= regd(4);
			siftreg(3) <= regd(3);
			siftreg(2) <= regd(2);
			siftreg(1) <= regd(1);
			siftreg(0) <= regd(0);
		else
			if(icclk = '1') then
				siftreg(1) <= siftreg(0);
				siftreg(2) <= siftreg(1);
				siftreg(3) <= siftreg(2);
				siftreg(4) <= siftreg(3);
				siftreg(5) <= siftreg(4);
				siftreg(6) <= siftreg(5);
				siftreg(7) <= siftreg(6);
				siftreg(8) <= siftreg(7);
				siftreg(9) <= siftreg(8);
				siftreg(10) <= siftreg(9);
				siftreg(11) <= siftreg(10);
				siftreg(12) <= siftreg(11);
				siftreg(13) <= siftreg(12);
				siftreg(14) <= siftreg(13);
				siftreg(15) <= siftreg(14);
				CDTI <= siftreg(15);
			else
				siftreg <= siftreg;
			end if;
		end if;
	end if;
end process;

end RTL;