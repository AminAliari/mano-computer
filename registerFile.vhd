-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity registerFile is port (
    input : in std_logic_vector(15 downto 0);
    wp : in std_logic_vector(5 downto 0);
    index : in std_logic_vector(3 downto 0);
    lw, hw, clk : in std_logic;
    left, right : out std_logic_vector(15 downto 0)
);
end entity registerFile;

architecture imp of registerFile is

-- signals
type signalArray is array (63 downto 0) of std_logic_vector(15 downto 0);
signal regs : signalArray;

-- implementation
begin
  process (clk)
  variable lindex, rindex : integer := 0;
  begin
      lindex := to_integer(unsigned(index(3 downto 2))) + to_integer(unsigned(wp(5 downto 0)));
      rindex := to_integer(unsigned(index(1 downto 0))) + to_integer(unsigned(wp(5 downto 0)));

    if rising_edge(clk) then
      if lw = '1' and hw = '0' then
        regs(lindex)(7 downto 0) <= input(7 downto 0);
      end if;
        
      if hw = '1' and lw = '0' then
        regs(lindex)(15 downto 8) <= input(7 downto 0);
      end if;

      if lw = '1' and hw = '1' then
        regs(lindex)(15 downto 0) <= input(15 downto 0);
      end if;

      left <= regs(lindex);
      right <= regs(rindex);
    end if;
  end process;
end architecture imp;
