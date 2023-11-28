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
        requisitado: in std_logic;
        andar: in std_logic_vector(3 downto 0);
        saida: out std_logic_vector(1 downto 0);
        andar_display: out std_logic_vector(6 downto 0);
        andar_atual_display: out std_logic_vector(6 downto 0)
    );
END Elevador;

ARCHITECTURE arch OF elevador IS
    COMPONENT debouncer
    PORT (
        clk_fpga, rst_debouncer, input_key: in std_logic;
        out_key: out std_logic);
	 END COMPONENT;

    COMPONENT sevensegmentdisplay
    PORT (
        d0, d1, d2, d3: in std_logic;
        A, B, C, D, E, F, G: out std_logic);
    END COMPONENT;

    TYPE st IS (desce, sobe, espera);
    SIGNAL estado: st;
    SIGNAL andar_atual: std_logic_vector(3 downto 0);
    SIGNAL out_clk_db, out_rst_db: std_logic;

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
        DisplayAndar: sevensegmentdisplay PORT MAP(
            d0 => andar(0),
            d1 => andar(1),
            d2 => andar(2),
            d3 => andar(3),
            A => andar_display(0),
            B => andar_display(1),
            C => andar_display(2),
            D => andar_display(3),
            E => andar_display(4),
            F => andar_display(5),
            G => andar_display(6)
        );
        DisplayAndarAtual: sevensegmentdisplay PORT MAP(
            d0 => andar_atual(0),
            d1 => andar_atual(1),
            d2 => andar_atual(2),
            d3 => andar_atual(3),
            A => andar_atual_display(0),
            B => andar_atual_display(1),
            C => andar_atual_display(2),
            D => andar_atual_display(3),
            E => andar_atual_display(4),
            F => andar_atual_display(5),
            G => andar_atual_display(6)
        );

        PROCESS (out_clk_db, out_rst_db)
        BEGIN

            IF out_rst_db = '1' THEN
                andar_atual <= "0000";
                estado <= espera;
            ELSIF rising_edge(out_clk_db) THEN
                CASE estado IS
                    WHEN espera =>
                        IF requisitado = '1' THEN
                            IF andar_atual = andar THEN
                                estado <= espera;
                            ELSIF andar_atual < andar THEN
                                estado <= sobe;
                                andar_atual <= andar_atual + "0001";
                            ELSIF andar_atual > andar THEN
                                estado <= desce;
                                andar_atual <= andar_atual - "0001";
                            END IF;
                        else
                            estado <= espera;
                        END IF;
                    WHEN sobe =>
                        IF andar_atual /= andar THEN
                            andar_atual <= andar_atual + "0001";
                        ELSE
                            estado <= espera;
                        END IF;
                    WHEN desce =>
                        IF andar_atual /= andar THEN
                            andar_atual <= andar_atual - "0001";
                        else
                            estado <= espera;
                        END IF;
                END CASE;
            END IF;            
END PROCESS;

WITH estado SELECT saida <=
    "00" WHEN espera,
    "01" WHEN sobe,
    "10" WHEN desce;
END arch;