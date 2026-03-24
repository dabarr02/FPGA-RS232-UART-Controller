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

entity fifoFSM is
  port (
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    rdE : in  std_logic;   -- señal de lectura
    wrE : in std_logic;   
    controlIn: in std_logic_vector(3 downto 0); -- señales que se reciben del DataPath
    controlOut: out std_logic_vector(8 downto 0) -- señales que se envian al DataPath
    );
end fifoFSM;

--------------------------------------------------------------------
use work.common.all;
architecture rtl  of fifoFSM is
 type state_type is (EMPTY_STATE, FULL_STATE, LAST_WRITE, LAST_READ);
    signal STATE, NEXT_STATE : state_type := EMPTY_STATE;
    signal controlIn_aux : std_logic_vector(3 downto 0);
    signal controlOut_aux : std_logic_vector(8 downto 0);
    ----------Alias para controlIn----------
    alias nextWrtEq: std_logic is controlIn_aux(0);
    alias nextRdEq: std_logic is controlIn_aux(1);
    alias isEmpty: std_logic is controlIn_aux(2);
    alias isFull: std_logic is controlIn_aux(3);

    ----------Alias para controlOut----------
    alias incWrPtr: std_logic is controlOut_aux(0);
    alias incRdPtr: std_logic is controlOut_aux(1);
    alias wrEn: std_logic is controlOut_aux(2);
    alias emptySet: std_logic is controlOut_aux(3);
    alias emptyClr: std_logic is controlOut_aux(4);
    alias fullSet: std_logic is controlOut_aux(5);
    alias fullClr: std_logic is controlOut_aux(6);
    alias countInc: std_logic is controlOut_aux(7);
    alias countDec: std_logic is controlOut_aux(8);

    
begin
    controlIn_aux <= controlIn;
    controlOut <= controlOut_aux;
    
    STATE_REG:
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                STATE <= EMPTY_STATE;
            else
                STATE <= NEXT_STATE;
            end if;
        end if;
    end process STATE_REG;

   COMB_LOGIC: process (STATE, isEmpty, isFull, nextWrtEq, nextRdEq, rdE, wrE)
    begin
        -- Valores por defecto 
        incWrPtr <= '0'; incRdPtr <= '0'; wrEn <= '0';
        emptySet <= '0'; emptyClr <= '0'; fullSet <= '0'; fullClr <= '0'; countInc <= '0'; countDec <= '0';

        case STATE is
            when EMPTY_STATE =>
                if (wrE = '1') then
                    incWrPtr <= '1'; 
                    wrEn <= '1'; 
                    countInc <= '1';
                    if nextWrtEq = '1' then 
                        fullSet <= '1'; 
                        NEXT_STATE <= FULL_STATE;
                    else 
                        NEXT_STATE <= LAST_WRITE;
                    end if;
                else
                    NEXT_STATE <= EMPTY_STATE;
                end if;
            when FULL_STATE =>
                if (rdE = '1') then
                    incRdPtr <= '1';
                    fullClr <= '1';
                    countDec <= '1';
                    if nextRdEq = '1' then 
                        emptySet <= '1';
                        NEXT_STATE <= EMPTY_STATE;
                    else 
                        NEXT_STATE <= LAST_READ;
                    end if;
                else
                    NEXT_STATE <= FULL_STATE;
                end if;

            when LAST_WRITE | LAST_READ =>
                emptyClr <= '1';
                fullClr <= '1';   
                if (wrE = '1' and rdE = '1') then
                    -- CASO SIMULTÁNEO: Movemos ambos punteros, el número de datos no cambia
                    incWrPtr <= '1';
                    incRdPtr <= '1';
                    wrEn <= '1';
                    NEXT_STATE <= STATE;

                elsif (wrE = '1' and isFull = '0') then
                -- SOLO ESCRITURA
                    incWrPtr <= '1';
                    wrEn <= '1';
                    countInc <= '1';
                    if nextWrtEq = '1' then 
                        fullSet <= '1';
                        NEXT_STATE <= FULL_STATE;
                    else 
                        NEXT_STATE <= LAST_WRITE;
                    end if;

                    elsif (rdE = '1' and isEmpty = '0') then
                        -- SOLO LECTURA
                        incRdPtr <= '1';
                        countDec <= '1';
                        if nextRdEq = '1' then 
                            emptySet <= '1';
                            NEXT_STATE <= EMPTY_STATE;
                        else 
                            NEXT_STATE <= LAST_READ;
                        end if;
                    else
                        NEXT_STATE <= STATE;
                end if;
        end case;
    end process COMB_LOGIC;

end rtl;


 