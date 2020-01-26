Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY dispctr IS
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
END dispctr;

ARCHITECTURE RTL OF dispctr IS

component seven_segdec
	port (
		DIN   : in	std_logic_vector( 3 downto 0);
		DOUT  : out std_logic_vector( 7 downto 0));
end component;

component BcdDigit
    Port ( Clk :    in  STD_LOGIC;
           Init :   in  STD_LOGIC;
           DoneIn:  in  STD_LOGIC;
           ModIn :  in  STD_LOGIC;
           ModOut : out  STD_LOGIC;
           Q :      out  STD_LOGIC_VECTOR (3 downto 0));
end component;

signal att4thdig,att3rddig,att2nddig,att1stdig,selreg,muxsel,bcdo : std_logic_vector(3 downto 0);
signal dout : std_logic_vector(7 downto 0);
signal inv_din : std_logic_vector(7 downto 0);
signal shift_reg : std_logic_vector(6 downto 0);
signal count : std_logic_vector(2 downto 0);
signal done_node : std_logic;
signal modout0, modout1 : std_logic;
signal load : std_logic;
signal init : std_logic;
signal shiftout : std_logic;
signal detdispsw,ledon : std_logic;


begin
-- Call the three BcdDigit instance
BcdDigit0 : BcdDigit port map(
	Clk => clk,
	Init => init,
	DoneIn => done_node,
	ModIn => shift_reg(6),
	ModOut => modout0,
	Q => att2nddig
	);
BcdDigit1 : BcdDigit port map(
	Clk => clk,
	Init => init,
	DoneIn => done_node,
	ModIn => modout0,
	ModOut => modout1,
	Q => att3rddig
	);
BcdDigit2 : BcdDigit port map(
	Clk => clk,
	Init => init,
	DoneIn => done_node,
	ModIn => modout1,
	ModOut => open,
	Q => att4thdig
	);

--Call the Seven Segment Decoder instance
seg1 : seven_segdec port map(DIN => bcdo,DOUT => dout);

-- Inverts the data of the attenuator
inv_din(7) <= not DIN(7);
inv_din(6) <= not DIN(6);
inv_din(5) <= not DIN(5);
inv_din(4) <= not DIN(4);
inv_din(3) <= not DIN(3);
inv_din(2) <= not DIN(2);
inv_din(1) <= not DIN(1);
inv_din(0) <= not DIN(0);
 
-- Shift the binary data
process(clk) begin
	if clk'event and clk='1' then
		if init='1' then
			shift_reg <= (others => '0');
		else
			if load='1' then
				shift_reg <= inv_din(7 downto 1);
			else
				shift_reg <= shift_reg(5 downto 0) & '0';
			end if;
		end if;
	end if;
end process;
    
-- Initialize the BcdDigit
init <= ATTUP or ATTDWN;

process(clk) begin
	if clk'event and clk='1' then
		load <= init;
	end if;
end process;

process(clk) begin
	if clk'event and clk='1' then
			if load='1' then
				count <= (others => '0');
				done_node <= '0';
			elsif count = "110" then
				count <= count;
				done_node <= '1';
			else
				count <= count + '1';
				done_node <= '0';
			end if;
	end if;
end process;

----Chattering canceller for attenuator switches
process(CHAT_CLK,DISPSW) begin
	if(DISPSW = '1') then
		detdispsw <= '1';
	elsif(CHAT_CLK'event and CHAT_CLK='1') then
		detdispsw <= DISPSW;
	end if;
end process;

--Control the 7 segment leds
process(detdispsw,RESET) begin
	if RESET = '0' then
		ledon <= '1';
	elsif detdispsw'event and detdispsw='1' then
			ledon <= not ledon;
	end if;
end process;

--Circular shift register
process(RESET,ENDIVCLK) begin
	if RESET = '0' then
		selreg <= "0001";
	elsif(ENDIVCLK'event and ENDIVCLK='1') then
		selreg(0) <= selreg(3);
		selreg(1) <= selreg(0);
		selreg(2) <= selreg(1);
		selreg(3) <= selreg(2);
	end if;
end process;

--Digit select signal
COMSEL(0) <= not selreg(0);
COMSEL(1) <= not selreg(1);
COMSEL(2) <= not selreg(2);
COMSEL(3) <= not selreg(3);

--BCD data select signal
muxsel(0) <= selreg(0);
muxsel(1) <= selreg(1);
muxsel(2) <= selreg(2);
muxsel(3) <= selreg(3);
 
att1stdig(3) <= '0';
att1stdig(2) <= inv_din(0);
att1stdig(1) <= '0';
att1stdig(0) <= inv_din(0); 

process(muxsel,att1stdig,att2nddig,att3rddig,att4thdig)begin
	case muxsel is
		when "0001" => bcdo <= att1stdig;
		when "0010" => bcdo <= att2nddig;
		when "0100" => bcdo <= att3rddig;
		when "1000" => bcdo <= att4thdig;
		when others => bcdo <= "0000";
	end case;
end process;

process(ledon,dout,reset) begin
	if reset = '1' then
		if ledon = '1' then
			LED <= dout;
		else
			LED <= "11111111";
		end if;
	else
		LED <= "11111111";
	end if;
end process;

end RTL;