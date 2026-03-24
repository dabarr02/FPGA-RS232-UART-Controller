-------------------------------------------------------------------
--
--  Fichero:
--    rs232reciverFSM.vhd  13/3/2026
--
--  
--    Diseño Automatico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Prop�sito:
--    Unidad de controls para rs232transmitter.vhd
--
--  Notas de dise�o:
--    - Parity: NONE
--    - Num data bits: 8
--    - Num stop bits: 1
--
-------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity fifoDP is
  port (
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    controlIn: in std_logic_vector(8 downto 0); -- señales que se reciben del FSM
    controlOut: out std_logic_vector(3 downto 0); -- señales que se envian al FSM
    ----Salidas del datapath:
    dataOut: out std_logic_vector(7 downto 0); -- datos que salen de la FIFO
    numData: out std_logic_vector(4 downto 0); -- numero de elementos en la FIFO
    full: out std_logic; -- señal que indica si la FIFO está llena
    empty: out std_logic; -- señal que indica si la FIFO está vacía

    -----Entradas del datapath:
    dataIn: in std_logic_vector(7 downto 0) -- datos que entran a la FIFO
    );
end fifoDP;

--------------------------------------------------------------------
use work.common.all;
architecture rtl  of fifoDP is
    -----BRAM componente-----
    COMPONENT BRAM_FIFO
    PORT (
        clka : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        clkb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
    );
    END COMPONENT;

    component RAM_REG is
    port (
        clka  : in  std_logic;
        wea   : in  std_logic_vector(0 downto 0);
        addra : in  std_logic_vector(3 downto 0);
        dina  : in  std_logic_vector(7 downto 0);
        clkb  : in  std_logic; 
        addrb : in  std_logic_vector(3 downto 0);
        doutb : out std_logic_vector(7 downto 0)
    );
  end component;


    signal controlIn_aux : std_logic_vector(8 downto 0);
    signal controlOut_aux : std_logic_vector(3 downto 0);
    ----------Alias para controlOut----------
    alias nextWrtEq: std_logic is controlOut_aux(0);
    alias nextRdEq: std_logic is controlOut_aux(1);
    alias isEmpty: std_logic is controlOut_aux(2);
    alias isFull: std_logic is controlOut_aux(3);

    ----------Alias para controlIn----------
    alias incWrPtr: std_logic is controlIn_aux(0);
    alias incRdPtr: std_logic is controlIn_aux(1);
    alias wrEn: std_logic is controlIn_aux(2);
    alias emptySet: std_logic is controlIn_aux(3);
    alias emptyClr: std_logic is controlIn_aux(4);
    alias fullSet: std_logic is controlIn_aux(5);
    alias fullClr: std_logic is controlIn_aux(6);
    alias countInc: std_logic is controlIn_aux(7);
    alias countDec: std_logic is controlIn_aux(8);

    -----Registros para los punteros de lectura y escritura-----
    signal wrPtr: unsigned(3 downto 0) := (others => '0');
    signal rdPtr: unsigned(3 downto 0) := (others => '0');
    signal elemsReg: unsigned(4 downto 0) := (others => '0'); -- registro para almacenar el numero de elementos en la FIFO
    signal fullReg: std_logic := '0'; -- registro para almacenar el estado de lleno de la FIFO
    signal emptyReg: std_logic := '1'; -- registro para almacenar el estado de vacio de la FIFO
    signal nextwrPtr: unsigned(3 downto 0);
    signal nextrdPtr: unsigned(3 downto 0);
    signal wrea: std_logic_vector(0 downto 0);

begin
    controlIn_aux <= controlIn;
    controlOut <= controlOut_aux;
    wrea(0) <= wrEn;    
----------Numero de elementos-----------------------------
    elementCounter: process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                elemsReg <= (others => '0');
            else
                if countInc = '1' then
                    elemsReg <= elemsReg + 1;
                elsif countDec = '1' then
                    elemsReg <= elemsReg - 1;
                end if;
            end if;
        end if;
    end process elementCounter;
    numData <= std_logic_vector(elemsReg);
----Registros de punteros---------------------------
    PunteroWRT:process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                wrPtr <= (others => '0');
            else
                if(incWrPtr = '1') then
                   wrPtr <= nextwrPtr;
                end if;
            end if;
        end if;
    end process PunteroWRT;

    PunteroRDT:process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rdPtr <= (others => '0');
            else
                if(incRdPtr = '1') then
                   rdPtr <= nextrdPtr;
                end if;
            end if;
        end if;
    end process PunteroRDT;

   
        nextwrPtr <= wrPtr + 1 when wrPtr /= "1111" else (others => '0');
        nextrdPtr <= rdPtr + 1 when rdPtr /= "1111" else (others => '0');
        nextWrtEq <= '1' when (nextwrPtr = rdPtr) else '0';
        nextRdEq <= '1' when (nextrdPtr = wrPtr) else '0';

-------------------------------------------------------------------------------------

-------------------FLAGS DE LLENO Y VACIO--------------------------------------------
    fullFlag: process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fullReg <= '0';
            else
                if fullSet = '1' then
                    fullReg <= '1';
                elsif fullClr = '1' then
                    fullReg <= '0';
                end if;
            end if;
        end if;
    end process fullFlag;

    emptyFlag: process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                emptyReg <= '1';
            else
                if emptySet = '1' then
                    emptyReg <= '1';
                elsif emptyClr = '1' then
                    emptyReg <= '0';
                end if;
            end if;
        end if;
    end process emptyFlag;
    full <= fullReg;
    empty <= emptyReg;
    isEmpty <= emptyReg;
    isFull <= fullReg;
--------------------------------------------------------------------------------------

--------------------Instancia de la BRAM---------------------------------------------
    BRAM_inst: BRAM_FIFO
        port map (
            clka => clk,
            wea => wrea,
            addra => std_logic_vector(wrPtr),
            dina => dataIn,
            clkb => clk,
            addrb => std_logic_vector(rdPtr),
            doutb => dataOut
        );
--------------------------------------------------------------------------------------
end rtl;
 