-------------------------------------------------------------------
--
--  Fichero:
--    rs232transmitter.vhd  16/3/2026
--
--  
--    Dise�o Autom�tico de Sistemas
--    Facultad de Inform�tica. Universidad Complutense de Madrid
--
--  Prop�sito:
--    Conversor elemental de paralelo a una linea serie RS-232 con 
--    protocolo de strobe
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

entity rs232transmitter is
  generic (
    FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
    BAUDRATE : natural   -- velocidad de comunicacion
  );
  port (
    -- host side
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    dataRdy : in  std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato a transmitir
    data    : in  std_logic_vector (7 downto 0);   -- dato a transmitir
    busy    : out std_logic;   -- se activa mientras esta transmitiendo
    -- RS232 side
    TxD     : out std_logic    -- salida de datos serie del interfaz RS-232
  );
end rs232transmitter;

-------------------------------------------------------------------

use work.common.all;

architecture rtl of rs232transmitter is
component rs232transmitterDP is
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
end component;

component rs232transmitterFSM is
  port (
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    dataRdy : in  std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato a transmitir
    busy    : out std_logic;   -- se activa mientras esta transmitiendo
    controlIn: in std_logic_vector(4 downto 0); -- señales que se reciben del DataPath
    controlOut: out std_logic_vector(3 downto 0) -- señales que se envian al DataPath
    );
end component;

signal controlFSMtoDP : std_logic_vector(3 downto 0);
signal controlDPtoFSM : std_logic_vector(4 downto 0);
  
begin
control: rs232transmitterFSM
    port map (
        clk => clk,
        rst => rst,
        dataRdy => dataRdy,
        busy => busy,
        controlIn => controlDPtoFSM,
        controlOut => controlFSMtoDP
    );
  
datapath: rs232transmitterDP
    generic map (
        FREQ_KHZ => FREQ_KHZ,
        BAUDRATE => BAUDRATE
    ) port map (
        clk => clk,
        rst => rst,
        controlIn => controlFSMtoDP,
        controlOut => controlDPtoFSM,
        data => data,
        txD => TxD
    );
  
end rtl;

