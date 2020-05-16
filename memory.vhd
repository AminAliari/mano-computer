library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity memory is
	generic (blocksize : integer := 1024);

	port (clk, readmem, writemem : in std_logic;
		addressbus: in std_logic_vector (15 downto 0);
    databusIn : in std_logic_vector(15 downto 0);
    databusOut : out std_logic_vector(15 downto 0);
		databus : inout std_logic_vector (15 downto 0);
		memdataready : out std_logic);
end entity memory;

architecture behavioral of memory is
	type mem is array (0 to blocksize - 1) of std_logic_vector (15 downto 0);
begin
	process (clk)
		variable buffermem : mem := (others => (others => '0'));
		variable ad : integer;
		variable init : boolean := true;
	begin
		if init = true then
			-- notes:
			-- test with 10ns steps.
			-- this set of instructions will add r0 and r1 then saves it to r0. 1 + 2 = 3 -> r(0)
			
			-- clear wp
			buffermem(0) := "0000000000000110";

			-- mil r0
			buffermem(1) := "1111000000000001";

			-- mih r0
			buffermem(2) := "1111000100000000";

			-- jump pc to 9 (pc = rd + I)
			-- buffermem(3) := "1111001100001000";
			-- 
			-- mil r1
			buffermem(3) := "1111010000010000";
			-- mih r1
			buffermem(4) := "1111010100000000";

			-- mih r1 with different value
			-- buffermem(7) := "1111010100011111";
			-- 
			-- add r1, r0
			buffermem(5) := "1011010000000000";
			init := false;
		end if;

		if  clk'event and clk = '1' then
			ad := to_integer(unsigned(addressbus));

			if readmem = '1' then
				memdataready <= '1';
				if ad >= blocksize then
					databusOut <= (others => 'Z');
				else
					databusOut <= buffermem(ad);
				end if;
			elsif writemem = '1' then
				memdataready <= '1';
				if ad < blocksize then
					buffermem(ad) := databusIn;
				end if;
			end if;
		end if;
	end process;
end architecture behavioral;
