-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_signed.ALL;

entity twoComplement is port (
    a : in std_logic_vector(15 downto 0);
    output : out std_logic_vector(15 downto 0)
);
end entity twoComplement;

architecture imp of twoComplement is

begin
	output <= (not a) + '1';
end architecture imp;
