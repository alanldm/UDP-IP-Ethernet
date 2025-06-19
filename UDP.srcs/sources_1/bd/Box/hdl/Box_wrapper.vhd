--Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
--Date        : Thu Jun 19 11:07:09 2025
--Host        : GANP1847 running 64-bit major release  (build 9200)
--Command     : generate_target Box_wrapper.bd
--Design      : Box_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity Box_wrapper is
  port (
    CLK_125MHz_0 : out STD_LOGIC;
    clk_in1_n_0 : in STD_LOGIC;
    clk_in1_p_0 : in STD_LOGIC;
    rgmii_rx_ctl_0 : in STD_LOGIC;
    rgmii_rxc_0 : in STD_LOGIC;
    rgmii_rxd_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    rgmii_tx_ctl_0 : out STD_LOGIC;
    rgmii_txc_0 : out STD_LOGIC;
    rgmii_txd_0 : out STD_LOGIC_VECTOR ( 3 downto 0 )
  );
end Box_wrapper;

architecture STRUCTURE of Box_wrapper is
  component Box is
  port (
    CLK_125MHz_0 : out STD_LOGIC;
    clk_in1_n_0 : in STD_LOGIC;
    clk_in1_p_0 : in STD_LOGIC;
    rgmii_rx_ctl_0 : in STD_LOGIC;
    rgmii_rxc_0 : in STD_LOGIC;
    rgmii_rxd_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    rgmii_tx_ctl_0 : out STD_LOGIC;
    rgmii_txc_0 : out STD_LOGIC;
    rgmii_txd_0 : out STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component Box;
begin
Box_i: component Box
     port map (
      CLK_125MHz_0 => CLK_125MHz_0,
      clk_in1_n_0 => clk_in1_n_0,
      clk_in1_p_0 => clk_in1_p_0,
      rgmii_rx_ctl_0 => rgmii_rx_ctl_0,
      rgmii_rxc_0 => rgmii_rxc_0,
      rgmii_rxd_0(3 downto 0) => rgmii_rxd_0(3 downto 0),
      rgmii_tx_ctl_0 => rgmii_tx_ctl_0,
      rgmii_txc_0 => rgmii_txc_0,
      rgmii_txd_0(3 downto 0) => rgmii_txd_0(3 downto 0)
    );
end STRUCTURE;
