-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_signed.ALL;

entity rightShifter is port (
    input : in std_logic_vector(15 downto 0);
    output : out std_logic_vector(15 downto 0)
);
end entity rightShifter;

architecture imp of rightShifter is

begin
	output <= input(15) & input(15 downto 1);
end architecture imp;