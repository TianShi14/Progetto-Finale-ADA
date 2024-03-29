library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity outputMaster is
    port(
        clk        : in  std_logic;
        clk25      : in  std_logic;
        startGame  : in  std_logic;
        active     : in  std_logic;
        endFrame   : in  std_logic;
        genFrame   : out std_logic;                            -- preparazione schermata successiva
        r, g, b    : out std_logic_vector(3 downto 0);
        -- segnali per mem Game
        clkGame    : out std_logic;                            -- specific clock for Start screen ROM, useful for clock masking                  
        address    : out std_logic_vector(17 downto 0);        -- mem Game address  
        memGameOut : in  std_logic_vector(11 downto 0);        -- data out Game mem 
        wena       : out std_logic_vector(0 to 0);
        ena        : out std_logic;
        
        newRow     : out std_logic;
        enable     : out std_logic;
        playerX    : in  natural;
        -- segnali per mem Angel
        dataAngel  : in  std_logic_vector(11 downto 0);
        addrAngel  : out std_logic_vector(12 downto 0);       
        enaAngel   : out std_logic;
        -----------------collisioni----------
        death      : in  std_logic;
        row        : out std_logic_vector(4  downto 0); 
        playerY    : out std_logic_vector(9  downto 0); 
        check      : out std_logic;
        multiple   : out std_logic;
        
        rst        : out std_logic                                                                                                               
    );
end outputMaster;

architecture behavioral of outputMaster is
    type msf is (start, transition, game, dead, reset);                     -- state types
    signal state        : msf := start;                              -- state machine 
    signal vgaCount     : integer range 0 to 640 * 480-1    := 0;    -- global counter
    signal memCounter   : integer range 0 to 480 * 240-1    := 0;    -- Mem counter  
    signal HCounter     : integer range 0 to 640 - 1        := 0;
    signal pixelN       : integer range 0 to 48 - 1         := 0; 
    signal rowN         : integer range 0 to 20 - 1         := 10;
    signal angelCount   : integer range 0 to 48 * 48 - 1    := 0;
    signal trCount      : integer range 0 to 10_000_000 - 1 := 0;
    signal deathCount   : integer range 0 to 240 * 48 - 1   := 0;
    signal startCount   : integer range 0 to 315 * 57 - 1   := 0;
    signal borderCount  : integer range 0 to 200 * 480      := 1;
    signal rowCount     : integer range 0 to 20 * 48 - 1    := 20 * 48 - 1;
    signal restart      : integer range 0 to 180 - 1        := 0;
    signal bigRow       : integer range 0 to 20 - 1         := 0;
    signal startAddr    : integer := 480 * 240;
    signal flipCount    : integer := 0;
    signal deadPosition : integer := 0;
    signal flip         : boolean := false;
    signal isStarting   : boolean := false;
    signal move         : boolean := false;
    signal lost         : boolean := false;
    signal prevClk25    : std_logic;
    
    -- death screen signals
    signal deathAddr : std_logic_vector(13 downto 0) := (others => '0');
    signal deathData : std_logic_vector(11 downto 0);
    signal deathEna  : std_logic;
    
    -- start screen signals
    signal initAddr  : std_logic_vector(14 downto 0) := (others => '0');
    signal initData  : std_logic_vector(11 downto 0);
    signal initEna   : std_logic;
    
    -- border screen signals
    signal borderAddr  : std_logic_vector(16 downto 0) := (others => '0');
    signal borderData  : std_logic_vector(11 downto 0);
    signal borderEna   : std_logic;
begin

    youDied: entity work.blk_mem_gen_5
    port map(
        clka          => clk,
        addra         => deathAddr,
        douta         => deathData,
        ena           => deathEna
    );
    
    startScreen: entity work.blk_mem_gen_6
    port map(
        clka          => clk,
        addra         => initAddr,
        douta         => initData,
        ena           => initEna
    );

    border: entity work.blk_mem_gen_7
    port map(
        clka          => clk,
        addra         => borderAddr,
        douta         => borderData,
        ena           => borderEna
    );

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
                    if active = '1' then
                        r <= x"4";
                        g <= x"6";
                        b <= x"7";
                        if vgaCount > 640 * 48 * 3 - 1 and vgaCount < 640 * (48 * 3 + 57) - 1 and HCounter >= 161 - 1 and HCounter <= 161 + 315 - 1 then
                            initEna  <= '1';
                            initAddr <= std_logic_vector(to_unsigned(startCount, initAddr'length));
                            if HCounter /= 161 - 1 then
                                r <= initData(11 downto 8);
                                g <= initData(7  downto 4);
                                b <= initData(3  downto 0);
                            end if;
                        else
                            initEna  <= '0';
                        end if;
                        if prevClk25 = '0' and clk25 = '1' then
                            if vgaCount > 640 * 48 * 3 - 1 and vgaCount < 640 * (48 * 3 + 57) - 1 and HCounter >= 161 - 1 and HCounter < 161 + 315 - 1 then
                                startCount <= startCount + 1;
                            end if;
                            vgaCount <= vgaCount + 1;                                                            
                            HCounter <= HCounter + 1; 
                            if HCounter = 640 -1 then
                                HCounter   <= 0;
                            end if;       
                            if vgaCount = 640 * 480 - 1 then
                                HCounter   <= 0;
                                vgaCount   <= 0;
                                startCount <= 0;
                                if startGame = '1' then
                                    state     <= transition;
                                    genFrame  <= '1';
                                    enable    <= '1';
                                end if;
                            end if;                                                                      
                        end if;
                    end if;
                when transition =>
                    enable   <= '0';
                    genFrame <= '0';
                    r <= x"4";
                    g <= x"6";
                    b <= x"7";
                    if timeCount < 100_000_000 then  
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
                    check     <= '0';
                    multiple  <= '1';
                    newRow    <= '0';
                    borderEna <= '0';
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
                        if memCounter > 240 * 48 * 9 - 1 and HCounter >= playerX + 200 - 1 and HCounter < playerX + 200 + 48 - 1 then
                            enaAngel  <= '1';
                            if move then 
                                addrAngel <= std_logic_vector(to_unsigned(angelCount, addrAngel'length));
                            else
                                addrAngel <= std_logic_vector(to_unsigned(48 * 48 + angelCount, addrAngel'length));
                            end if;
                        else
                            enaAngel  <= '0';
                        end if;
                        if HCounter < 200 - 1 or HCounter >= 440 - 1 then
                            borderAddr <= std_logic_vector(to_unsigned(borderCount, borderAddr'length));
                            borderEna <= '1';
                        else
                            borderEna <= '0';
                        end if;
                        if HCounter = 200 - 1 then                                                           
                            ena     <= '1';                                                                  
                        end if;                                                                              
                        if HCounter > 200 - 1 and HCounter <= 440 - 1 then                                   
                            ena <= '1';
                            if memCounter > 240 * 48 * 9 - 1 and HCounter >= playerX + 200 and HCounter < playerX + 200 + 48 
                            and dataAngel /= x"D15" then
                                r <= dataAngel(11 downto 8);
                                g <= dataAngel(7  downto 4);
                                b <= dataAngel(3  downto 0);
                            else 
                                if memGameOut(11 downto 8) = x"9" and memGameOut(7 downto 4) = x"9" and memGameOut(3 downto 0) = x"9" then
                                    r   <= x"A";
                                    g   <= x"A";
                                    b   <= x"A"; 
                                else                                                             
                                    r   <= memGameOut(11 downto 8);                                              
                                    g   <= memGameOut(7  downto 4);                                              
                                    b   <= memGameOut(3  downto 0);   
                                end if;
                            end if;                                           
                        else        -- verde
                            ena        <= '0';    
                                                                                            
                            r   <= borderData(11 downto 8);                                                               
                            g   <= borderData(7  downto 4);                                                               
                            b   <= borderData(3  downto 0);                                                               
                        end if;
                        if prevClk25 = '0' and clk25 = '1' then
                            if trCount >= 10_000_000 - 1 then
                                move    <= not move;
                                trCount <= 0;
                            else
                                trCount <= trCount + 1;
                            end if;
                            if memCounter > 240 * 48 * 9 - 1 and HCounter >= playerX + 200 - 1 and HCounter < playerX + 200 + 48 - 1 then -------
                                angelCount <= angelCount + 1;
                            end if;
                            if HCounter < 200 - 1 or HCounter >= 440 - 2 then
                                borderCount <= borderCount + 1;
                                if HCounter = 440 - 2 then
                                    borderCount <= borderCount - 200;
                                end if;
                                if borderCount = 200 * 480 - 1 and HCounter > 440 then
                                    borderCount <= 0;
                                end if;
                            end if;
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
                                angelCount <= 0;
                                flip       <= false;
                                
                                if not lost then
                                    if pixelN = 0 then
                                        if not isStarting then
                                            isStarting <= true;
                                        else
                                            newRow <= '1';
                                            if bigRow = 20 - 1 then
                                                bigRow <= 0;
                                            else 
                                                bigRow <= bigRow + 1;
                                            end if;
                                            multiple <= '0';
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
                                    if rowCount = 0 then
                                        rowCount <= 960 - 1;
                                    else
                                        rowCount <= rowCount - 1;
                                    end if;
                                    -- parte dedicata alle collisioni ----------------------
                                    
                                    playerY  <= std_logic_vector(to_unsigned(rowCount, playerY'length));
                                    row      <= std_logic_vector(to_unsigned(bigRow, row'length));
                                    check    <= '1';
                                    --------------------------------------------------------
                                    pixelN <= pixelNN;
                                    rowN   <= rowNN;
                                    startAddr  <= (48 * rowNN + pixelNN) * 240;
                                else
                                    state        <= dead;
                                    deadPosition <= playerX;
                                end if;
                            end if;                                                                      
                        end if;
                    end if;
                when dead =>
                    check    <= '0';
                    multiple <= '1';
                    newRow   <= '0';
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
                        if memCounter > 240 * 48 * 9 - 1 and HCounter >= deadPosition + 200 - 1 and HCounter < deadPosition + 200 + 48 - 1 then
                            enaAngel  <= '1';
                            if move then 
                                addrAngel <= std_logic_vector(to_unsigned(angelCount, addrAngel'length));
                            else
                                addrAngel <= std_logic_vector(to_unsigned(48 * 48 + angelCount, addrAngel'length));
                            end if;
                        else
                            enaAngel  <= '0';
                        end if;
                        if memCounter > 240 * 48 * 4 - 1 and memCounter < 240 * 48 * 5 and HCounter >= 200 - 1 and HCounter < 440 - 1 then
                            deathEna  <= '1';
                            deathAddr <= std_logic_vector(to_unsigned(deathCount, deathAddr'length));
                        else
                            deathEna <= '0';
                        end if;
                        if HCounter < 200 - 1 or HCounter >= 440 - 1 then
                            borderAddr <= std_logic_vector(to_unsigned(borderCount, borderAddr'length));
                            borderEna <= '1';
                        else
                            borderEna <= '0';
                        end if;
                        if HCounter = 200 - 1 then                                                           
                            ena     <= '1';                                                                  
                        end if;                                                                              
                        if HCounter > 200 - 1 and HCounter <= 440 - 1 then                                   
                            ena <= '1';
                            if memCounter > 240 * 48 * 9 - 1 and HCounter >= deadPosition + 200 and HCounter < deadPosition + 200 + 48 
                            and dataAngel /= x"D15" then
                                r <= dataAngel(11 downto 8);
                                g <= dataAngel(7  downto 4);
                                b <= dataAngel(3  downto 0);
                            else 
                                if memCounter > 240 * 48 * 4 - 1 and memCounter < 240 * 48 * 5 then
                                    r <= deathData(11 downto 8);
                                    g <= deathData(7  downto 4);
                                    b <= deathData(3  downto 0);
                                else
                                    if memGameOut(11 downto 8) = x"9" and memGameOut(7 downto 4) = x"9" and memGameOut(3 downto 0) = x"9" then
                                        r   <= x"A";
                                        g   <= x"A";
                                        b   <= x"A"; 
                                    else                                                             
                                        r   <= memGameOut(11 downto 8);                                              
                                        g   <= memGameOut(7  downto 4);                                              
                                        b   <= memGameOut(3  downto 0);   
                                    end if;
                                end if;
                            end if;                                           
                        else        -- verde
                            ena <= '0';
                                                                                                     
                            r   <= borderData(11 downto 8);                                                               
                            g   <= borderData(7  downto 4);                                                               
                            b   <= borderData(3  downto 0);                                                                
                        end if;
                        if prevClk25 = '0' and clk25 = '1' then
                            if memCounter > 240 * 48 * 9 - 1 and HCounter >= deadPosition + 200 - 1 and HCounter < deadPosition + 200 + 48 - 1 then -------
                                angelCount <= angelCount + 1;
                            end if;
                            if memCounter > 240 * 48 * 4 - 1 and memCounter < 240 * 48 * 5 and HCounter >= 200 - 1 and HCounter < 440 - 1 then
                                deathCount <= deathCount + 1;
                            end if;
                            if HCounter < 200 - 1 or HCounter >= 440 - 2 then
                                borderCount <= borderCount + 1;
                                if HCounter = 440 - 2 then
                                    borderCount <= borderCount - 200;
                                end if;
                                if borderCount = 200 * 480 - 1 and HCounter > 440 then
                                    borderCount <= 0;
                                end if;
                            end if;
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
                                angelCount <= 0;
                                deathCount <= 0;
                                flip       <= false;
                                if restart /= 180 - 1 then
                                    restart      <= restart + 1;
                                else
                                    state        <= reset;                      
                                    vgaCount     <= 0;    
                                    memCounter   <= 0;    
                                    HCounter     <= 0;          
                                    pixelN       <= 0;          
                                    rowN         <= 10;         
                                    angelCount   <= 0;          
                                    trCount      <= 0;          
                                    deathCount   <= 0;          
                                    startCount   <= 0;          
                                    borderCount  <= 1;          
                                    rowCount     <= 20 * 48 - 1;
                                    restart      <= 0;          
                                    bigRow       <= 0;          
                                    startAddr    <= 480 * 240;                            
                                    flipCount    <= 0;                                    
                                    deadPosition <= 0;                                    
                                    flip         <= false;                                
                                    isStarting   <= false;                                
                                    move         <= false;                                
                                    lost         <= false;
                                    deathEna     <= '0';
                                    initEna      <= '0';
                                    borderEna    <= '0';
                                    
                                    genFrame     <= '0';
                                    ena          <= '0';
                                    newRow       <= '0';
                                    enable       <= '0';
                                    enaAngel     <= '0';
                                    check        <= '0';
                                    multiple     <= '0';  
                                    row          <= (others => '0'); 
                                    playerY      <= (others => '0');                                                  
                                end if;
                            end if;                                                                      
                        end if;
                    end if;
                when reset => 
                    if trCount = 10_000_000 - 1 then
                        rst     <= '0';
                        trCount <= 0;
                        state   <= start;
                    else
                        trCount <= trCount + 1;
                        rst     <= '1';
                    end if;
            end case;
            if death = '1' then
                lost <= true;
            end if;
        end if;
    end process;
    clkGame <= clk;

end behavioral;