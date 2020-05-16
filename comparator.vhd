-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_signed.ALL;

entity comparator is port (
    a, b : in std_logic_vector(15 downto 0);
    c : out std_logic;
    z : out std_logic
);
end entity comparator;

architecture imp of comparator is

begin
  c <= '1' when a > b else '0';
  z <= '0' when a > b else '1';
end architecture imp;
