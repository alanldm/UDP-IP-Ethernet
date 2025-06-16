library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IP is
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        enable : in std_logic;
        srcIP : in std_logic_vector(31 downto 0);
        dstIP : in std_logic_vector(31 downto 0);
        busIP : out std_logic_vector(7 downto 0);
        start : out std_logic
    );
end IP;

architecture Behavioral of IP is
type FSM is (
    IP_START,
    IP_VERSION,
    IP_SERVICE,
    IP_LENGTH,
    IP_ID,
    IP_FLAGS,
    IP_TTL,
    IP_PROTOCOL,
    IP_CHECKSUM,
    IP_SRC_IP,
    IP_DST_IP,
    IP_DONE
);
signal state, next_state : FSM := IP_START;
signal counter : integer := 0;

type twoBytes is array (0 to 1) of std_logic_vector (7 downto 0);
type fourBytes is array (0 to 3) of std_logic_vector (7 downto 0);

signal version : std_logic_vector (7 downto 0) := x"45";
signal service : std_logic_vector (7 downto 0) := x"00";
signal length : twoBytes := (x"00", x"32");
signal id : twoBytes := (x"00", x"01");
signal flag : twoBytes := (x"40", x"00");
signal ttl : std_logic_vector (7 downto 0) := x"40";
signal protocol : std_logic_vector (7 downto 0) := x"11";
signal checksum : twoBytes := (x"AA", x"BB");
signal src_ip : fourBytes;
signal dst_ip : fourBytes; 


begin

process (clk)
begin
    if (rising_edge(clk)) then
        if (rst = '0') then
            state <= IP_START;
        else
            state <= next_state;
        end if;
    end if;
end process;

process (state, counter, enable)
begin
    case state is
        when IP_START =>
            if (enable = '1') then
                next_state <= IP_VERSION;
            else
                next_state <= IP_START;
            end if;
        when IP_VERSION =>
            next_state <= IP_SERVICE;            
        when IP_SERVICE =>
            next_state <= IP_LENGTH;                       
        when IP_LENGTH =>
            if (counter = 1) then
                next_state <= IP_ID;
            else
                next_state <= IP_LENGTH;
            end if;
        when IP_ID =>
            if (counter = 1) then
                next_state <= IP_FLAGS;
            else
                next_state <= IP_ID;
            end if;
        when IP_FLAGS =>
            if (counter = 1) then
                next_state <= IP_TTL;
            else
                next_state <= IP_FLAGS;
            end if;
        when IP_TTL =>
            next_state <= IP_PROTOCOL;
        when IP_PROTOCOL =>
            next_state <= IP_CHECKSUM;
        when IP_CHECKSUM =>
            if (counter = 1) then
                next_state <= IP_SRC_IP;
            else
                next_state <= IP_CHECKSUM;
            end if;
        when IP_SRC_IP =>
            if (counter = 3) then
                next_state <= IP_DST_IP;
            else
                next_state <= IP_SRC_IP;
            end if;            
        when IP_DST_IP =>
            if (counter = 3) then
                next_state <= IP_DONE;
            else
                next_state <= IP_DST_IP;
            end if;            
        when IP_DONE =>
            next_state <= IP_START;
        when OTHERS =>
            next_state <= IP_START;
    end case;
end process;

process (clk)
begin
    if (rising_edge(clk)) then
        case state is
            when IP_START =>
                if (enable = '1') then
                    start <= '1';
                    src_ip <= (srcIP(31 downto 24), srcIP(23 downto 16), srcIP(15 downto 8), srcIP(7 downto 0));
                    dst_ip <= (dstIP(31 downto 24), dstIP(23 downto 16), dstIP(15 downto 8), dstIP(7 downto 0));
                    busIP <= (others => '0');
                    
                    counter <= 0;
                end if;
            when IP_VERSION =>
                start <= '1';
                busIP <= version;
                counter <= 0;
            when IP_SERVICE =>
                start <= '1';
                busIP <= service;
                counter <= 0;
            when IP_LENGTH =>
                start <= '1';
                busIP <= length(counter);
                
                if (counter = 1) then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when IP_ID =>
                start <= '1';
                busIP <= id(counter);
                
                if (counter = 1) then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when IP_FLAGS =>
                start <= '1';
                busIP <= flag(counter);
                
                if (counter = 1) then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when IP_TTL =>
                start <= '1';
                busIP <= ttl;
                counter <= 0;
            when IP_PROTOCOL =>
                start <= '1';
                busIP <= protocol;
                counter <= 0;
            when IP_CHECKSUM =>
                start <= '1';
                busIP <= checksum(counter);
                
                if (counter = 1) then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when IP_SRC_IP =>
                start <= '1';
                busIP <= src_ip(counter);
                
                if (counter = 3) then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when IP_DST_IP =>
                busIP <= dst_ip(counter);
                
                if (counter = 3) then
                    start <= '0';
                    counter <= 0;
                else
                    start <= '1';
                    counter <= counter + 1;
                end if;
            when IP_DONE =>
                start <= '0';
                busIP <= (others => '0');
                counter <= 0;
            when OTHERS =>
                start <= '0';
                busIP <= (others => '0');
        end case;
    end if;
end process;

end Behavioral;