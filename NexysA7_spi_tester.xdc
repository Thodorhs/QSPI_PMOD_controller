## ----------------------------------------------------------------------------------
## 1. 100 MHz Clock Signal
## ----------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## ----------------------------------------------------------------------------------
## 2. Buttons (Center)
## ----------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { btnC }]; # Center (Reset)

## ----------------------------------------------------------------------------------
## 4. LEDs [15:0] (Data Read Back)
## ----------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { led[0]  }];
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { led[1]  }];
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { led[2]  }];
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { led[3]  }];
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { led[4]  }];
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { led[5]  }];
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { led[6]  }];
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { led[7]  }];
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { led[8]  }];
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { led[9]  }];
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { led[10] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { led[11] }];
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { led[12] }];
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { led[13] }];
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { led[14] }];
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { led[15] }];

## ----------------------------------------------------------------------------------
## 5. PMOD JA (Top Right PMOD Header) - Connected to QSPI PMOD Board
## ----------------------------------------------------------------------------------
# Top Row of PMOD JA
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { pmod_cs0  }]; # JA1 (Pin 1) - Flash CS
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { pmod_mosi }]; # JA2 (Pin 2) - MOSI
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { pmod_miso }]; # JA3 (Pin 3) - MISO
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { pmod_sck  }]; # JA4 (Pin 4) - SCK

# Bottom Row of PMOD JA
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { pmod_sd2  }]; # JA7 (Pin 7) - SD2
set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 } [get_ports { pmod_sd3  }]; # JA8 (Pin 8) - SD3
set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 } [get_ports { pmod_cs1  }]; # JA9 (Pin 9) - PSRAM A CS
set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 } [get_ports { pmod_cs2  }]; # JA10 (Pin 10) - PSRAM B CS

# TEST SUCCESS LED
set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { ack_led   }];

## ----------------------------------------------------------------------------------
## 7-Segment Display
## ----------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { seg[0] }]; # CA
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports { seg[1] }]; # CB
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { seg[2] }]; # CC
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { seg[3] }]; # CD
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { seg[4] }]; # CE
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { seg[5] }]; # CF
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { seg[6] }]; # CG
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { dp }];     # DP

set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { an[0] }];  # AN0
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { an[1] }];  # AN1
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { an[2] }];  # AN2
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { an[3] }];  # AN3
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { an[4] }];  # AN4
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { an[5] }];  # AN5
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { an[6] }];  # AN6
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { an[7] }];  # AN7