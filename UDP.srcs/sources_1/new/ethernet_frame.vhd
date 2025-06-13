library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ethernet_frame is
    Port ( 
        clk : in std_logic;
        reset : in std_logic;
        tready : in std_logic;
        tdata : out std_logic_vector(7 downto 0);
        tvalid : out std_logic;
        tlast : out std_logic        
    );
end ethernet_frame;

architecture Behavioral of ethernet_frame is
type FSM is (IDLE, DEST_MAC, SRC_MAC, TYPE_FIELD, DATA, DONE);
type mac_array is array (0 to 5) of std_logic_vector(7 downto 0);
type type_array is array (0 to 1) of std_logic_vector(7 downto 0);
type payload_array is array (0 to 7) of std_logic_vector(7 downto 0);
signal state, next_state : FSM := IDLE;

signal counter : integer := 0;
signal destination_mac : mac_array := (x"FF", x"FF", x"FF", x"FF", x"FF", x"FF"); 
signal source_mac : mac_array := (x"00", x"0A", x"35", x"00", x"00", x"01");
signal ethernet_type : type_array := (x"08", x"00");
signal payload : payload_array := (x"01", x"02",x"03", x"04", x"05", x"06", x"07", x"08");

begin

--Changing to the next state
process (clk)
begin
    if (rising_edge(clk)) then
        if (reset = '1') then
            state <= IDLE;
        else
            state <= next_state;
        end if;
    end if;

end process;

--Selecting the next state
process (state, counter, tready)
begin
    case state is
        when IDLE =>
            next_state <= DEST_MAC;
        when DEST_MAC =>
            if tready = '1' and counter = 5 then
                next_state <= SRC_MAC;
            end if;
        when SRC_MAC =>
            if tready = '1' and counter = 5 then
                next_state <= TYPE_FIELD;
            end if;
        when TYPE_FIELD =>
            if tready = '1' and counter = 1 then
                next_state <= DATA;
            end if;
        when DATA =>
            if tready = '1' and counter = 7 then
                next_state <= DONE;
            end if;
        when DONE =>
            next_state <= IDLE;
        when others =>
            next_state <= IDLE;        
    end case;

end process;

--Outputs value for each state
process(clk)
begin
    if (rising_edge(clk)) then
        if (reset = '1') then
            counter <= 0;
            tvalid <= '0';
            tdata <= (others => '0');
            tlast <= '0';
        elsif (tready = '1') then
            case state is
                when DEST_MAC =>
                    tdata <= destination_mac(counter);
                    tvalid <= '1';
                    tlast <= '0';
                    
                    if (counter = 5) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                when SRC_MAC =>
                    tdata <= source_mac(counter);
                    tvalid <= '1';
                    tlast <= '0';
                    
                    if (counter = 5) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if; 
                when TYPE_FIELD =>
                    tdata <= ethernet_type(counter);
                    tvalid <= '1';
                    tlast <= '0';
                    
                    if (counter = 1) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if; 
                when DATA =>
                    tdata <= payload(counter);
                    tvalid <= '1';
                    
                    if (counter = 7) then
                        tlast <= '1';
                        counter <= 0;
                    else
                        counter <= counter + 1;
                        tlast <= '0';
                    end if;
                when others =>
                    tvalid <= '0';
                    tlast <= '0';
                    tdata <= (others => '0');
                    counter <= 0;
            end case;
        end if;
    end if;

end process;

end Behavioral;
