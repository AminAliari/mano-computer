library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sanity_tb is
end entity;

architecture tb of sanity_tb is
  signal clk : std_logic := '0';

  -- comparator
  signal cmpA, cmpB : std_logic_vector(15 downto 0) := (others => '0');
  signal cmpC, cmpZ : std_logic;

  -- program counter
  signal pcEnable : std_logic := '0';
  signal pcIn, pcOut : std_logic_vector(15 downto 0) := (others => '0');

  -- flags
  signal aluC, aluZ : std_logic := '0';
  signal cset, zset, creset, zreset, flagLoad : std_logic := '0';
  signal flagC, flagZ : std_logic;

  -- register file
  signal rfInput, rfLeft, rfRight : std_logic_vector(15 downto 0) := (others => '0');
  signal rfWp : std_logic_vector(5 downto 0) := (others => '0');
  signal rfIndex : std_logic_vector(3 downto 0) := (others => '0');
  signal rfLw, rfHw : std_logic := '0';
begin
  clk <= not clk after 5 ns;

  cmp_i: entity work.comparator
    port map (
      a => cmpA,
      b => cmpB,
      c => cmpC,
      z => cmpZ
    );

  pc_i: entity work.ProgramCounter
    port map (
      EnablePC => pcEnable,
      input => pcIn,
      clk => clk,
      output => pcOut
    );

  flags_i: entity work.flags
    port map (
      cout => aluC,
      zout => aluZ,
      cset => cset,
      zset => zset,
      creset => creset,
      zreset => zreset,
      load => flagLoad,
      clk => clk,
      cin => flagC,
      zin => flagZ
    );

  rf_i: entity work.registerFile
    port map (
      input => rfInput,
      wp => rfWp,
      index => rfIndex,
      lw => rfLw,
      hw => rfHw,
      clk => clk,
      left => rfLeft,
      right => rfRight
    );

  stimulus: process
  begin
    -- comparator behavior
    cmpA <= x"0005"; cmpB <= x"0003"; wait for 1 ns;
    assert (cmpC = '1' and cmpZ = '0') report "Comparator failed for a>b" severity failure;

    cmpA <= x"0005"; cmpB <= x"0005"; wait for 1 ns;
    assert (cmpC = '0' and cmpZ = '1') report "Comparator failed for a=b" severity failure;

    cmpA <= x"0002"; cmpB <= x"0007"; wait for 1 ns;
    assert (cmpC = '0' and cmpZ = '0') report "Comparator failed for a<b" severity failure;

    -- flags default state
    wait for 1 ns;
    assert (flagC = '0' and flagZ = '0') report "Flags did not initialize to zero" severity failure;

    -- program counter should update only on rising edge when enabled
    pcEnable <= '0';
    pcIn <= x"0004";
    wait for 12 ns;
    assert pcOut /= x"0004" report "ProgramCounter updated while disabled" severity failure;

    pcEnable <= '1';
    pcIn <= x"0004";
    wait for 10 ns;
    assert pcOut = x"0004" report "ProgramCounter did not update on rising edge" severity failure;

    -- register file wrap-around write/read: WP=63 and left-index offset=1 -> index 0
    rfWp <= std_logic_vector(to_unsigned(63, 6));
    rfIndex <= "0100";
    rfInput <= x"00AA";
    rfLw <= '1';
    rfHw <= '1';
    wait for 10 ns;
    rfLw <= '0';
    rfHw <= '0';
    wait for 10 ns;
    assert rfLeft = x"00AA" report "RegisterFile wrap-around indexing failed" severity failure;

    report "sanity_tb passed" severity note;
    wait;
  end process;
end architecture;
