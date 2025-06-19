library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UDP is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        src_port : in std_logic_vector(15 downto 0);
        dst_port : in std_logic_vector(15 downto 0);
        data_length : in std_logic_vector(15 downto 0);
        chcksum : in std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(159 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        valid : out std_logic;
        on_off : out std_logic;
        state_dbg : out std_logic_vector(3 downto 0)
    );
end UDP;

architecture Behavioral of UDP is
type FSM is (
    START,
    LOAD,
    SOURCE_PORT,
    DESTINATION_PORT,
    LENGTH,
    CHECKSUM,
    DATA,
    RESET,
    DONE
);

type state_code_array is array (FSM) of std_logic_vector(3 downto 0);

constant state_code : state_code_array := (
    START               => "0001",
    LOAD                => "0010",
    SOURCE_PORT         => "0011",
    DESTINATION_PORT    => "0100",
    LENGTH              => "0101",
    CHECKSUM            => "0110",
    DATA                => "0111",
    RESET               => "1000",
    DONE                => "1001",
    others              => "1111"
);

type twoBytes is array (0 to 1) of std_logic_vector(7 downto 0);
type busData is array (0 to 19) of std_logic_vector(7 downto 0);
signal src_port_s, dst_port_s, data_length_s, chcksum_s : twoBytes;
signal data_s : busData;

signal state, next_state : FSM := START;
signal counter : integer := 0;
signal length_s : integer := 1;
constant two_bytes : integer := 2;

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
        when START =>
            next_state <= LOAD;
        when LOAD =>
            next_state <= SOURCE_PORT;
        when SOURCE_PORT =>
            if (counter = two_bytes-1) then
                next_state <= DESTINATION_PORT;
            else
                next_state <= SOURCE_PORT;
            end if;
        when DESTINATION_PORT =>
            if (counter = two_bytes-1) then
                next_state <= LENGTH;
            else
                next_state <= DESTINATION_PORT;
            end if;
        when LENGTH =>
            if (counter = two_bytes-1) then
                next_state <= CHECKSUM;
            else
                next_state <= LENGTH;
            end if;
        when CHECKSUM =>
            if (counter = two_bytes-1) then
                next_state <= DATA;
            else
                next_state <= CHECKSUM;
            end if;
        when DATA =>
            if (counter = length_s-1) then
                next_state <= DONE;
            else
                next_state <= DATA;
            end if;
        when RESET =>
            next_state <= START;
        when DONE =>
            next_state <= START;
        when others =>
            next_state <= START;
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
                    src_port_s <= (src_port(15 downto 8), src_port(7 downto 0));
                    dst_port_s <= (dst_port(15 downto 8), dst_port(7 downto 0));
                    data_length_s <= (data_length(15 downto 8), data_length(7 downto 0));
                    chcksum_s <= (chcksum(15 downto 8), chcksum(7 downto 0));
                    data_s <= (data_in(159 downto 152), data_in(151 downto 144), data_in(143 downto 136), data_in(135 downto 128), data_in(127 downto 120),
                               data_in(119 downto 112), data_in(111 downto 104), data_in(103 downto 96), data_in(95 downto 88), data_in(87 downto 80),
                               data_in(79 downto 72), data_in(71 downto 64), data_in(63 downto 56), data_in(55 downto 48), data_in(47 downto 40),
                               data_in(39 downto 32), data_in(31 downto 24), data_in(23 downto 16), data_in(15 downto 8), data_in(7 downto 0));
                    valid <= '0';
                    
                when SOURCE_PORT =>
                    data_out <= src_port_s(counter);
                    
                when DESTINATION_PORT =>
                    data_out <= dst_port_s(counter);
                    
                when LENGTH =>
                    data_out <= data_length_s(counter);
                    length_s <= to_integer(unsigned(data_length_s(0)) & unsigned(data_length_s(1)));
                
                when CHECKSUM =>
                    data_out <= chcksum_s(counter);
                    
                when DATA =>
                    data_out <= data_s(counter);
                    
                    if (counter = length_s-1) then
                        on_off <= '0';
                    end if;
                when RESET =>
                    on_off <= '0';
                    valid <= '0';
                    
                when DONE =>
                    on_off <= '0';
                    valid <= '0';
                    
                when others =>
                    on_off <= '0';
                    valid <= '0';
                    
            end case;
        else
            on_off <= '0';
            valid <= '0';
            data_out <= (others => '0');
        end if;
    state_dbg <= state_code(state);
    end if;
end process;

process (clk)
begin
    if (rising_edge(clk)) then
        if (en = '1') then
            case state is
                when SOURCE_PORT | DESTINATION_PORT | LENGTH | CHECKSUM =>
                    if (counter = two_bytes-1) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                when DATA =>
                    if (counter = length_s-1) then
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
