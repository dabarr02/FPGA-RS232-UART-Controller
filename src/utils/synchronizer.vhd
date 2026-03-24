-------------------------------------------------------------------
--
--  Fichero:
--    synchronizer.vhd  
--
--    
--    Facultad de Inform�tica. Universidad Complutense de Madrid
--
--  Prop�sito:
--    Sincroniza una entrada binaria
--
--  Notas de dise�o:
--    Orientado a FPGA Xilinx 7 series
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity synchronizer is
  generic (
    STAGES  : natural;       -- n�mero de biestables del sincronizador
    XPOL    : std_logic      -- polaridad (valor en reposo) de la se�al a sincronizar
  );
  port (
    rst : in std_logic; -- reset s�ncrono del sistema
    clk   : in  std_logic;   -- reloj del sistema
    x     : in  std_logic;   -- entrada binaria a sincronizar
    xSync : out std_logic    -- salida sincronizada que sigue a la entrada
  );
end synchronizer;

-------------------------------------------------------------------

architecture syn of synchronizer is 
 signal aux : std_logic_vector(STAGES-1 downto 0) := (others => XPOL); 
begin
  process (clk,rst)
  begin
    
    if rising_edge(clk) then
      if rst = '1' then
        aux <= (others => XPOL);
      else
        aux<=aux(STAGES-2 downto 0) & x;
      end if;
    end if;
  end process;
  xSync <= aux(STAGES-1);

end syn;
