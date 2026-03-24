-------------------------------------------------------------------
--
--  Fichero:
--    rs232receiver.vhd  12/09/2023
--
--    (c) J.M. Mendias
--    Dise�o Autom�tico de Sistemas
--    Facultad de Inform�tica. Universidad Complutense de Madrid
--
--  Prop�sito:
--    Conversor elemental de una linea serie RS-232 a paralelo con 
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
use work.common.all;

entity rs232receiver is
  generic (
    FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
    BAUDRATE : natural   -- velocidad de comunicacion
  );
  port (
    -- host side
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    dataRdy : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
    data    : out std_logic_vector (7 downto 0);   -- dato recibido
    -- RS232 side
    RxD     : in  std_logic    -- entrada de datos serie del interfaz RS-232
  );
end rs232receiver;

-------------------------------------------------------------------
architecture rtl of rs232receiver is
component rs232receiverDP is
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
end component;

component rs232receiverFSM is
  port (
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    rxD : in  std_logic;   -- señal sincronizada de entrada de datos serie del interfaz RS-232
    dataRdy : out std_logic;   -- se activa durante 1 ciclo cada vez
    controlIn: in std_logic_vector(4 downto 0); -- señales que se reciben del DataPath
    controlOut: out std_logic_vector(2 downto 0) -- señales que se envian al DataPath
    );
end component;
signal controlFSMtoDP : std_logic_vector(2 downto 0);
signal controlDPtoFSM : std_logic_vector(4 downto 0);
signal rxDSync : std_logic;

begin
    SynchronizerRxD : synchronizer
        generic map ( STAGES => 2, XPOL => '1' )
        port map ( clk => clk, rst => rst, x => RxD, xSync => rxDSync );
    FSM: rs232receiverFSM
        port map ( clk => clk, rst => rst, rxD => rxDSync, dataRdy => dataRdy, controlIn => controlDPtoFSM, controlOut => controlFSMtoDP );
    DP: rs232receiverDP
        generic map ( FREQ_KHZ => FREQ_KHZ, BAUDRATE => BAUDRATE )
        port map ( clk => clk, rst => rst, controlIn => controlFSMtoDP, controlOut => controlDPtoFSM, data => data, RxD => rxDSync);
        
end rtl;
