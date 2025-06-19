library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IP is
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        prtcl_on_off : in std_logic;
        prtcl_valid : in std_logic;
        data_length : in std_logic_vector(15 downto 0);
        src_ip : in std_logic_vector(31 downto 0);
        dst_ip : in std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        on_off : out std_logic;
        valid : out std_logic;
        prtcl_en : out std_logic;
        state_dbg : out std_logic_vector(4 downto 0)
    );
end IP;

architecture Behavioral of IP is

function ip_checksum(header : std_logic_vector(159 downto 0)) return std_logic_vector is
    variable sum : unsigned(17 downto 0) := (others => '0');
    variable word : unsigned(15 downto 0);
begin
    for i in 0 to 9 loop
        word := unsigned(header((i*16 + 15) downto i*16));
        sum := sum + resize(word, 18);
    end loop;
    
    sum := resize(sum(15 downto 0), 18) + ("00" & sum(17 downto 16));
    
    return std_logic_vector(not sum(15 downto 0));
end function;

type FSM is (
    START,
    LOAD,
    CAL_LENGTH,
    CAL_CHECKSUM,
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
    ENABLE_PROTOCOL,
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
    CAL_LENGTH      => "10001",
    CAL_CHECKSUM    => "10010",
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
    ENABLE_PROTOCOL => "01101",
    DATA            => "01110",
    RESET           => "01111",
    DONE            => "10000",
    others          => "00000"
);

type twoBytes is array (0 to two_bytes-1) of std_logic_vector (7 downto 0);
type fourBytes is array (0 to ip_length-1) of std_logic_vector (7 downto 0);

signal version_s : std_logic_vector (7 downto 0) := x"45";
signal service_s : std_logic_vector (7 downto 0) := x"00";
signal length_s : twoBytes;
signal id_s : twoBytes := (x"00", x"01");
signal flag_s : twoBytes := (x"40", x"00");
signal ttl_s : std_logic_vector (7 downto 0) := x"40";
signal protocol_s : std_logic_vector (7 downto 0) := x"11";
signal checksum_s : twoBytes;
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
        when LOAD => next_state <= CAL_LENGTH;
        when CAL_LENGTH => next_state <= CAL_CHECKSUM;
        when CAL_CHECKSUM => next_state <= VERSION;
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
                next_state <= ENABLE_PROTOCOL;
            else
                next_state <= DESTINATION_IP;
            end if;
        when ENABLE_PROTOCOL =>
            if (prtcl_on_off = '1') then
                next_state <= DATA;
            else
                next_state <= ENABLE_PROTOCOL;
            end if;
        when DATA =>
            if (prtcl_on_off = '0') then
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
variable result : unsigned(15 downto 0);
variable concat : std_logic_vector(15 downto 0);
variable header : std_logic_vector(159 downto 0);
variable chksum : std_logic_vector(15 downto 0) := (others => '0');
                    
begin
    if (rising_edge(clk)) then
        if (en = '1') then
            on_off <= '1';
            valid <= '1';
            prtcl_en <= '0';
            data_out <= (others => '0');
            
            case state is
                when START =>
                    valid <= '0';
                
                when LOAD =>
                    src_ip_s <= (src_ip(31 downto 24), src_ip(23 downto 16), src_ip(15 downto 8), src_ip(7 downto 0));
                    dst_ip_s <= (dst_ip(31 downto 24), dst_ip(23 downto 16), dst_ip(15 downto 8), dst_ip(7 downto 0));
                    length_s <= (data_length(15 downto 8), data_length(7 downto 0));
                    valid <= '0';
                    
                when CAL_LENGTH =>
                    concat := length_s(0) & length_s(1);
                    result := unsigned(concat) + 8 + 20;
                    length_s <= (std_logic_vector(result(15 downto 8)), std_logic_vector(result(7 downto 0)));
                    valid <= '0';
                    
                when CAL_CHECKSUM =>
                    header := version_s & service_s & length_s(0) & length_s(1) & id_s(0) & id_s(1) & flag_s(0) & flag_s(1) & ttl_s & protocol_s & chksum & src_ip_s(0) & src_ip_s(1) & src_ip_s(2) & src_ip_s(3) & dst_ip_s(0) & dst_ip_s(1) & dst_ip_s(2) & dst_ip_s(3);
                    chksum := ip_checksum(header);
                    checksum_s <= (chksum(15 downto 8), chksum(7 downto 0));      
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
                when ENABLE_PROTOCOL =>
                    valid <= '0';
                    prtcl_en <= '1';
                when DATA =>
                    prtcl_en <= '1';
                    valid <= prtcl_valid;
                    data_out <= data_in;
                    
                    if (prtcl_on_off = '0') then
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