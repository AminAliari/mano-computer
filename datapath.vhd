-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity datapath is port (
    -- alu
    bTo0, andOp, orOp, notOp, xorOp, compOp, addOp, subOp, cmpOp, shiftR, shiftL : in std_logic;
    
    -- IR
    irLoad : in std_logic;
    
    -- WP
    wpAdd, wpReset : in std_logic;

    -- flags
    cset, zset, creset, zreset, flagLoad : in std_logic;

    -- register file
     lw, hw, isFromMemory : in std_logic;

    -- address unit
    ResetPC, PCPlusI, PCPlus1, R0PlusI, R0plus0, EnablePC : in std_logic;

    -- datapath
    isRsOnAddressbus, isRdOnAddressbus : in std_logic;
    isAddressOnDatabus,isAluOnDatabus : in std_logic;
    cOut, zOut : out std_logic;
    isShadow, clk : in std_logic;
    databusIn : in std_logic_vector(15 downto 0);
    databusOut : out std_logic_vector(15 downto 0);
    instruction, addresbus : out std_logic_vector(15 downto 0)
);
end entity datapath;

architecture imp of datapath is

-- components
component alu is port (
    a, b : in std_logic_vector(15 downto 0);
    bTo0, andOp, orOp, notOp, xorOp, compOp, addOp, subOp, cmpOp, shiftR, shiftL : in std_logic;
    cin, zin : in std_logic;
    cout, zout : out std_logic;
    output : out std_logic_vector(15 downto 0)
);
end component;

component instructionRegister is port (
    input : in std_logic_vector(15 downto 0);
    load, clk : in std_logic;
    output : out std_logic_vector(15 downto 0)
);
end component;

component windowPointer is port (
    input : in std_logic_vector(5 downto 0);
    add, reset, clk : in std_logic;
    output : out std_logic_vector(5 downto 0)
);
end component;

component flags is port (
    cout, zout : in std_logic; -- from alu
    cset, zset, creset, zreset, load, clk : in std_logic;
    cin, zin : out std_logic
);
end component;

component registerFile is port (
    input : in std_logic_vector(15 downto 0);
    wp : in std_logic_vector(5 downto 0);
    index : in std_logic_vector(3 downto 0);
    lw, hw, clk : in std_logic;
    left, right : out std_logic_vector(15 downto 0)
);
end component;

component AddressUnit IS
  port (
    Rside : in std_logic_vector (15 downto 0);
    Iside : in std_logic_vector (7 downto 0);
    Address : out std_logic_vector (15 downto 0);
    clk, ResetPC, PCplusI, PCplus1 : in std_logic;
    RplusI, Rplus0, EnablePC : in std_logic
  );
end component;

-- signals

-- alu
signal aluCout, aluZout : std_logic;
signal aluOut : std_logic_vector(15 downto 0);

-- IR
signal irOut : std_logic_vector(15 downto 0);

-- WP
signal wpOut : std_logic_vector( 5 downto 0);

-- flags
signal fCin, fZin : std_logic;

-- register file
signal rfIndex : std_logic_vector(3 downto 0);
signal leftOut, rightOut : std_logic_vector(15 downto 0);

-- address unit
signal address, auRightBus: std_logic_vector(15 downto 0);
signal tempData : std_logic_vector(15 downto 0);

-- implementation
begin

  aluCmp : alu port map (leftOut, rightOut, bTo0, andOp, orOp, notOp, xorOp, compOp, addOp, subOp, cmpOp, shiftR, shiftL, fCin, fZin, aluCout, aluZout, aluOut);

  IR : instructionRegister port map (databusIn, irLoad, clk, irOut);
  instruction <= irOut(15 downto 0);

  WP : WindowPointer port map (irOut(5 downto 0), wpAdd, wpReset, clk, wpOut);

  flagsCmp : flags port map (aluCout, aluZout, cset, zset, creset, zreset, flagLoad, clk, fCin, fZin);

  cOut <= fCin; -- sends for controller
  zOut <= fZin; -- same here

  tempData <= databusIn when isFromMemory = '1' else aluOut;
  rfIndex <= irOut(3 downto 0) when isShadow = '1' else irOut(11 downto 8);
  registerFileCmp : registerFile port map (tempData, wpOut, rfIndex, lw, hw, clk, leftOut, rightOut);

  addressUnitCmp : AddressUnit port map (auRightBus, irOut(7 downto 0), address, clk, ResetPC, PCPlusI ,PCPlus1, R0PlusI, R0plus0, EnablePC);
  addresbus <= address;

  auRightBus <= leftOut when isRdOnAddressbus = '1' else rightOut when isRsOnAddressbus ='1' else "ZZZZZZZZZZZZZZZZ"; -- others: high impedance
  databusOut <= aluOut when isAluOnDatabus = '1' else address when isAddressOnDatabus = '1' else "ZZZZZZZZZZZZZZZZ"; -- same here

end architecture imp;
