-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_signed.ALL;

entity flags is port (
    cout, zout : in std_logic; -- from alu
    cset, zset, creset, zreset, load, clk : in std_logic;
    cin, zin : out std_logic
);
end entity flags;

architecture imp of flags is

-- implementation
begin
  process (clk)
  variable temp : std_logic_vector(5 downto 0) := "000000";
  begin
    if rising_edge(clk) then
      if load = '1' then
        cin <= cout;
        zin <= zout;
      else
        if creset = '1' then
          cin <= '0';
        elsif cset = '1' then
          cin <= '1';
        end if;

        if zreset = '1' then
          zin <= '0';
        elsif zset = '1' then
          zin <= '1';
        end if;
      end if;
    end if;
  end process;
end architecture imp;
