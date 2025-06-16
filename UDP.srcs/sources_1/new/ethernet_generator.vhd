library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_generator is
    Port ( 
        clk : in std_logic;                          -- System clock input (125 MHz for Ethernet)
        reset : in std_logic;                        -- Synchronous reset (active low)
        startIP : in std_logic;
        busIP : in std_logic_vector(7 downto 0);
        tready : in std_logic;                       -- Downstream ready signal (AXI-Stream handshake)
        tdata : out std_logic_vector(7 downto 0);    -- Output data byte (AXI-Stream bus)
        tvalid : out std_logic;                      -- Data valid signal (AXI-Stream handshake)
        tlast : out std_logic;                       -- Indicates the last byte of a packet/frame (AXI-Stream)
        enIP : out std_logic;
        count : out std_logic_vector(5 downto 0)     -- Debug: byte counter (sent bytes)
    );
end ethernet_generator;

architecture Behavioral of ethernet_generator is
-- Begin: Timer component declaration
component timer is
    Generic(
        N : integer := 125000000
    );
    Port( 
        clk : in std_logic;
        rst : in std_logic;
        enable : in std_logic;
        start : out std_logic
    );
end component;
-- End: Timer component declaration

-- Begin: Timer control signals
signal enable_s : std_logic := '0'; -- Enables the timer counting process when set to '1'
signal rst_s : std_logic := '1';    -- Synchronous reset for the timer (active low)
signal start_s : std_logic;         -- Pulse output from the timer
-- End: Timer control signals

-- FSM states
type FSM is (
    IDLE, 
    DEST_MAC, 
    SRC_MAC, 
    TYPE_FIELD,
    ENABLE_IP,
    DATA, 
    PADDING, 
    DONE
);
signal state, next_state : FSM := IDLE;                                 -- Current and next state signals

type mac_array is array (0 to 5) of std_logic_vector(7 downto 0);       -- MAC address type (6 Bytes)
type type_array is array (0 to 1) of std_logic_vector(7 downto 0);      -- Protocol type (2 Bytes)

signal counter : integer := 0;
signal destination_mac : mac_array := (x"FF", x"FF", x"FF", x"FF", x"FF", x"FF");
signal source_mac : mac_array := (x"00", x"0A", x"35", x"00", x"00", x"01");
signal ethernet_type : type_array := (x"08", x"00");

begin

-- Begin: Timer instantiation
inst_timer : timer generic map (1250) port map (
    clk => clk,
    rst => rst_s,
    enable => enable_s,
    start => start_s
);
-- End: Timer instantiation

-- Begin: State register logic
process (clk)
begin
    if (rising_edge(clk)) then
        if (reset = '0') then
            state <= IDLE;
        else
            state <= next_state;
        end if;
    end if;

end process;
-- End: State register

-- Begin: Next state logic
process (state, counter, tready)
begin
    case state is
        when IDLE =>
            if (start_s = '1') then
                next_state <= DEST_MAC;
            else
                next_state <= IDLE;
            end if;
        when DEST_MAC =>
            if (tready = '1' and counter = 5) then
                next_state <= SRC_MAC;
            else
                next_state <= DEST_MAC;
            end if;
        when SRC_MAC =>
            if (tready = '1' and counter = 5) then
                next_state <= TYPE_FIELD;
            else
                next_state <= SRC_MAC;
            end if;
        when TYPE_FIELD =>
            if (tready = '1' and counter = 1) then
                next_state <= ENABLE_IP;
            else
                next_state <= TYPE_FIELD;
            end if;
        when ENABLE_IP =>
            if (tready = '1' and startIP = '1') then
                next_state <= DATA;
            else
                next_state <= ENABLE_IP;
            end if;
        when DATA =>
            if (tready = '1' and startIP = '0') then
                next_state <= PADDING;
            else
                next_state <= DATA;
            end if;
        when PADDING =>
            if (tready = '1' and counter = 63) then
                next_state <= DONE;
            else
                next_state <= PADDING;
            end if;
        when DONE =>
            next_state <= IDLE;
        when others =>
            next_state <= IDLE;        
    end case;
end process;
-- End: Next state logic

-- Begin: Output logic
process(clk)
begin
    if (rising_edge(clk)) then
        if (reset = '0') then
            tvalid <= '0';
            tdata <= (others => '0');
            tlast <= '0';
            counter <= 0;
            enIP <= '0';
            
            enable_s <= '0';
            rst_s <= '0';
        elsif (tready = '1') then
            case state is
                when IDLE =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    tlast <= '0';
                    counter <= 0;
                    enIP <= '0';
                    
                    enable_s <= '1';
                    rst_s <= '1';
                when DEST_MAC =>
                    tvalid <= '1';
                    tdata <= destination_mac(counter);
                    tlast <= '0';
                    enIP <= '0';
                    
                    if (counter = 5) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                    
                    enable_s <= '0';
                    rst_s <= '0';
                when SRC_MAC =>
                    tvalid <= '1';
                    tdata <= source_mac(counter);
                    tlast <= '0';
                    enIP <= '0';
                    
                    if (counter = 5) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                    
                    enable_s <= '0';
                    rst_s <= '0';
                when TYPE_FIELD =>
                    tvalid <= '1';
                    tdata <= ethernet_type(counter);
                    tlast <= '0';
                    enIP <= '0';
                    
                    if (counter = 1) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                    
                    enable_s <= '0';
                    rst_s <= '0';
                when ENABLE_IP =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    tlast <= '0';
                    enIP <= '1';
                    counter <= 0;
                    
                    enable_s <= '0';
                    rst_s <= '0';
                when DATA =>
                    tvalid <= '1';
                    tdata <= busIP;
                    tlast <= '0';
                    enIP <= '1';
                    counter <= 0;
                    
                    enable_s <= '0';
                    rst_s <= '0';
                when PADDING =>
                    tvalid <= '1';
                    tdata <= x"00";
                    enIP <= '0';
                    
                    if (counter = 63) then
                        tlast <= '1';
                        counter <= 0;
                    else
                        counter <= counter + 1;
                        tlast <= '0';
                    end if;
                    
                    enable_s <= '0';
                    rst_s <= '0';
                when DONE =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    tlast <= '0';
                    counter <= 0;
                    enIP <= '0';
                    
                    enable_s <= '0';
                    rst_s <= '0';
                when others =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    tlast <= '0';
                    counter <= 0;
                    enIP <= '0';
                    
                    enable_s <= '0';
                    rst_s <= '0';
            end case;
        else
            tvalid <= '0';
            tdata <= (others => '0');
            tlast <= '0';
            enIP <= '0';
            
            enable_s <= '0';
            rst_s <= '0';
        end if;
    end if;

end process;
-- End: Output logic

-- Debug signal
count <= std_logic_vector(to_unsigned(counter, 6));

end Behavioral;