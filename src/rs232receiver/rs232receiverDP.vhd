-------------------------------------------------------------------
--
--  Fichero:
--    rs232transFSM.vhd  13/3/2026
--
--  
--    Diseño Automatico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Prop�sito:
--    DataPath para rs232transmitter.vhd
--
--  Notas de diseño:
--    - Parity: NONE
--    - Num data bits: 8
--    - Num stop bits: 1
--
-------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
entity rs232receiverDP is
    generic (
        FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
        BAUDRATE : natural   -- velocidad de comunicacion
    );
    port (
        -- host side
        clk     : in  std_logic;   -- reloj del sistema
        rst     : in  std_logic;   -- reset s�ncrono del sistema
        controlIn: in std_logic_vector(2 downto 0); -- señales que se reciben del FSM
        controlOut: out std_logic_vector(4 downto 0); -- señales que se envian al FSM
        data    : out  std_logic_vector (7 downto 0);   -- dato a recibir
        RxD     : in std_logic    -- entrada de datos serie del interfaz RS-232
    );
end rs232receiverDP;
-------------------------------------------------------------------
use work.common.all;
architecture rtl of rs232receiverDP is
    signal controlIn_aux : std_logic_vector(2 downto 0);
    signal controlOut_aux : std_logic_vector(4 downto 0);
    alias baudCntCE : std_logic is controlIn_aux(0);
    alias bitPosCE : std_logic is controlIn_aux(1);
    alias shiftRx : std_logic is controlIn_aux(2);
    alias readRx : std_logic is controlOut_aux(0);
    alias posCounter: std_logic_vector(3 downto 0) is controlOut_aux(4 downto 1);
    constant CYCLES : natural := (FREQ_KHZ*1000)/BAUDRATE;
    signal countBaud  : natural range 0 to CYCLES-1 := 0;
    signal bitCounter : unsigned(3 downto 0) := (others => '0');
    signal shifterReg : std_logic_vector(9 downto 0) := (others => '0');
    signal RxDSync : std_logic;
begin
    controlIn_aux <= controlIn;
    controlOut <= controlOut_aux;

    rxDSynchronizer : synchronizer
        generic map ( STAGES => 2, XPOL => '1' )
        port map ( clk => clk,rst=>rst, x => RxD, xSync => RxDSync );

    baudCnt: --Contador divisor de frecuencia para generar enable cada ciclo de baudios
        process (clk)
        begin
            if rising_edge(clk) then
                if(rst = '1') then
                    countBaud <= 0;
                elsif baudCntCE = '1' then
                    if countBaud = CYCLES-1 then
                        countBaud <= 0;
                       
                    else
                        countBaud <= countBaud + 1;
                        
                    end if;
                else
                    countBaud <= 0;
                end if;
            end if;
        end process;
    readRx <= '1' when (countBaud = (CYCLES/2)-1) and baudCntCE = '1' else '0';
    
    modCounter11:
        process (clk)
        begin
            if rising_edge(clk) then
                if(rst = '1') then
                    bitCounter <= (others => '0');
                else
                    if bitPosCE = '1' then
                        if bitCounter = "1010" then 
                            bitCounter <= (others => '0');
                        else
                            bitCounter <= bitCounter + 1;
                        end if;
                    end if;
                end if;
            end if;
        end process;
    posCounter <= std_logic_vector(bitCounter);
    
   
    ShifterRegProc:
        process (clk)
        begin
            if(rising_edge(clk) ) then
                if(rst = '1') then
                    shifterReg <= (others => '0');
                elsif shiftRx = '1' then
                    shifterReg <= RxDSync & shifterReg(9 downto 1); -- Shift a la derecha, rellenando con el nuevo bit por la izquierda
                else
                    shifterReg <= shifterReg;
                end if;
            end if;
        end process;
    data <= shifterReg(8 downto 1); -- Los 8 bits de datos son los bits 8 a 1 del shifter


end rtl;