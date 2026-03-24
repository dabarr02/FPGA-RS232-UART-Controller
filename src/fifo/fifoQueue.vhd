--
--  Fichero:
--    fifoQueue.vhd  16/03/2026
--
--   
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Buffer de tipo FIFO
--
--  Notas de diseño:
--    - Está implementada con BRAM
--    - Si la FIFO está llena, los nuevos datos que se intenten 
--      almacenar se ignoran
--    - Si la FIFO está vacía, las lecturas devuelven valores no
--      validos
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.common.all;

entity fifoQueue is
  generic (
    WL    : natural;   -- anchura de la palabra de fifo
    DEPTH : natural    -- numero de palabras en fifo
  );
  port (
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset síncrono del sistema
    wrE     : in  std_logic;   -- se activa durante 1 ciclo para escribir un dato en la fifo
    dataIn  : in  std_logic_vector(7 downto 0);   -- dato a escribir
    rdE     : in  std_logic;   -- se activa durante 1 ciclo para leer un dato de la fifo
    dataOut : out std_logic_vector(7 downto 0);   -- dato a leer
    numData : out std_logic_vector(4 downto 0);   -- numero de datos almacenados (max 16)
    full    : out std_logic;   -- indicador de fifo llena
    empty   : out std_logic    -- indicador de fifo vacia
  );
end fifoQueue;

architecture rtl of fifoQueue is

 component fifoDP is
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
end component;


component fifoFSM is
  port (
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset s�ncrono del sistema
    rdE : in  std_logic;   -- señal de lectura
    wrE : in std_logic;   
    controlIn: in std_logic_vector(3 downto 0); -- señales que se reciben del DataPath
    controlOut: out std_logic_vector(8 downto 0) -- señales que se envian al DataPath
    );
end component;

signal controlFSMtoDP: std_logic_vector(8 downto 0);
signal controlDPtoFSM: std_logic_vector(3 downto 0);

begin

    DP: fifoDP
    port map (
        clk => clk,
        rst => rst,
        controlIn => controlFSMtoDP,
        controlOut => controlDPtoFSM,
        dataIn => dataIn,
        dataOut => dataOut,
        numData => numData,
        full => full,
        empty => empty
    );

    FSM: fifoFSM
    port map (
        clk => clk,
        rst => rst,
        rdE => rdE,
        wrE => wrE,
        controlIn => controlDPtoFSM,
        controlOut => controlFSMtoDP
    );

end rtl;