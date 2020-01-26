Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY detect_fs IS
PORT(XDSD,MCLK,LRCK,CK_SEL,CPOK : IN std_logic;
		ov96k : OUT std_logic);
END detect_fs;

ARCHITECTURE RTL OF detect_fs IS

signal slrck,iov96k : std_logic;
signal fcount : std_logic_vector(8 downto 0);
signal q,f,FS : std_logic_vector(3 downto 0);
signal sreg : std_logic_vector(1 downto 0);


BEGIN

process(MCLK) begin
	if MCLK'event and MCLK='1' then
		sreg <= sreg(0) & LRCK;
	end if;
end process;

slrck <= sreg(1);

process(CPOK,MCLK,XDSD) BEGIN
	if(CPOK = '0' or XDSD = '0') then
		fcount <= "000000000";
	elsif(MCLK'event and MCLK='1') then
		if slrck = '1' then
			fcount <= fcount + '1';
		else
			fcount <= "000000000";
		end if;
	end if;
end process;

process(CPOK,XDSD,fcount,CK_SEL) begin
	if(CPOK = '0' or XDSD = '0') then
		q <= "1111";
	else	
		if CK_SEL = '0' then
			case fcount is
				when "011111111" => q <= "0001";	--44.1kHz
				when "001111111" => q <= "0011";	--88.2kHz
				when "000111111" => q <= "0101";	--176.4kHz
				when "000011111" => q <= "0111";	--352.8kHz
				when others => q <= "XXXX";
			end case;
		else
			case fcount is
				when "101111111" => q <= "0000";	--32kHz
				when "011111111" => q <= "0010";	--48kHz
				when "001111111" => q <= "0100";	--96kHz
				when "000111111" => q <= "0110";	--192kHz
				when "000011111" => q <= "1000";	--384kHz
				When others => q <= "XXXX";
			end case;
		end if;
	end if;
end process;

process(MCLK,q) begin
	if MCLK'event and MCLK='1' then
		if q="0000" then
			f <= "0000";
		elsif q="0001" then
			f <= "0001";
		elsif q="0010" then
			f <= "0010";
		elsif q="0011" then
			f <= "0011";
		elsif q="0100" then
			f <= "0100";
		elsif q="0101" then
			f <= "0101";
		elsif q="0110" then
			f <= "0110";
		elsif q="0111" then
			f <= "0111";
		elsif q="1000" then
			f <= "1000";
		else
			f <= f;
		end if;
	end if;
end process;

process(slrck) begin
	if slrck'event and slrck='0' then
		FS <= f;
	end if;
end process;

ov96k <= iov96k when XDSD = '1' else '1';

process(FS,iov96k) begin
	if FS > "0011" then
		iov96k <= '0';
	else
		iov96k <= '1';
	end if;
end process;

end RTL;
			
				