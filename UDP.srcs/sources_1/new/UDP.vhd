library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UDP is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        src_port : in std_logic_vector(15 downto 0);
        dst_port : in std_logic_vector(15 downto 0);
        data_length : in std_logic_vector(15 downto 0);
        checksum : in std_logic_vector(15 downto 0);
        data_in : in std_logic_vector(159 downto 0);
        data_out : out std_logic_vector(7 downto 0);
        on_off : out std_logic
    );
end UDP;

architecture Behavioral of UDP is
type FSM is (
    START,
    LOAD,
    
    RESET,
    DONE
);


begin


end Behavioral;
