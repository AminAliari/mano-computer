-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity computer is 

end entity;

architecture imp of computer is

-- componenets
component sayeh is port (
    clk : in std_logic;
    databusIn : in std_logic_vector(15 downto 0);
    databusOut : out std_logic_vector(15 downto 0);
    addressbus : out std_logic_vector (15 downto 0);
    readMem , writeMem : out std_logic;
    ExternalReset, MemdataReady : in std_logic
);
end component;

component memory is port (
	clk, readMem, writeMem : in std_logic;
	addressbus: in std_logic_vector (15 downto 0);
  databusIn : in std_logic_vector(15 downto 0);
  databusOut : out std_logic_vector(15 downto 0);
	MemdataReady : out std_logic
);
end component;

-- signals
signal readMem, writeMem, MemdataReady : std_logic;
signal databusIn, databusOut, addressbus : std_logic_vector(15 downto 0);
signal clk : std_logic;
signal ExternalReset : std_logic;

begin
  sayehComp : sayeh port map (clk, databusOut, databusIn, addressbus, readMem, writeMem, ExternalReset, MemdataReady);
  memoryComp : memory port map (clk, readMem, writeMem, addressbus, databusIn, databusOut, MemdataReady);

  clock: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process clock;

  test: process
    begin
    ExternalReset <= '1';
    wait for 10 ns;
    ExternalReset <= '0';
    readMem <= '1';
    wait;
  end process test;
end architecture;