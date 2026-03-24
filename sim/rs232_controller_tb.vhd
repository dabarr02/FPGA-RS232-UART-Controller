library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rs232_controller_tb is
end rs232_controller_tb;

architecture bench of rs232_controller_tb is

  -- Componente a testear (Unit Under Test) 
  component rs232_controller_top
    port (
      clk    : in  std_logic;
      rst    : in  std_logic;
      RxD    : in  std_logic;
      TxD    : out std_logic;
      TxEn   : in  std_logic;
      leds   : out std_logic_vector(15 downto 0);
      an_n   : out std_logic_vector (3 downto 0);
      segs_n : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Configuración de tiempos para 1200 baudios 
  constant BAUDRATE : natural := 1200; 
  constant clk_period : time := 10 ns; -- 100 MHz
  -- Un bit a 1200 baudios tarda ~833.33 us
  constant baud_period : time := 833333 ns; 

  -- Señales del banco de pruebas
  signal clk, rst, TxEn : std_logic := '0';
  signal RxD : std_logic := '1'; -- Reposo en alto
  signal TxD : std_logic;
  signal leds : std_logic_vector(15 downto 0);
  signal an_n : std_logic_vector(3 downto 0);
  signal segs_n : std_logic_vector(7 downto 0);

  -- Procedimiento para inyectar bytes por el receptor
  procedure inject_byte(constant byte : in std_logic_vector(7 downto 0); signal line : out std_logic) is
  begin
    line <= '0'; wait for baud_period; -- Start
    for i in 0 to 7 loop
      line <= byte(i); wait for baud_period;
    end loop;
    line <= '1'; wait for baud_period; -- Stop
    wait for baud_period; -- Pausa entre caracteres
  end procedure;

begin

  -- Instancia del sistema completo [cite: 215-217]
  uut: rs232_controller_top 
    port map ( 
        clk    => clk, 
        rst    => rst, 
        RxD    => RxD, 
        TxD    => TxD, 
        TxEn   => TxEn, 
        leds   => leds, 
        an_n   => an_n, 
        segs_n => segs_n 
    );

  -- Generador de reloj
  clk_process : process 
  begin
    clk <= '0'; wait for clk_period/2;
    clk <= '1'; wait for clk_period/2;
  end process;

  -- Proceso de estímulos
  stim_proc: process
    variable captured : std_logic_vector(7 downto 0);
  begin
    -- Inicialización
    RxD <= '1'; TxEn <= '0'; rst <= '1';
    wait for 100 ns;
    rst <= '0';
    wait for 1 ms;

    -- FASE 1: Inyectar 6 bytes ("123456")
    report "--- FASE 1: Inyectando secuencia 1-2-3-4-5-6 ---";
    inject_byte(x"31", RxD); -- '1'
    inject_byte(x"32", RxD); -- '2'
    inject_byte(x"33", RxD); -- '3'
    inject_byte(x"34", RxD); -- '4'
    inject_byte(x"35", RxD); -- '5'
    inject_byte(x"36", RxD); -- '6'

    wait for 2 ms;
    report "Datos en FIFO (Leds encendidos): " & to_string(leds);

    -- FASE 2: Activar volcado (Loopback)
    report "--- FASE 2: Activando TxEn para volcado ---";
    TxEn <= '1';

    -- Capturamos los 6 bytes que el transmisor debería devolver
    for j in 1 to 6 loop
        wait until TxD = '0'; -- Esperar inicio del bit de Start
        report "   [TXD] Detectado inicio de byte " & integer'image(j);
        wait for baud_period / 2; -- Situarse en el centro del bit
        
        for i in 0 to 7 loop
            wait for baud_period;
            captured(i) := TxD;
        end loop;
        
        report "   >>> BYTE RECIBIDO: " & to_hstring(captured);
        wait until TxD = '1'; -- Esperar fin del bit de Stop
    end loop;

    report "--- TEST FINALIZADO CON EXITO ---";
    wait;
  end process;

end architecture;