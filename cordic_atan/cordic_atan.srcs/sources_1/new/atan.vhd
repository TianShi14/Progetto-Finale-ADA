library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity atan is
    port(
        enable       : in     std_logic;
        clk          : in     std_logic;
        x_value      : in     std_logic_vector(15 downto 0);
        y_value      : in     std_logic_vector(15 downto 0);
        reset        : out    std_logic;
        thresholds   : out    std_logic_vector(3 downto 0)
    );
end atan;

architecture behavioral of atan is

--definizione tipo per lo stato
type state_type is (waits, load);
--definizione segnali di stato presente e futuro
signal present_state, next_state : state_type := waits;

signal xy_tvalid    : std_logic;
signal angle_tvalid : std_logic;
signal buffer_angle : std_logic_vector(7 downto 0);

begin
    cordic: entity work.cordic_0
        port map(
            aclk                                 => clk,
            s_axis_cartesian_tdata(31 downto 16) => x_value,
            s_axis_cartesian_tdata(15 downto 0)  => y_value,
            s_axis_cartesian_tvalid              => xy_tvalid,
            m_axis_dout_tdata                    => buffer_angle,
            m_axis_dout_tvalid                   => angle_tvalid,
            aresetn                              => reset
        );
    --PROCESSO SEQUENZIALE sensibile a clk
    seq: process (clk) is
    begin
        if rising_edge(clk) then
            present_state <= next_state;
        end if;
    end process seq;    
    --PROCESSO DELLO STATO FUTURO sensibile a present_state, enable e angle_tvalid
    fut: process (present_state, enable, angle_tvalid) is
    begin
        next_state <= present_state;
        case present_state is 
            when waits =>
                if enable = '1' then
                    next_state <= load;
                else 
                    next_state <= waits;
                end if;
            when load =>
                if angle_tvalid = '1' then
                    thresholds <= (others => '0');
                    if signed(buffer_angle) >= 0 then
                        if signed(buffer_angle) <= 16 then
                            thresholds(0) <= '1';
                        else
                            thresholds(1) <= '1';
                        end if;
                    else 
                        if signed(buffer_angle) <= -16 then
                            thresholds(2) <= '1';
                        else
                            thresholds(3) <= '1';
                        end if;
                    end if;
                    next_state <= waits;
                else
                    next_state <= load;
                end if;
         end case;
    end process fut;
    --PROCESSO CONTROLLO USCITE 
    exits: process (present_state) is
    begin
        --STATO WAITS
        case present_state is 
            when waits =>
                xy_tvalid <= '0';
            when load => 
                xy_tvalid <= '1';
        end case;
    end process exits; 

end behavioral;