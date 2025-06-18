library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_generator is
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        prtcl_on_off : in std_logic;
        prtcl_valid : in std_logic;
        src_mac : in std_logic_vector(47 downto 0);
        dst_mac : in std_logic_vector(47 downto 0);
        prtcl_type : in std_logic_vector (15 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        tready : in std_logic;
        tdata : out std_logic_vector(7 downto 0);
        tvalid : out std_logic;
        tlast : out std_logic;
        prtcl_en : out std_logic;
        start_dbg : out std_logic;
        state_dbg : out std_logic_vector(3 downto 0);
        count_dbg : out std_logic_vector(5 downto 0)
    );
end ethernet_generator;

architecture Behavioral of ethernet_generator is
constant mac_length : integer := 6;
constant type_field_length : integer := 2;
constant padding_length : integer := 11;
type mac_array is array (0 to mac_length-1) of std_logic_vector(7 downto 0);
type type_array is array (0 to type_field_length-1) of std_logic_vector(7 downto 0);

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

-- FSM states
type FSM is (
    WAITING,
    START,
    LOAD,
    DESTINATION_MAC, 
    SOURCE_MAC,
    TYPE_FIELD,
    ENABLE_PROTOCOL,
    DATA,
    PADDING,
    DONE,
    RESET
);
signal state, next_state : FSM := WAITING;
type state_code_array is array (FSM) of std_logic_vector(3 downto 0);

constant state_code : state_code_array := (
    WAITING         => "0001",
    START           => "0010",
    LOAD            => "0011",
    DESTINATION_MAC => "0100",
    SOURCE_MAC      => "0101",
    TYPE_FIELD      => "0110",
    ENABLE_PROTOCOL => "0111",
    DATA            => "1000",
    PADDING         => "1001",
    DONE            => "1010",
    RESET           => "1011"
);

-- Begin: Timer control signals
signal en_timer_s : std_logic := '0';
signal rst_timer_s : std_logic := '1';
signal done_timer_s : std_logic;
-- End: Timer control signals

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
            state <= RESET;
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
        when WAITING =>
            if (done_timer_s = '1') then
                next_state <= START;
            else
                next_state <= WAITING;
            end if;
        when START =>
            next_state <= LOAD;
        when LOAD =>
            next_state <= DESTINATION_MAC;
        when DESTINATION_MAC =>
            if (tready = '1' and counter = mac_length-1) then
                next_state <= SOURCE_MAC;
            else
                next_state <= DESTINATION_MAC;
            end if;
        when SOURCE_MAC =>
            if (tready = '1' and counter = mac_length-1) then
                next_state <= TYPE_FIELD;
            else
                next_state <= SOURCE_MAC;
            end if;
        when TYPE_FIELD =>
            if (tready = '1' and counter = type_field_length-1) then
                next_state <= ENABLE_PROTOCOL;
            else
                next_state <= TYPE_FIELD;
            end if;
        when ENABLE_PROTOCOL =>
            if (tready = '1' and prtcl_on_off = '1') then
                next_state <= DATA;
            else
                next_state <= ENABLE_PROTOCOL;
            end if;
        when DATA =>
            if (tready = '1' and prtcl_on_off = '0') then
                next_state <= PADDING;
            else
                next_state <= DATA;
            end if;
        when PADDING =>
            if (tready = '1' and counter = padding_length-1) then
                next_state <= DONE;
            else
                next_state <= PADDING;
            end if;
        when DONE =>
            next_state <= WAITING;
        when RESET =>
            next_state <= WAITING;
        when others =>
            next_state <= WAITING;        
    end case;
end process;
-- End: Next state logic

-- Begin: Output logic
process(clk)
begin
    if (rising_edge(clk)) then
        if (tready = '1') then
            tlast <= '0';
            prtcl_en <= '0';
            start_dbg <= '1';
            
            case state is
                when WAITING =>                    
                    tvalid <= '0';
                    tdata <= (others => '0');
                
                when START =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                
                when LOAD =>
                    dst_mac_s <= (dst_mac(47 downto 40), dst_mac(39 downto 32), dst_mac(31 downto 24), dst_mac(23 downto 16), dst_mac(15 downto 8), dst_mac(7 downto 0));
                    src_mac_s <= (src_mac(47 downto 40), src_mac(39 downto 32), src_mac(31 downto 24), src_mac(23 downto 16), src_mac(15 downto 8), src_mac(7 downto 0)); 
                    prtcl_type_s <= (prtcl_type(15 downto 8), prtcl_type(7 downto 0));
                    
                    tvalid <= '0';
                    tdata <= (others => '0');
                
                when DESTINATION_MAC =>
                    tvalid <= '1';
                    tdata <= dst_mac_s(counter);
                    
                when SOURCE_MAC =>
                    tvalid <= '1';
                    tdata <= src_mac_s(counter);
                    
                when TYPE_FIELD =>
                    tvalid <= '1';
                    tdata <= prtcl_type_s(counter);
                    
                when ENABLE_PROTOCOL =>
                    tvalid <= '0';
                    prtcl_en <= '1';
                    tdata <= (others => '0');
                    
                when DATA =>
                    tvalid <= prtcl_valid;
                    prtcl_en <= '1';
                    tdata <= data_in;
                    
                when PADDING =>
                    tvalid <= '1';
                    tdata <= x"00";
                    
                    if (counter = padding_length-1) then
                        tlast <= '1';
                    end if;
                    
                when DONE =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    start_dbg <= '0';
                    
                when RESET =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    start_dbg <= '0';
                    
                when others =>
                    tvalid <= '0';
                    tdata <= (others => '0');
                    start_dbg <= '0';
            end case;
        else
            tvalid <= '0';
            tdata <= (others => '0');
            tlast <= '0';
            prtcl_en <= '0';
            
            start_dbg <= '0';
        end if;
        
        state_dbg <= state_code(state);
    end if;
end process;
-- End: Output logic

-- Begin: Timer logic
process (state)
begin
    case state is
        when WAITING =>
            en_timer_s <= '1';
            rst_timer_s <= '1';
        when others =>
            en_timer_s <= '0';
            rst_timer_s <= '0';
     end case;
end process;
-- End: Timer logic

-- Begin: Counter logic
process (clk)
begin
    if (rising_edge(clk)) then
        if (tready = '1') then
            case state is
                when DESTINATION_MAC | SOURCE_MAC =>
                    if (counter = mac_length-1) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                when TYPE_FIELD => 
                    if (counter = type_field_length-1) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                when PADDING =>
                    if (counter = padding_length-1) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                when others =>
                    counter <= 0;
            end case;
        end if;
    end if;
end process;
-- End: Counter logic

-- Debug signal
count_dbg <= std_logic_vector(to_unsigned(counter, 6));

end Behavioral;