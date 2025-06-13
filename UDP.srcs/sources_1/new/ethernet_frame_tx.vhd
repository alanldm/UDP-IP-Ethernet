library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_frame_tx is
    Port (
        clk           : in  std_logic;
        rstn          : in  std_logic;
        tready        : in  std_logic;
        tvalid        : out std_logic;
        tdata         : out std_logic_vector(7 downto 0);
        tlast         : out std_logic
    );
end ethernet_frame_tx;

architecture Behavioral of ethernet_frame_tx is

    -- Ethernet frame: FF FF FF FF FF FF 00 0A 35 00 00 01 08 00 01 .. 08
    type frame_array_t is array (0 to 21) of std_logic_vector(7 downto 0);
    constant frame : frame_array_t := (
        x"10", x"FF", x"FF", x"FF", x"FF", x"FF",  -- Dest MAC
        x"00", x"0A", x"35", x"00", x"00", x"01",  -- Src MAC
        x"08", x"00",                                  -- Ethertype IPv4
        x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08"  -- Payload
    );

    signal index   : integer range 0 to 21 := 0;
    signal sending : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                index   <= 0;
                sending <= '0';
                tvalid  <= '0';
                tdata   <= (others => '0');
                tlast   <= '0';

            elsif sending = '0' then
                -- Começa envio automaticamente
                sending <= '1';
                index   <= 0;

            elsif sending = '1' then
                if tready = '1' then
                    tdata  <= frame(index);
                    tvalid <= '1';

                    if index = 21 then
                        tlast   <= '1';
                        sending <= '0';
                        index   <= 0;
                    else
                        tlast <= '0';
                        index <= index + 1;
                    end if;
                else
                    tvalid <= '0';
                    tlast  <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
