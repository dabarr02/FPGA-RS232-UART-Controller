-------------------------------------------------------------------
--
--  Fichero:
--    rs232receiverFSM.vhd  13/3/2026
--
--  
--    Diseño Automatico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Prop�sito:
--    Unidad de controls para rs232receiver.vhd
--
--  Notas de dise�o:
--    - Parity: NONE
--    - Num data bits: 8
--    - Num stop bits: 1
--
-------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity rs232receiverFSM is
  port (
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    rxD : in  std_logic;   -- señal sincronizada de entrada de datos serie del interfaz RS-232
    dataRdy : out std_logic;   -- se activa durante 1 ciclo cada vez
    controlIn: in std_logic_vector(4 downto 0); -- señales que se reciben del DataPath
    controlOut: out std_logic_vector(2 downto 0) -- señales que se envian al DataPath
    );
end rs232receiverFSM;

--------------------------------------------------------------------
use work.common.all;
architecture rtl  of rs232receiverFSM is
    type state_type is (IDLE, RECIBIR, LISTO);
    signal STATE, NEXT_STATE : state_type := IDLE;
    signal controlIn_aux : std_logic_vector(4 downto 0);
    signal controlOut_aux : std_logic_vector(2 downto 0);
    alias readRx : std_logic is controlIn_aux(0);
    alias posCounter: std_logic_vector(3 downto 0) is controlIn_aux(4 downto 1);
    alias baudCntCE : std_logic is controlOut_aux(0);
    alias bitPosCE : std_logic is controlOut_aux(1);
    alias shiftRx : std_logic is controlOut_aux(2);
    
begin
    controlIn_aux <= controlIn;
    controlOut <= controlOut_aux;

    STATE_REG:
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                STATE <= IDLE;
            else
                STATE <= NEXT_STATE;
            end if;
        end if;
    end process STATE_REG;

    COMB_LOGIC:
    process (STATE, rxD, readRx, posCounter)
    begin
    ---Valores por defecto
        bitPosCE <= '0';
        baudCntCE <= '0';
        shiftRx <= '0';
        dataRdy <= '0';
    ---Fin Defaults
    ---Inicio FSM
    case STATE is
        when IDLE =>
           if(rxD = '0') then -- Detectamos el bit de start
                NEXT_STATE <= RECIBIR;
                bitPosCE <= '1'; -- Habilitamos el contador de bits para contar los 8 bits de datos
            else
                NEXT_STATE <= IDLE;
                bitPosCE <= '0';
            end if;
        when RECIBIR =>
            baudCntCE <= '1'; -- Habilitamos el contador de baudios para generar el enable de lectura en el momento adecuado
            if(readRx = '1') then
                shiftRx <= '1'; -- Habilitamos el shift del shifter del datapath para ir almacenando los bits recibidos
                bitPosCE <= '1';
                if(posCounter = "1010") then -- Cuando hemos recibido el bit de stop (posCounter = 10), activamos dataRdy durante un ciclo
                    NEXT_STATE <= LISTO;
                else
                    NEXT_STATE <= RECIBIR;
                end if;
            else
                NEXT_STATE <= RECIBIR;
            end if;
        when LISTO =>
            NEXT_STATE <= IDLE; -- Volvemos a IDLE para esperar la siguiente trama
            dataRdy <= '1'; -- Activamos dataRdy durante un ciclo para indicar que hay datos listos
        end case;
    end process COMB_LOGIC;

end rtl;

 