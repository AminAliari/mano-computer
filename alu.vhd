-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity alu is port (
    a, b : in std_logic_vector(15 downto 0);
    bTo0, andOp, orOp, notOp, xorOp, compOp, addOp, subOp, cmpOp, shiftR, shiftL : in std_logic;
    cin, zin : in std_logic;
    cout, zout : out std_logic;
    output : out std_logic_vector(15 downto 0)
);
end entity alu;

architecture imp of alu is

-- components
component twoComplement is port (
    a : in std_logic_vector(15 downto 0);
    output : out std_logic_vector(15 downto 0)
);
end component;

component adder is port (
    a, b : in std_logic_vector(15 downto 0);
    cin  : in std_logic;
    output : out std_logic_vector(15 downto 0);
    cout : out std_logic
);
end component;

component subber is port (
    a, b : in std_logic_vector(15 downto 0);
    cin  : in std_logic;
    output : out std_logic_vector(15 downto 0);
    cout : out std_logic
);
end component;

component comparator is port (
    a, b : in std_logic_vector(15 downto 0);
    c : out std_logic;
    z : out std_logic
);
end component;

component rightShifter is port (
    input : in std_logic_vector(15 downto 0);
    output : out std_logic_vector(15 downto 0)
);
end component;

component leftShifter is port (
    input : in std_logic_vector(15 downto 0);
    output : out std_logic_vector(15 downto 0)
);
end component;

-- signals
type signalArray is array (7 downto 0) of std_logic_vector(15 downto 0);

signal outs : signalArray; -- outputs
signal cs : std_logic_vector(2 downto 0);
signal tempZ : std_logic;

-- implementation
begin
  
  outs(0) <= a and b;
  outs(1) <= a or b;
  outs(2) <= a xor b;

  compInstance: twoComplement port map(a, outs(3));
  adderInstance: adder port map(a, b, cin, outs(4), cs(0));
  subberInstance: subber port map(a, b, cin, outs(5), cs(1));
  rightShiftInstance: rightShifter port map(b, outs(6));
  leftShiftInstance: leftShifter port map(b, outs(7));
  compareInstance: comparator port map(a, b, cs(2), tempZ);

  output <= outs(0) when andOp = '1' else outs(1) when orOp = '1' else outs(2) when xorOp = '1' else outs(3) when compOp = '1' else 
            outs(4) when addOp = '1' else outs(5) when subOp = '1' else outs(6) when shiftR = '1' else outs(7) when shiftL = '1' else b when bTo0 = '1';
  cout <= cs(0) when addOp = '1' else cs(1) when subOp = '1' else cs(2) when cmpOp = '1' else cin;
  zout <= tempZ when cmpOp = '1' else zin;

end architecture imp;
