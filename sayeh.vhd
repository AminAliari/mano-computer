-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity sayeh is port (
    clk: in std_logic;
    databusIn : in std_logic_vector(15 downto 0);
    databusOut : out std_logic_vector(15 downto 0);
    addressbus: out std_logic_vector (15 downto 0);
    readMem , writeMem : out std_logic;
    ExternalReset, MemdataReady : in std_logic
);
end entity sayeh;

architecture imp of sayeh is
  
-- components
component datapath is port (
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
    isAddressOnDatabus, isAluOnDatabus : in std_logic;
    cOut, zOut : out std_logic;
    isShadow, clk : in std_logic;
    databusIn : in std_logic_vector(15 downto 0);
    databusOut : out std_logic_vector(15 downto 0);
    instruction, addresbus : out std_logic_vector(15 downto 0)
);
end component;

component controller is port(
      -- alu
  bTo0, andOp, orOp, notOp, xorOp, compOp, addOp, subOp, cmpOp, shiftR, shiftL : out std_logic;
  
  -- IR
  irLoad : out std_logic;
  
  -- WP
  wpAdd, wpReset : out std_logic;

  -- flags
  cset, zset, creset, zreset, flagLoad : out std_logic;

  -- register file
  lw, hw, isFromMemory : out std_logic;

  -- address unit
  ResetPC, PCPlusI, PCPlus1, R0PlusI, R0plus0, EnablePC : out std_logic;

  -- controller

  isRsOnAddressbus, isRdOnAddressbus : out std_logic;
  isAddressOnDatabus, isAluOnDatabus : out std_logic;
  cOut, zOut : in std_logic;
  isShadow : out std_logic;
  ExternalReset, MemDataReady, clk : in std_logic;
  instruction : in std_logic_vector(15 downto 0);
  readMem, writeMem : out std_logic
);
end component;


--singals

-- alu
signal bTo0, andOp, orOp, notOp, xorOp, compOp, addOp, subOp, cmpOp, shiftR, shiftL : std_logic;

-- IR
signal irLoad : std_logic;

-- WP
signal wpAdd, wpReset : std_logic;

-- flags
signal cset, zset, creset, zreset, flagLoad : std_logic;

-- register file
signal lw, hw, isFromMemory : std_logic;

-- address unit
signal ResetPC, PCPlusI, PCPlus1, R0PlusI, R0plus0, EnablePC : std_logic;

-- datapath
signal isRsOnAddressbus, isRdOnAddressbus : std_logic;
signal isAddressOnDatabus,isAluOnDatabus : std_logic;
signal cOut, zOut : std_logic;
signal isShadow : std_logic;
signal instruction : std_logic_vector(15 downto 0);
-- implementation
begin

  datapathCmp : datapath port map (
     -- alu
    bTo0, andOp, orOp, notOp, xorOp, compOp, addOp, subOp, cmpOp, shiftR, shiftL,

    -- IR
    irLoad,

    -- WP
    wpAdd, wpReset,

    -- flags
    cset, zset, creset, zreset, flagLoad,

    -- register file
     lw, hw, isFromMemory,

    -- address unit
    ResetPC, PCPlusI, PCPlus1, R0PlusI, R0plus0, EnablePC,

    -- datapath
    isRsOnAddressbus, isRdOnAddressbus,
    isAddressOnDatabus,isAluOnDatabus,
    cOut, zOut,
    isShadow, clk,
    databusIn,
    databusOut,
    instruction, addressbus
  );

  controllerCmp : controller port map (
        -- alu
    bTo0, andOp, orOp, notOp, xorOp, compOp, addOp, subOp, cmpOp, shiftR, shiftL,
    
    -- IR
    irLoad,
    
    -- WP
    wpAdd, wpReset,

    -- flags
    cset, zset, creset, zreset, flagLoad,

    -- register file
     lw, hw, isFromMemory,

    -- address unit
    ResetPC, PCPlusI, PCPlus1, R0PlusI, R0plus0, EnablePC,

    -- controller

    isRsOnAddressbus, isRdOnAddressbus,
    isAddressOnDatabus, isAluOnDatabus,
    cOut, zOut,
    isShadow, ExternalReset, MemDataReady, clk,
    instruction,readMem,writeMem
  );
end architecture;