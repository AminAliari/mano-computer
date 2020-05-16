-- Amin Aliari - 9431066

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity controller is port(
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
end entity controller;

architecture imp of controller is



-- signals
signal currentState,nextState : std_logic_vector ( 3 downto 0);
signal shadow, update : std_logic;

-- constants

-- states
constant reset : std_logic_vector (3 downto 0) := "0000"; -- resting cycle
constant fetch : std_logic_vector (3 downto 0) := "0001"; -- reading memory instruction
constant execute : std_logic_vector (3 downto 0) := "0010"; -- executes IR
constant executeShadow : std_logic_vector (3 downto 0) := "0011"; -- executes shadow part of IR
constant readLoop : std_logic_vector (3 downto 0) := "0100"; -- checks if IR is read
constant readLoopReady : std_logic_vector (3 downto 0) := "0101"; -- checks if IR is read
constant executeWriteRF : std_logic_vector (3 downto 0) := "0110"; -- writes databus on Register File
constant executeWriteRFWithoutInc : std_logic_vector (3 downto 0) := "0111"; -- writes databus on Register File without incerementing PC
constant executeWriteRFWithoutShadow: std_logic_vector (3 downto 0) := "1000"; -- writes databus on Register File without checking for shodow type 
constant incerementPC : std_logic_vector (3 downto 0) := "1001"; -- incerements PC

-- operations
constant nop : std_logic_vector (3 downto 0):=  "0000"; -- no operation
constant hlt : std_logic_vector (3 downto 0):=  "0001"; -- halt
constant szf : std_logic_vector (3 downto 0):=  "0010"; -- set zero flag
constant czf : std_logic_vector (3 downto 0):=  "0011"; -- clear zero flag
constant scf : std_logic_vector (3 downto 0):=  "0100"; -- set carry flag
constant ccf : std_logic_vector (3 downto 0):=  "0101"; -- clear carry flag
constant cwp : std_logic_vector (3 downto 0):=  "0110"; -- claer window pointer
constant mvr : std_logic_vector (3 downto 0):=  "0001"; -- Rd <= Rs
constant lda : std_logic_vector (3 downto 0):=  "0010"; -- Rd <= Mem(Rs)
constant sta : std_logic_vector (3 downto 0):=  "0011"; -- Mem(Rd) <= Rs
constant myXor : std_logic_vector (3 downto 0):=  "0100"; -- Rd <= Rd xor Rs
constant tcm : std_logic_vector (3 downto 0):=  "0101"; -- Rd <= two's complement of Rd
constant myAnd : std_logic_vector (3 downto 0):= "0110"; -- Rd <= Rd and Rs
constant myOr : std_logic_vector (3 downto 0):=  "0111"; -- Rd <= Rd or Rs
constant myNot : std_logic_vector (3 downto 0):= "1000"; -- Rd <= ~Rs
constant shl : std_logic_vector (3 downto 0):=  "1001"; -- Rd <= shift left Rs
constant shr : std_logic_vector (3 downto 0):=  "1010"; -- Rd <= shift right Rs
constant add : std_logic_vector (3 downto 0):=  "1011"; -- Rd <= Rd + Rs
constant sub : std_logic_vector (3 downto 0):=  "1100"; -- Rd <= Rd - Rs
constant cmp : std_logic_vector (3 downto 0):=  "1110"; -- set c and z based on Rd < Rs
constant mil : std_logic_vector (1 downto 0):=  "00"; -- Rdl <= {8'bZ,I}
constant mih : std_logic_vector (1 downto 0):=  "01"; -- Rdh <= {I,8'bZ}
constant spc : std_logic_vector (1 downto 0):=  "10"; -- Rd <= PC + 1
constant jpa : std_logic_vector (1 downto 0):=  "11"; -- PC <= Rd + I
constant jpr : std_logic_vector (3 downto 0):=  "0111"; -- PC <= PC + 1
constant brz : std_logic_vector (3 downto 0):=  "1000"; -- if (z) same here
constant brc : std_logic_vector (3 downto 0):=  "1001"; -- if (c) same here
constant awp : std_logic_vector (3 downto 0):=  "1010"; -- WP <= WP + I

-- implementation
begin

process (ExternalReset, clk)
begin
  if ExternalReset = '1' then -- 'U' for booting up the controller
    currentState <= reset;
  elsif rising_edge(clk) then
    currentState <= nextState;
  end if;
end process;

-- cheking if the IR contains a shadow instruction type (NOT-cases: 1111-whatever..., 0000-X where x has to be more than 6)
shadow <= '0' when (instruction(15 downto 12) = "0000" and instruction(11 downto 8) > "0110") else '0' when instruction(15 downto 12) = "1111" else '1';


process (currentState, update)
begin

-- reseting flags [
  -- alu
  andOp <= '0';
  orOp <= '0';
  notOp <= '0';
  xorOp <= '0';
  compOp <= '0';
  addOp <= '0';
  subOp <= '0';
  cmpOp <= '0';
  shiftR <= '0';
  shiftL <= '0';

  -- WP
  wpAdd <= '0';
  wpReset <= '0';

  -- flags
  cset <= '0';
  zset <= '0';
  creset <= '0';
  zreset <= '0';
  flagLoad <= '0';

  -- register file
  lw <= '0';
  hw <= '0';

  -- address unit
  ResetPC <= '0';
  PCPlusI <= '0';
  PCPlus1 <= '0';
  R0PlusI <= '0';
  R0plus0 <= '0';
  EnablePC <= '0';

  -- controller
  isRsOnAddressbus <= '0';
  isRdOnAddressbus <= '0';
  isAddressOnDatabus <= '0';
  isAluOnDatabus <= '0';
  writeMem <= '0';
-- ]

-- [ main process

  case (currentState) is
    when reset =>
      report "[amin]: reset";
      WPReset <= '1';                
      ResetPC <= '1';
      EnablePC <= '1';
      nextState <= fetch;

    when fetch =>
      report "[amin]: fetch";
      irLoad <= '1';
      readMem <= '1';
      writeMem <= '0';
      isFromMemory <= '0';
      nextState <= readLoop;

    when readLoop =>
      report "[amin]: read loop";
      if MemDataReady = '1' then
        nextState <= readLoopReady;
      else
        nextState <= readLoop;
        if update = 'U' then
          update <= '0';
        elsif update = '0' then
          update <= '1';
        else
          update <= '0';
        end if;
      end if;

    when readLoopReady =>      
      readMem <= '0';
      irLoad <= '0';
      nextState <= execute;
    
    when execute =>
      report "[amin]: execute";
       if shadow = '1' then
        isShadow <='1';
      else
        isShadow <= '0';
      end if;
      case(instruction(15 downto 12)) is
        when "0000" =>
          case(instruction(11 downto 8)) is
            when nop =>
              report "[amin]: execute NOP";
              if shadow = '1' then
                nextState <= executeShadow;
              else
                -- incerement pc and go to next state of sayeh
                PCPlus1 <= '1';
                EnablePC <= '1';
                nextState <= fetch;
              end if;

            when hlt => 
              report "[amin]: execute halt";
              -- [end here]

            when szf =>
              report "[amin]: execute set zero flag";
              zset <= '1';
              if shadow = '1' then
                nextState <= executeShadow;
              else
                PCPlus1 <= '1';
                EnablePC <= '1';
                nextState <= fetch;
              end if;
              
            when czf =>
              report "[amin]: execute clear zero flag";
              zreset <= '1';
              if shadow = '1' then
                nextState <= executeShadow;
              else
                PCPlus1 <= '1';
                EnablePC <= '1';
                nextState <= fetch;
              end if;

            when scf =>
              report "[amin]: execute set carry flag";
              cset <= '1';
              if shadow = '1' then
                nextState <= executeShadow;
              else
                PCPlus1 <= '1';
                EnablePC <= '1';
                nextState <= fetch;
              end if;

            when ccf =>
              report "[amin]: execute clear carry flag";
              creset <= '1';
              if shadow = '1' then
                nextState <= executeShadow;
              else
                PCPlus1<= '1';
                EnablePC<= '1';
                nextState <= fetch;
              end if;

            when cwp =>
              report "[amin]: execute clear window pointer";
              wpReset <= '1';
              if shadow = '1' then
                nextState <= executeShadow;
              else
                PCPlus1 <= '1';
                EnablePC <= '1';
                nextState <= fetch;
              end if;

            when jpr =>
              report "[amin]: execute jump relative (PC = PC + I)";
              PCPlusI <= '1';
              EnablePC <= '1';
              nextState <= fetch;

            when brz =>
              report "[amin]: execute branch if zero (z == 1)";
              if zOut = '1' then
                PCPlusI <= '1';
                EnablePC <= '1';
              end if;
              nextState <= fetch;

            when brc =>
              report "[amin]: execute branch if carry (c == 1)";
              if cOut = '1' then
                PCPlusI <= '1';
                EnablePC <= '1';
              end if;
              nextState <= fetch;

            when awp =>
              report "[amin]: execute add window pointer (WP = WP + I)";
              wpAdd <= '1';
              if shadow = '1' then
                nextState <= executeShadow;
              else
                PCPlus1 <= '1';
                EnablePC <= '1';
                nextState <= fetch;
              end if;
            when others =>
              report "[amin]: execute others first case";
          end case;
          
        when mvr =>
          report "[amin]: execute mvr (Rd = Rs)";
          bTo0 <= '1';
          readMem <= '0';
          lw <= '1';
          hw <= '1';

          if shadow = '1' then
            nextState <= executeShadow;
          else
            PCPlus1 <= '1';
            EnablePC <= '1';
            nextState <= fetch;
          end if;

        when lda =>
          report "[amin]: execute load addressed (Rd = Mem(Rs))";
          isRsOnAddressbus <= '1';
          R0plus0 <= '1';
          readMem <= '1';
          isFromMemory <= '1';
          nextState <= executeWriteRF;

        when sta =>
          report "[amin]: execute store addressed (Mem(Rd) <= Rs))";
          bTo0 <= '1';
          isRdOnAddressbus <= '1';
          R0PlusI <= '1';
          isAluOnDatabus <= '1';
          readMem <= '0';
          writeMem <= '1';
          if shadow = '1' then
            nextState <= executeShadow;
          else
            PCPlus1 <= '1';
            EnablePC <= '1';
            nextState <= fetch;
          end if;

        when myAnd =>
          report "[amin]: execute and";
          andOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when myOr =>
          report "[amin]: execute or";
          orOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when myNot =>
          report "[amin]: execute not";
          notOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when myXor =>
          report "[amin]: execute xor";
          xorOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when tcm =>
          report "[amin]: execute two complement";
          compOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when shl =>
          report "[amin]: execute shift left";
          shiftL <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when shr =>
          report "[amin]: execute shift right";
          shiftR <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when add =>
          report "[amin]: execute add";
          addOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when sub =>
          report "[amin]: execute sub";
          subOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when cmp =>
          report "[amin]: execute compare";
          cmpOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRF;

        when "1111" =>
          case(instruction(9 downto 8)) is
            when mil =>
              report "[amin]: execute move I low (Rdl = I)";
              isFromMemory <= '1';
              lw <= '1';
              EnablePC <= '1';
              PCPlus1 <= '1';
              nextState <= fetch;

            when mih =>
              report "[amin]: execute move I high (Rdh = I)";
              isFromMemory <= '1';
              EnablePC <= '1';
              hw <= '1';
              PCPlus1 <= '1';
              nextState <= fetch;

            when spc =>
              report "[amin]: execute save PC";
              readMem<= '0';              
              PCPlusI <= '1';
              isAddressOnDatabus <= '1';
              nextState <= executeWriteRFWithoutInc;
            when jpa =>
              report "[amin]: execute jump addressed (PC = Rd + I)";
              isRdOnAddressbus <= '1';
              R0PlusI <= '1';
              EnablePC <= '1';
              nextState <= fetch;
            when others =>
              report "[amin]: execute second case";  
          end case;  
          when others =>  
            report "[amin]: execute others";   
      end case;

     when executeShadow =>
      report "[amin]: executeShadow";
      --isShadow <= '1';
      case(instruction(7 downto 4)) is
        when "0000" =>
          case(instruction(3 downto 0)) is
            when nop =>
              report "[amin]: execute [shadow] NOP";
              PCPlus1 <= '1';
              EnablePC <= '1';
              nextState <= fetch;

            when hlt =>
              report "[amin]: execute [shadow] halt";
              -- [end here]

            when szf =>
              report "[amin]: execute [shadow] set zero flag";
              zset <= '1';
              PCPlus1 <= '1';
              EnablePC <= '1';
              nextState <= fetch;
            
            when czf =>
              report "[amin]: execute [shadow] clear zero flag";
              zreset <= '1';
              PCPlus1 <= '1';
              EnablePC <= '1';
              nextState <= fetch;

            when scf =>
              report "[amin]: execute [shadow] set carry flag";
              cset <= '1';
              PCPlus1 <= '1';
              EnablePC <= '1';
              nextState <= fetch;

            when ccf =>
              report "[amin]: execute [shadow] clear carry flag";
              creset <= '1';
              PCPlus1 <= '1';
              EnablePC <= '1';
              nextState <= fetch;

            when cwp =>
              report "[amin]: execute [shadow] clear window pointer";
              wpReset <= '1';
              PCPlus1 <= '1';
              EnablePC <= '1';
              nextState <= fetch;

            when awp =>
              report "[amin]: execute [shadow] add window pointer (WP = WP + I)";
              wpAdd <= '1';
              PCPlus1 <= '1';
              EnablePC <= '1';
              nextState <= fetch;
            when others =>
              report "[amin]: execute [shadow] others first case";
          end case;
          
        when mvr =>
          report "[amin]: execute [shadow] mvr (Rd = Rs)";
          bTo0 <= '1';
          readMem <= '0';
          lw <= '1';
          hw <= '1';

          PCPlus1 <= '1';
          EnablePC <= '1';
          nextState <= fetch;

        when lda =>
          report "[amin]: execute [shadow] load addressed (Rd = Mem(Rs))";
          isRsOnAddressbus <= '1';
          R0plus0 <= '1';
          readMem <= '1';
          isFromMemory <= '1';
          nextState <= executeWriteRFWithoutShadow;

        when sta =>
          report "[amin]: execute store addressed (Mem(Rd) <= Rs))";
          bTo0 <= '1';
          isRdOnAddressbus <= '1';
          R0PlusI <= '1';
          isAluOnDatabus <= '1';
          readMem <= '0';
          writeMem <= '1';
          PCPlus1 <= '1';
          EnablePC <= '1';
          nextState <= fetch;

        when myAnd =>
          report "[amin]: execute [shadow] and";
          andOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when myOr =>
          report "[amin]: execute [shadow] or";
          orOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when myNot =>
          report "[amin]: execute [shadow] not";
          notOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when myXor =>
          report "[amin]: execute [shadow] xor";
          xorOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when tcm =>
          report "[amin]: execute [shadow] two complement";
          compOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when shl =>
          report "[amin]: execute [shadow] shift left";
          shiftL <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when shr =>
          report "[amin]: execute [shadow] shift right";
          shiftR <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when add =>
          report "[amin]: execute [shadow] add";
          addOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when sub =>
          report "[amin]: execute [shadow] sub";
          subOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;

        when cmp =>
          report "[amin]: execute [shadow] compare";
          cmpOp <= '1';
          readMem <= '0';
          nextState <= executeWriteRFWithoutShadow;   
        when others =>
          report "[amin]: execute [shadow] others second case";
      end case;

    when executeWriteRF =>
      report "[amin]: execute write to RF";
      lw <= '1';
      hw <= '1';
      if shadow = '1' then
        nextState <= executeShadow;
      else
        PCPlus1 <= '1';
        EnablePC <= '1';
        nextState <= fetch;
      end if;

    when executeWriteRFWithoutShadow =>
      report "[amin]: execute write to RF without shadow";
      lw <= '1';
      hw <= '1';
      PCPlus1 <= '1';
      EnablePC <= '1';
      nextState <= fetch;

    when executeWriteRFWithoutInc =>
      report "[amin]: execute write to RF without incerement";
      lw <= '1';
      hw <= '1';
      nextState <= incerementPC;

    when incerementPC =>
      report "[amin]: incerement PC";
      PCPlus1 <= '1';
      EnablePC <= '1';

      if shadow = '1' then
        nextState <= executeShadow;
      else
        nextState <= fetch;
      end if;
    when others =>
      report "[amin]: others state";
  end case;

-- ]
end process;
end architecture imp;
