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
entity rs232transmitterDP is
    generic (
        FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
        BAUDRATE : natural   -- velocidad de comunicacion
    );
    port (
        -- host side
        clk     : in  std_logic;   -- reloj del sistema
        rst     : in  std_logic;   -- reset s�ncrono del sistema
        controlIn: in std_logic_vector(3 downto 0); -- señales que se reciben del FSM
        controlOut: out std_logic_vector(4 downto 0); -- señales que se envian al FSM
        data    : in  std_logic_vector (7 downto 0);   -- dato a transmitir
        txD     : out std_logic    -- salida de datos serie del interfaz RS-232
    );
end rs232transmitterDP;
-------------------------------------------------------------------
use work.common.all;
architecture rtl of rs232transmitterDP is
    signal controlIn_aux : std_logic_vector(3 downto 0);
    signal controlOut_aux : std_logic_vector(4 downto 0);
    alias baudCntCE : std_logic is controlIn_aux(0);
    alias bitPosCE : std_logic is controlIn_aux(1);
    alias txDLoad : std_logic is controlIn_aux(2);
    alias txDShift : std_logic is controlIn_aux(3);
    alias writeTx : std_logic is controlOut_aux(0);
    alias posCounter: std_logic_vector(3 downto 0) is controlOut_aux(4 downto 1);
    constant CYCLES : natural := (FREQ_KHZ*1000)/BAUDRATE;
    signal countBaud  : natural range 0 to CYCLES-1 := 0;
    signal bitCounter : unsigned(3 downto 0) := (others => '0');
    signal shifterReg : std_logic_vector(9 downto 0) := (others => '0');
begin
    controlIn_aux <= controlIn;
    controlOut <= controlOut_aux;

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
    writeTx <= '1' when (countBaud = CYCLES-1) else '0';
    
    modCounter11:
        process (clk)
        begin
            if rising_edge(clk) then
                if(rst = '1') then
                    bitCounter <= (others => '0');
                else
                    if bitPosCE = '1' then
                        if bitCounter = "1001" then -- Contador modulo 11 (start + 8 data + stop)
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
                    shifterReg <= (others => '1');
                elsif txDLoad = '1' then
                    shifterReg <= '1' & data & '0'; -- Cargar el shifter con el bit de start (0), los 8 bits de datos y el bit de stop (1)
                elsif txDShift = '1' then
                    shifterReg <= '1' & shifterReg(9 downto 1); -- Shift a la derecha, rellenando con 1's por la izquierda (stop bits)
                else
                    shifterReg <= shifterReg;
                end if;
            end if;
        end process;
    txD <= shifterReg(0); -- El bit a transmitir es el LSB del shifter


end rtl;