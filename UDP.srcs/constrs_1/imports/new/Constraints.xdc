#### ==== RGMII RX (PHY ? FPGA) ====
set_property PACKAGE_PIN Y18 [get_ports rgmii_rxc_0]         ;# ETH_RX_CLK
set_property PACKAGE_PIN AB19 [get_ports rgmii_rx_ctl_0]      ;# ETH_RX_CTRL
set_property PACKAGE_PIN AA20 [get_ports rgmii_rxd_0[3]]       ;# ETH_RXD3
set_property PACKAGE_PIN AA19 [get_ports rgmii_rxd_0[2]]       ;# ETH_RXD2
set_property PACKAGE_PIN AB22 [get_ports rgmii_rxd_0[1]]       ;# ETH_RXD1
set_property PACKAGE_PIN AB21 [get_ports rgmii_rxd_0[0]]       ;# ETH_RXD0

#RGMII TX
set_property PACKAGE_PIN V18 [get_ports rgmii_txc_0]
set_property PACKAGE_PIN W18 [get_ports rgmii_tx_ctl_0]       
set_property PACKAGE_PIN V19 [get_ports rgmii_txd_0[3]]        
set_property PACKAGE_PIN U19 [get_ports rgmii_txd_0[2]]        
set_property PACKAGE_PIN AA15 [get_ports rgmii_txd_0[1]]       
set_property PACKAGE_PIN AA14 [get_ports rgmii_txd_0[0]]       

set_property IOSTANDARD LVCMOS33 [get_ports {rgmii_*}]

#Clock Si570 - 156.25MHz
set_property PACKAGE_PIN T2 [get_ports clk_in1_p_0]
set_property PACKAGE_PIN T1 [get_ports clk_in1_n_0]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports {clk_in1_p_0 clk_in1_n_0}]
set_property DIFF_TERM TRUE [get_ports {clk_in1_p_0 clk_in1_n_0}]

#Debug Clock 125MHz
set_property PACKAGE_PIN A5 [get_ports CLK_125MHz_0]
set_property IOSTANDARD LVCMOS18 [get_ports CLK_125MHz_0]


#Reset
set_property PACKAGE_PIN T16 [get_ports ext_reset_in_0]
set_property IOSTANDARD LVCMOS33 [get_ports ext_reset_in_0]