--
--
--
--
--
--
Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

entity attcnt is
port(
		CLK : IN std_logic;
		RESET_N : IN std_logic;
		A : IN std_logic;
		B : IN std_logic;
		CNTUP : OUT std_logic;
		CNTDWN : OUT std_logic;
		Q : OUT std_logic_vector(7 downto 0));
end attcnt;

architecture RTL of attcnt is

signal q_fb : std_logic_vector(7 downto 0);
--signal q_fb : std_logic_vector(8 downto 0);
signal s0,s1 : std_logic_vector(1 downto 0);
signal up,down : std_logic;

begin

process(s0,s1) begin
	if (s0 = "00" and s1 = "01") or 
		(s0 = "01" and s1 = "11") or 
		(s0 = "11" and s1 = "10") or 
		(s0 = "10" and s1 = "00") then
		up <= '1';
	elsif (s0 = "00" and s1 = "10") or	
		(s0 = "01" and s1 = "00") or 
		(s0 = "11" and s1 = "01") or 
		(s0 = "10" and s1 = "11") then
		down <= '1';
	else
		up <= '0'; down <= '0';
	end if;
end process;

CNTUP <= up; CNTDWN <= down;

process(RESET_N,CLK) begin
	if(RESET_N = '0') then
		s0 <= "00"; s1 <= "00";
		q_fb <= "11111111";
--		q_fb <= "111111111";
		elsif(CLK'event and CLK='1') then
		s0 <= (A & B); s1 <= s0;
		if(up = '1') then
			if(q_fb = "11111111") then
--			if(q_fb = "111111111") then
				q_fb <= q_fb;
			else 
				q_fb <= q_fb + '1';
--				q_fb <= q_fb + 2;
			end if;
		elsif(down = '1') then
			if(q_fb = "00000000") then
--			if(q_fb = "000000000") then
				q_fb <= q_fb;
			else
				q_fb <= q_fb - '1';
--				q_fb <= q_fb - 2;
			end if;
		else
			q_fb <= q_fb;
		end if;
	end if;
end process;

q <= q_fb;
--	q(7) <= q_fb(8);
--	q(6) <= q_fb(7);
--	q(5) <= q_fb(6);
--	q(4) <= q_fb(5);
--	q(3) <= q_fb(4);
--	q(2) <= q_fb(3);
--	q(1) <= q_fb(2);
--	q(0) <= q_fb(1);
	
end rtl;