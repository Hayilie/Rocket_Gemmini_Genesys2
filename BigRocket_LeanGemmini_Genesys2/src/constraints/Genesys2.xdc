# ------------------------------------------------------------------------------
# 1. ANA SAAT (200 MHz)
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN AD12 IOSTANDARD LVDS } [get_ports sys_clk_p]
set_property -dict { PACKAGE_PIN AD11 IOSTANDARD LVDS } [get_ports sys_clk_n]
create_clock -period 5.000 -name sys_clk_pin [get_ports sys_clk_p]

# ------------------------------------------------------------------------------
# 2. UART VE RESET
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN Y23 IOSTANDARD LVCMOS33 } [get_ports uart_0_rxd]
set_property -dict { PACKAGE_PIN Y20 IOSTANDARD LVCMOS33 } [get_ports uart_0_txd]
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports reset_io]

# ------------------------------------------------------------------------------
# 3. DURUM LED'İ
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN T28 IOSTANDARD LVCMOS33 } [get_ports status_led]

# ------------------------------------------------------------------------------
# 4. JTAG PORTLARI (PMOD JA Üzerinden)
# PMOD JA Pinleri: JA1 (U27), JA2 (U28), JA3 (T26), JA4 (T27)
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN U27 IOSTANDARD LVCMOS33 } [get_ports jtag_tck]
set_property -dict { PACKAGE_PIN U28 IOSTANDARD LVCMOS33 } [get_ports jtag_tms]
set_property -dict { PACKAGE_PIN T26 IOSTANDARD LVCMOS33 } [get_ports jtag_tdi]
set_property -dict { PACKAGE_PIN T27 IOSTANDARD LVCMOS33 } [get_ports jtag_tdo]

# JTAG TCK için saat tanımlaması (OpenOCD genelde 10 MHz - 100ns civarı çalışır)
create_clock -period 100.000 -name jtag_clk_pin [get_ports jtag_tck]

# ------------------------------------------------------------------------------
# 5. ZAMANLAMA KISITLAMALARI VE OPTİMİZASYON (CRITICAL!)
# ------------------------------------------------------------------------------
# İç saatimizi (Artık 50 MHz hedefliyoruz) değişkene al
set inner_clk [get_clocks -of_objects [get_pins genesystimer/inst/mmcm_adv_inst/CLKOUT0]]

# JTAG ve Ana CPU saatlerinin birbirinden bağımsız (Asenkron) olduğunu belirt
# Bu ayar, Vivado'nun JTAG kabloları için boş yere zamanlama eforu harcamasını engeller
set_clock_groups -asynchronous -group $inner_clk -group [get_clocks jtag_clk_pin]

# JTAG Pinleri için False Path (JTAG yavaştır, Setup/Hold analizi gerekmez)
set_false_path -from [get_ports {jtag_tms jtag_tdi}]
set_false_path -to [get_ports jtag_tdo]

# UART yavaş olduğu için CPU saat alanında timing analizini devre dışı bırak
set_false_path -from [get_ports {reset_io uart_0_rxd}]
set_false_path -to [get_ports uart_0_txd]

# ------------------------------------------------------------------------------
# 6. BITSREAM VE VOLTAJ AYARLARI
# ------------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]