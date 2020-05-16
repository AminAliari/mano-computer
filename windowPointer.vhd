-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_signed.ALL;

entity windowPointer is port (
    input : in std_logic_vector(5 downto 0);
    add, reset, clk : in std_logic;
    output : out std_logic_vector(5 downto 0)
);
end entity windowPointer;

architecture imp of windowPointer is

-- implementation
begin
  process (clk)
  variable temp : std_logic_vector(5 downto 0) := "000000";
  begin
    if rising_edge(clk) then
      if reset = '1' then
        temp := "000000";
      elsif add = '1' then
        temp := temp + input;
      end if;
    end if;

    output <= temp;

  end process;
end architecture imp;
