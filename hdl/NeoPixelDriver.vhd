
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity NeoPixelDriver is
    Port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;
           dataIn : in STD_LOGIC_VECTOR(23 downto 0);
           dataOut : out STD_LOGIC:= '0';
           isEmpty: out STD_LOGIC := '1';
           busy: out STD_LOGIC := '0';
           bitTime: in integer := 125;
           oneTime: in integer := 75;
           zeroTime: in integer := 28;
           resetTime: in integer := 50000);
end NeoPixelDriver;

architecture Behavioral of NeoPixelDriver is
-- State definitions
    constant state_idle     : unsigned(1 downto 0) := "00";
    constant state_transmit : unsigned(1 downto 0) := "01";
    constant state_finish   : unsigned(1 downto 0) := "10";
    
-- other constants  
    signal state : unsigned (1 downto 0) := state_idle;
    signal dataCopy : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');
    signal bitCounter : integer := 0;
    signal bitTimeCounter : integer := 0;
begin
    fsm_proc: process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when state_idle =>
                    if en = '1' then
                        dataCopy <= dataIn;
                        isEmpty <= '0';
                        bitCounter <= 0;
                        bitTimeCounter <= 0;
                        state <= state_transmit;
                        dataOut <= '1';
                        busy <= '1';
                    end if;
                when state_transmit =>
                    bitTimeCounter <= bitTimeCounter + 1;
                                        
                    if bitTimeCounter = bitTime then
                        bitTimeCounter <= 0;
                        bitCounter <= bitCounter + 1;
                        dataOut <= '1';
                        isEmpty <= '1';
                        -- Weird scheduling issue where bit counter
                        -- does not get updated until the next iteration
                        if bitCounter = 23 and en = '1' then
                            state <= state_idle;
                        elsif bitCounter = 23 then
                            dataOut <= '0';
                            state <= state_finish;
                        end if;
                    end if;
                    
                    if (dataCopy(23 - bitCounter) = '0' and bitTimeCounter = zeroTime) or
                        (dataCopy(23 - bitCounter) = '1' and bitTimeCounter = oneTime) then
                        dataOut <= '0';    
                    end if; 

                when state_finish =>
                    bitTimeCounter <= bitTimeCounter + 1;
                    if (bitTimeCounter = resetTime) then
                        state <= state_idle;
                        busy <= '0';
                    end if;

                when others =>
            end case;
        end if;
    end process;

end Behavioral;
