LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

ENTITY Elevador is
    port (
        clk: in std_logic;
        clk_button: in std_logic;
        reset: in std_logic;
        reset_debouncer: in std_logic;
        sobe_button: in std_logic;
        requisitado: in std_logic;
        andar: in std_logic_vector(3 downto 0);
        saida: out std_logic_vector(1 downto 0)
    );
END Elevador;

ARCHITECTURE arch OF elevador IS
    COMPONENT debouncer
    PORT (
        clk_fpga, rst_debouncer, input_key: in std_logic;
        out_key: out std_logic);
	 END COMPONENT;

    TYPE st IS (desce, sobe, espera);
    SIGNAL estado: st;
    SIGNAL out_clk_db, out_rst_db, out_sobe_db: std_logic;

BEGIN
        D1: debouncer PORT MAP(
            clk_fpga => clk,
            rst_debouncer => reset_debouncer,
            input_key => clk_button,
            out_key => out_clk_db
        );
        D2: debouncer PORT MAP(
            clk_fpga => clk,
            rst_debouncer => reset_debouncer,
            input_key => reset,
            out_key => out_rst_db
        );
        D3: debouncer PORT MAP(
            clk_fpga => clk,
            rst_debouncer => reset_debouncer,
            input_key => sobe_button,
            out_key => out_sobe_db
        );

        PROCESS (out_clk_db, out_rst_db)
            VARIABLE andar_atual: std_logic_vector(3 downto 0) := "0000";
            VARIABLE count: std_logic_vector(3 downto 0) := "0000";
        BEGIN
            IF out_rst_db = '1' THEN
                andar_atual := "0000";
                count := "0000";
                estado <= espera;
            ELSIF rising_edge(out_clk_db) THEN
                IF count > "0000" THEN
                    count := count - "0001";
                END IF;
                
                IF (requisitado = '1' AND count="0000") THEN
                    IF andar_atual = andar THEN
                        estado <= espera;
                    ELSIF andar_atual < andar THEN
                        estado <= sobe;
                        count := andar - andar_atual;
                    ELSIF andar_atual > andar THEN
                        estado <= desce;
                        count := andar_atual - andar;
                    END IF;
					andar_atual := andar;
                else
                    estado <= espera;
                END IF;
			END IF;
END PROCESS;

WITH estado SELECT saida <=
    "00" WHEN espera,
    "01" WHEN sobe,
    "10" WHEN desce;
END arch;