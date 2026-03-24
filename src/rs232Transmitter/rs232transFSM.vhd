-------------------------------------------------------------------
--
--  Fichero:
--    rs232transmitterFSM.vhd  13/3/2026
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

entity rs232transmitterFSM is
  port (
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    dataRdy : in  std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato a transmitir
    busy    : out std_logic;   -- se activa mientras esta transmitiendo
    controlIn: in std_logic_vector(4 downto 0); -- señales que se reciben del DataPath
    controlOut: out std_logic_vector(3 downto 0) -- señales que se envian al DataPath
    );
end rs232transmitterFSM;

--------------------------------------------------------------------
use work.common.all;
architecture rtl  of rs232transmitterFSM is
    type state_type is (IDLE, EMITIR);
    signal STATE, NEXT_STATE : state_type := IDLE;
    signal controlIn_aux : std_logic_vector(4 downto 0);
    signal controlOut_aux : std_logic_vector(3 downto 0);
    alias writeTx : std_logic is controlIn_aux(0);
    alias posCounter: std_logic_vector(3 downto 0) is controlIn_aux(4 downto 1);
    alias baudCntCE : std_logic is controlOut_aux(0);
    alias bitPosCE : std_logic is controlOut_aux(1);
    alias txDLoad : std_logic is controlOut_aux(2);
    alias txDShift : std_logic is controlOut_aux(3);
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
    process (STATE, dataRdy, writeTx, posCounter)
    begin
        -- Valores por defecto
        bitPosCE <= '0';
        baudCntCE <= '0';
        txDLoad <= '0';
        txDShift <= '0';
        busy <= '0';

        case STATE is
            when IDLE =>
                if dataRdy = '1' then
                    txDLoad <= '1';
                    
                    NEXT_STATE <= EMITIR;
                else
                    NEXT_STATE <= IDLE;
                end if;

            when EMITIR =>
                busy <= '1';
                baudCntCE <= '1';
                if (writeTx = '1') then
                    -- Solo incrementamos y comprobamos el final al acabar el baudio
                    if (posCounter = "1001") then -- Tras el 10º bit (índice 9)
                        bitPosCE <= '1'; -- Esto lo devolverá a 0
                        NEXT_STATE <= IDLE;
                        txDShift <= '1';
                    else
                        txDShift <= '1';
                        bitPosCE <= '1';
                        NEXT_STATE <= EMITIR;
                    end if;
                else
                    NEXT_STATE <= EMITIR;
                end if;
        end case;
    end process COMB_LOGIC;

end rtl;

 