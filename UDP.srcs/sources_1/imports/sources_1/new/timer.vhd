library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity timer is
    Generic(
        N : integer := 125000000
    );
    Port( 
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        done : out std_logic
    );
end timer;

architecture Behavioral of timer is
signal counter : integer := 0;
signal flag : std_logic := '0';

begin
    process (clk)
        begin
            if (rising_edge(clk)) then
                if (rst = '0') then 
                    counter <= 0;
                    flag <= '0';
                elsif (en = '1') then                    
                    if (counter = N-1) then
                        flag <= '1';
                    else
                        counter <= counter + 1;
                    end if;
                else
                    flag <= '0';              
                end if;
            end if;
    end process;
    
done <= flag;
end Behavioral;
