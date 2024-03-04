library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity output is
    port(
        clk        : in  std_logic;
        clk25      : in  std_logic;
        startGame  : in  std_logic;
        active     : in  std_logic;
        endFrame   : in  std_logic;
        genFrame   : out std_logic; -- preparazione schermata successiva
        r, g, b    : out std_logic_vector(3 downto 0);
        -- segnali per mem Game
        clkGame    : out std_logic;                            -- specific clock for Start screen ROM, useful for clock masking                  
        address    : out std_logic_vector(17 downto 0);        -- mem Game address  
        memGameOut : in  std_logic_vector(11 downto 0);        -- data out Game mem 
        wena       : out std_logic_vector(0 to 0);
        ena        : out std_logic;
        newRow     : out std_logic;
        enable     : out std_logic                                                                                                                       
    );
end output;

architecture behavioral of output is
    type msf is (start, transition, game);                      -- state types
    signal state        : msf := start;                         -- state machine 
    signal vgaCount     : integer range 0 to 640*480-1 := 0;    -- global counter
    signal memCounter   : integer range 0 to 480*240-1 := 0;    -- Mem counter  
    signal HCounter     : integer range 0 to 640 - 1   := 0;
    signal pixelN       : integer range 0 to 48 - 1    := 0; 
    signal rowN         : integer range 0 to 20 - 1    := 10;
    signal startAddr    : integer := 480 * 240;
    signal flipCount    : integer := 0;
    signal flip         : boolean := false;
    signal isStarting   : boolean := false;
    signal prevClk25    : std_logic;
    
begin

    wena <= "0";

    process (clk)
        variable timeCount : integer := 0;       -- contiamo fino a 3 sec per la transizione
        variable rowNN     : integer;
        variable pixelNN   : integer;
    begin
        
        if rising_edge(clk) then
            prevClk25 <= clk25;
            
            case state is
                when start =>
--                    if active = '1' then
--                        r <= romStartOut(11 downto 8);
--                        g <= romStartOut (7 downto 4);
--                        b <= romStartOut (3 downto 0);
--                        if prevClk25 = '0' and clk25 = '1' then -- rising edge di clk25 mhz
--                            memCounter <= memCounter + 1;
--                            if memCounter = 640*480-1 then
--                                memCounter <= 0;
--                                if isStarting then
--                                    genFrame <= '1';
--                                    state <= transition;
--                                end if;
--                            end if;
--                        end if;
--                    end if;
--                    if startGame = '1' then
--                        isStarting := true;
--                    end if;
                    r <= (others => '0');
                    g <= (others => '0');
                    b <= (others => '0');
                    if startGame = '1' then
                        state    <= transition;
                        genFrame <= '1';
                        enable    <= '1';
                    end if;
                when transition =>
                    enable   <= '0';
                    genFrame <= '0';
                    r <= (others => '1');
                    g <= (others => '0');
                    b <= (others => '1');
                    if timeCount < 2 then  -- 200_000_000
                        timeCount := timeCount + 1;
                    else
                        if endFrame = '1' then  -- aspettare che finisca di disegnare il frame
                            timeCount  := 0;
                            vgaCount   <= 0;
                            memCounter <= 0;
                            state      <= game;
                        end if;
                    end if;
                when game =>
                    newRow <= '0';
                    if not flip then
                        address <= std_logic_vector(to_unsigned(startAddr + memCounter, address'length));
                        if startAddr + memCounter = 960 * 240 - 1 then
                            if memCounter /= 480 * 240 - 1 then
                                flip      <= true;
                                flipCount <= memCounter;
                            end if;
                        end if;
                    else
                        address <= std_logic_vector(to_unsigned(memCounter - flipCount - 1, address'length));
                    end if;
                    if active = '1' then
                        if HCounter = 200 - 1 then                                                           
                            ena     <= '1';                                                                  
                        end if;                                                                              
                        if HCounter > 200 - 1 and HCounter <= 440 - 1 then                                   
                            ena <= '1';
                            if memGameOut(11 downto 8) = x"9" and memGameOut(7  downto 4) = x"9" and memGameOut(3  downto 0) = x"9" then
                                r <= x"A";
                                g <= x"A";
                                b <= x"A"; 
                            else                                                             
                                r   <= memGameOut(11 downto 8);                                              
                                g   <= memGameOut(7  downto 4);                                              
                                b   <= memGameOut(3  downto 0);   
                            end if;                                           
                        else        
                            ena <= '0';                                                                         
                            r   <= "1000";                                                               
                            g   <= "1111";                                                               
                            b   <= "0101";                                                               
                        end if;
                        if prevClk25 = '0' and clk25 = '1' then
                            vgaCount <= vgaCount + 1;                                                            
                            HCounter <= HCounter + 1; 
                            if HCounter > 200 - 1 and HCounter <= 440 - 1 then 
                                if memCounter /= 480 * 240 - 1 then
                                    memCounter <= memCounter + 1;  
                                end if;                                                  
                            elsif HCounter = 640 -1 then
                                HCounter   <= 0;
                            end if;       
                            if vgaCount = 640 * 480 - 1 then
                                HCounter   <= 0;
                                vgaCount   <= 0;
                                memCounter <= 0;
                                flip       <= false;
                                if pixelN = 0 then
                                    if not isStarting then
                                        isStarting <= true;
                                    else
                                        newRow <= '1';
                                    end if;
                                    pixelNN := 47;
                                    if rowN = 0 then
                                        rowNN := 19;
                                    else
                                        rowNN := rowN - 1;
                                    end if;
                                else
                                    pixelNN := pixelN - 1;
                                end if;
                                pixelN <= pixelNN;
                                rowN   <= rowNN;
                                startAddr  <= (48 * rowNN + pixelNN) * 240;
                            end if;                                                                      
                        end if;
                    end if;
            end case;
            
        end if;
    end process;
    clkGame <= clk;

end behavioral;
