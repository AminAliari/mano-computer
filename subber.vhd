-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_signed.ALL;

entity subber is port (
    a, b : in std_logic_vector(15 downto 0);
    cin  : in std_logic;
    output : out std_logic_vector(15 downto 0);
    cout : out std_logic
);
end entity subber;

architecture imp of subber is
    signal temp : std_logic_vector(16 downto 0);
    signal tempCin : std_logic;
begin
	tempCin <= '0' when cin = 'U' else cin;
  temp <= (a(15) & a) - (b(15) & b) - tempCin; -- to handle negative numbers
  output <= temp(15 downto 0);
  cout   <= temp(16);
end architecture imp;
