-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_signed.ALL;

entity instructionRegister is port (
    input : in std_logic_vector(15 downto 0);
    load, clk : in std_logic;
    output : out std_logic_vector(15 downto 0)
);
end entity instructionRegister;

architecture imp of instructionRegister is

-- singal 
signal temp : std_logic_vector(5 downto 0);

-- implementation
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        output <= input;
      end if;
    end if;
  end process;
end architecture imp;
