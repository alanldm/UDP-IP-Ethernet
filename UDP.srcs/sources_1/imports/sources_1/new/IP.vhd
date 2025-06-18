library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IP is
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        src_ip : in std_logic_vector(31 downto 0);
        dst_ip : in std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        on_off : out std_logic;
        valid : out std_logic;
        state_dbg : out std_logic_vector(4 downto 0)
    );
end IP;

architecture Behavioral of IP is
type FSM is (
    START,
    LOAD,
    VERSION,
    SERVICE,
    LENGTH,
    ID,
    FLAGS,
    TTL,
    PROTOCOL,
    CHECKSUM,
    SOURCE_IP,
    DESTINATION_IP,
    DATA,
    RESET,
    DONE
);
signal state, next_state : FSM := START;
signal counter : integer := 0;
constant ip_length : integer := 4;
constant two_bytes : integer := 2;

type state_code_array is array (FSM) of std_logic_vector(4 downto 0);

constant state_code : state_code_array := (
    START           => "00001",
    LOAD            => "00010",
    VERSION         => "00011",
    SERVICE         => "00100",
    LENGTH          => "00101",
    ID              => "00110",
    FLAGS           => "00111",
    TTL             => "01000",
    PROTOCOL        => "01001",
    CHECKSUM        => "01010",
    SOURCE_IP       => "01011",
    DESTINATION_IP  => "01100",
    DATA            => "10000",
    RESET           => "01101",
    DONE            => "01111",
    others          => "00000"
);

type twoBytes is array (0 to two_bytes-1) of std_logic_vector (7 downto 0);
type fourBytes is array (0 to ip_length-1) of std_logic_vector (7 downto 0);

type udp is array (0 to 18) of std_logic_vector(7 downto 0);
signal udp_s : udp := (x"04", x"D2", x"16", x"78", x"00", x"1E", x"00", x"00", x"48", x"65", x"6C", x"6C", x"6F", x"20", x"57", x"6F", x"72", x"6C", x"64");

signal version_s : std_logic_vector (7 downto 0) := x"45";
signal service_s : std_logic_vector (7 downto 0) := x"00";
signal length_s : twoBytes := (x"00", x"32");
signal id_s : twoBytes := (x"00", x"01");
signal flag_s : twoBytes := (x"40", x"00");
signal ttl_s : std_logic_vector (7 downto 0) := x"40";
signal protocol_s : std_logic_vector (7 downto 0) := x"11";
signal checksum_s : twoBytes := (x"B7", x"59");
signal src_ip_s : fourBytes;
signal dst_ip_s : fourBytes; 

begin

process (clk)
begin
    if (rising_edge(clk)) then
        if (rst = '0') then
            state <= RESET;
        else
            if (en = '1') then
                state <= next_state;
            end if;
        end if;
    end if;
end process;

process (state, counter)
begin
    case state is
        when START => next_state <= LOAD;
        when LOAD => next_state <= VERSION;
        when VERSION => next_state <= SERVICE;            
        when SERVICE => next_state <= LENGTH;                       
        when LENGTH =>
            if (counter = two_bytes-1) then
                next_state <= ID;
            else
                next_state <= LENGTH;
            end if;
        when ID =>
            if (counter = two_bytes-1) then
                next_state <= FLAGS;
            else
                next_state <= ID;
            end if;
        when FLAGS =>
            if (counter = two_bytes-1) then
                next_state <= TTL;
            else
                next_state <= FLAGS;
            end if;
        when TTL => next_state <= PROTOCOL;
        when PROTOCOL => next_state <= CHECKSUM;
        when CHECKSUM =>
            if (counter = two_bytes-1) then
                next_state <= SOURCE_IP;
            else
                next_state <= CHECKSUM;
            end if;
        when SOURCE_IP =>
            if (counter = ip_length-1) then
                next_state <= DESTINATION_IP;
            else
                next_state <= SOURCE_IP;
            end if;            
        when DESTINATION_IP =>
            if (counter = ip_length-1) then
                next_state <= DATA;
            else
                next_state <= DESTINATION_IP;
            end if;
        when DATA =>
            if (counter = 18) then
                next_state <= DONE;
            else
                next_state <= DATA;
            end if;         
        when DONE => next_state <= START;
        when RESET => next_state <= START;
        when OTHERS => next_state <= START;
    end case;
end process;

process (clk)
begin
    if (rising_edge(clk)) then
        if (en = '1') then
            on_off <= '1';
            valid <= '1';
            data_out <= (others => '0');
            
            case state is
                when START =>
                    valid <= '0';
                
                when LOAD =>
                    src_ip_s <= (src_ip(31 downto 24), src_ip(23 downto 16), src_ip(15 downto 8), src_ip(7 downto 0));
                    dst_ip_s <= (dst_ip(31 downto 24), dst_ip(23 downto 16), dst_ip(15 downto 8), dst_ip(7 downto 0));
                    valid <= '0';          
                
                when VERSION => data_out <= version_s;
                when SERVICE => data_out <= service_s;
                when LENGTH => data_out <= length_s(counter);
                when ID => data_out <= id_s(counter);
                when FLAGS => data_out <= flag_s(counter);
                when TTL => data_out <= ttl_s;                    
                when PROTOCOL => data_out <= protocol_s;                    
                when CHECKSUM => data_out <= checksum_s(counter);
                when SOURCE_IP => data_out <= src_ip_s(counter);
                when DESTINATION_IP => data_out <= dst_ip_s(counter);
                when DATA =>
                    data_out <= udp_s(counter);
                    
                    if (counter = 18) then
                        on_off <= '0';
                    end if;
                when DONE =>
                    on_off <= '0';
                    valid <= '0';
                    
                when RESET =>
                    on_off <= '0';
                    valid <= '0';
                    
                when OTHERS =>
                    on_off <= '0';
                    valid <= '0';
            end case;
        else
            on_off <= '0';
            data_out <= (others => '0');
            valid <= '0';
        end if;
        
        state_dbg <= state_code(state);
    end if;
end process;

process (clk)
begin
if (rising_edge(clk)) then
    if (en = '1') then
        case state is
            when LENGTH | ID | FLAGS | CHECKSUM =>
                if (counter = two_bytes-1) then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when SOURCE_IP | DESTINATION_IP =>
                if (counter = ip_length-1) then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when DATA =>
                if (counter = 18) then
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

end Behavioral;