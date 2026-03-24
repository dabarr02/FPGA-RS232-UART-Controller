library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifoQueue_tb is
end fifoQueue_tb;

architecture bench of fifoQueue_tb is
  -- Componente a testear [cite: 75-77]
  component fifoQueue
    generic ( WL : natural; DEPTH : natural );
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      wrE     : in  std_logic;
      dataIn  : in  std_logic_vector(7 downto 0);
      rdE     : in  std_logic;
      dataOut : out std_logic_vector(7 downto 0);
      numData : out std_logic_vector(4 downto 0);
      full    : out std_logic;
      empty   : out std_logic
    );
  end component;

  -- Señales de interconexión
  signal clk, rst, wrE, rdE : std_logic := '0';
  signal dataIn, dataOut : std_logic_vector(7 downto 0);
  signal numData : std_logic_vector(4 downto 0);
  signal full, empty : std_logic;

  constant clk_period : time := 10 ns;

begin

  -- Instancia con profundidad 16 (4 bits de direccion) [cite: 75-77]
  uut: fifoQueue 
    generic map ( WL => 8, DEPTH => 16 )
    port map ( clk=>clk, rst=>rst, wrE=>wrE, dataIn=>dataIn, rdE=>rdE, dataOut=>dataOut, numData=>numData, full=>full, empty=>empty );

  -- Generador de reloj (100 MHz)
  clk_process : process begin
    clk <= '0'; wait for clk_period/2;
    clk <= '1'; wait for clk_period/2;
  end process;

  -- Proceso de estímulos orientado al cronograma
  stim_proc: process
  begin
    -- 1. RESET inicial
    rst <= '1'; wrE <= '0'; rdE <= '0'; dataIn <= x"00";
    wait for 20 ns;
    rst <= '0'; wait for clk_period;

    -- 2. ESCRITURA DESDE VACÍO (Verificar latencia BRAM)
    dataIn <= x"A1"; wrE <= '1'; wait for clk_period; -- Escribimos A1
    wrE <= '0'; wait for clk_period * 2; -- Esperamos a que el dato se estabilice

    -- 3. LECTURA SIMPLE
    rdE <= '1'; wait for clk_period;
    rdE <= '0'; wait for clk_period * 2;

    -- 4. LLENADO RÁPIDO (Burst)
    for i in 1 to 5 loop
        dataIn <= std_logic_vector(to_unsigned(i, 8));
        wrE <= '1'; wait for clk_period;
    end loop;
    wrE <= '0'; wait for clk_period * 2;

    -- 5. OPERACIÓN SIMULTÁNEA (Evitar bloqueo anterior) 
    -- Intentamos leer y escribir a la vez
    dataIn <= x"FF"; wrE <= '1'; rdE <= '1'; 
    wait for clk_period;
    wrE <= '0'; rdE <= '0';
    
    wait for clk_period * 5;
    report "Simulación de cronograma completada";
    wait;
  end process;

end architecture;