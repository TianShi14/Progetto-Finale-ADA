library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity randomizer is
    port(
        clk    : in  std_logic;
        random : out std_logic_vector(7 downto 0)
    );
end randomizer;

architecture behavior of randomizer is
    signal lfsr: std_logic_vector(7 downto 0) := "10011010";
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            lfsr(7 downto 1) <= lfsr(6 downto 0);
            lfsr(0) <= lfsr(7) xor lfsr(6) xor lfsr(5) xor lfsr(4) xor lfsr(3) xor lfsr(2) xor lfsr(1) xor lfsr(0);
            random <= lfsr;
        end if;
    end process;

end behavior;