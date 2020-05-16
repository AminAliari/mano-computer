-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_signed.ALL;

entity leftShifter is port (
    input : in std_logic_vector(15 downto 0);
    output : out std_logic_vector(15 downto 0)
);
end entity leftShifter;

architecture imp of leftShifter is

begin
	output <= input(14 downto 0)  & '0';
end architecture imp;