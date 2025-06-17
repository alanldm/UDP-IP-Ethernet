library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_generator is
    Port ( 
        clk : in std_logic;                         -- System clock input (125 MHz for Ethernet)
        rst : in std_logic;                         -- Synchronous reset (active low)
        prtcl_on_off : in std_logic;
        src_mac : in std_logic_vector(47 downto 0);
        dst_mac : in std_logic_vector(47 downto 0);
        prtcl_type : in std_logic_vector (15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        tready : in std_logic;                       -- Downstream ready signal (AXI-Stream handshake)
        tdata : out std_logic_vector(7 downto 0);    -- Output data byte (AXI-Stream bus)
        tvalid : out std_logic;                      -- Data valid signal (AXI-Stream handshake)
        tlast : out std_logic;                       -- Indicates the last byte of a packet/frame (AXI-Stream)
        prtcl_en : out std_logic;
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
        en : in std_logic;
        done : out std_logic
    );
end component;
-- End: Timer component declaration

-- Begin: Timer control signals
signal en_timer_s : std_logic := '0'; -- Enables the timer counting process when set to '1'
signal rst_timer_s : std_logic := '1';    -- Synchronous reset for the timer (active low)
signal done_timer_s : std_logic;         -- Pulse output from the timer
-- End: Timer control signals

-- FSM states
type FSM is (
    IDLE, 
    DESTINATION_MAC, 
    SOURCE_MAC, 
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
signal dst_mac_s, src_mac_s : mac_array;
signal prtcl_type_s : type_array;

begin

-- Begin: Timer instantiation
inst_timer : timer generic map (125) port map (
    clk => clk,
    rst => rst_timer_s,
    en => en_timer_s,
    done => done_timer_s
);
-- End: Timer instantiation

-- Begin: State register logic
process (clk)
begin
    if (rising_edge(clk)) then
        if (rst = '0') then
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
            if (done_timer_s = '1') then
                next_state <= DESTINATION_MAC;
            else
                next_state <= IDLE;
            end if;
        when DESTINATION_MAC =>
            if (tready = '1' and counter = 5) then
                next_state <= SOURCE_MAC;
            else
                next_state <= DESTINATION_MAC;
            end if;
        when SOURCE_MAC =>
            if (tready = '1' and counter = 5) then
                next_state <= TYPE_FIELD;
            else
                next_state <= SOURCE_MAC;
            end if;
        when TYPE_FIELD =>
            if (tready = '1' and counter = 1) then
                next_state <= ENABLE_IP;
            else
                next_state <= TYPE_FIELD;
            end if;
        when ENABLE_IP =>
            if (tready = '1' and prtcl_on_off = '1') then
                next_state <= DATA;
            else
                next_state <= ENABLE_IP;
            end if;
        when DATA =>
            if (tready = '1' and prtcl_on_off = '0') then
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
        if (rst = '0') then
            tvalid <= '0';
            tdata <= (others => '0');
            tlast <= '0';
            counter <= 0;
            prtcl_en <= '0';
        elsif (tready = '1') then
            case state is
                when IDLE =>
                    dst_mac_s <= (dst_mac(47 downto 40), dst_mac(39 downto 32), dst_mac(31 downto 24), dst_mac(23 downto 16), dst_mac(15 downto 8), dst_mac(7 downto 0));
                    src_mac_s <= (src_mac(47 downto 40), src_mac(39 downto 32), src_mac(31 downto 24), src_mac(23 downto 16), src_mac(15 downto 8), src_mac(7 downto 0)); 
                    prtcl_type_s <= (prtcl_type(15 downto 8), prtcl_type(7 downto 0));
                    
                    
                    tvalid <= '0';
                    tdata <= (others => '0');
                    tlast <= '0';
                    counter <= 0;
                    prtcl_en <= '0';
                    
                when DESTINATION_MAC =>
                    tvalid <= '1';
                    tdata <= dst_mac_s(counter);
                    tlast <= '0';
                    prtcl_en <= '0';
                    
                    if (counter = 5) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                    
                when SOURCE_MAC =>
                    tvalid <= '1';
                    tdata <= src_mac_s(counter);
                    tlast <= '0';
                    prtcl_en <= '0';
                    
                    if (counter = 5) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                    
                when TYPE_FIELD =>
                    tvalid <= '1';
                    tdata <= prtcl_type_s(counter);
                    tlast <= '0';
                    prtcl_en <= '0';
                    
                    if (counter = 1) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                    
                when ENABLE_IP =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    tlast <= '0';
                    prtcl_en <= '1';
                    counter <= 0;
                    
                when DATA =>
                    tvalid <= '1';
                    tdata <= data_in;
                    tlast <= '0';
                    prtcl_en <= '1';
                    counter <= 0;
                    
                when PADDING =>
                    tvalid <= '1';
                    tdata <= x"00";
                    prtcl_en <= '0';
                    
                    if (counter = 63) then
                        tlast <= '1';
                        counter <= 0;
                    else
                        counter <= counter + 1;
                        tlast <= '0';
                    end if;
                when DONE =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    tlast <= '0';
                    counter <= 0;
                    prtcl_en <= '0';
                    
                when others =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    tlast <= '0';
                    counter <= 0;
                    prtcl_en <= '0';
            end case;
        else
            tvalid <= '0';
            tdata <= (others => '0');
            tlast <= '0';
            prtcl_en <= '0';
        end if;
    end if;

end process;
-- End: Output logic

process (state)
begin
    case state is
        when IDLE =>
            en_timer_s <= '1';
            rst_timer_s <= '1';
        when OTHERS =>
            en_timer_s <= '0';
            rst_timer_s <= '0';
     end case;
end process;

-- Debug signal
count <= std_logic_vector(to_unsigned(counter, 6));

end Behavioral;