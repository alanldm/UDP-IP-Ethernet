library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity myNot is
    Port ( 
        i : in std_logic;
        o : out std_logic
    );
end myNot;

architecture Behavioral of myNot is

begin

    o <= not i;

end Behavioral;
