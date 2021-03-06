////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 14.7
//  \   \         Application : xaw2verilog
//  /   /         Filename : clock_dcm.v
// /___/   /\     Timestamp : 12/04/2015 14:28:19
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: xaw2verilog -st C:\NESBoy\fpga_nes\nes_cpu\.\clock_dcm.xaw C:\NESBoy\fpga_nes\nes_cpu\.\clock_dcm
//Design Name: clock_dcm
//Device: xc3s400-4pq208
//
// Module clock_dcm
// Generated by Xilinx Architecture Wizard
// Written for synthesis tool: XST
// Period Jitter (unit interval) for block DCM_INST = 0.03 UI
// Period Jitter (Peak-to-Peak) for block DCM_INST = 1.26 ns
`timescale 1ns / 1ps

module clock_dcm(CE_IN, 
                 CLKIN_IN, 
                 CLR_IN, 
                 PRE_IN, 
                 RST_IN, 
                 CLKFX_OUT, 
                 CLKIN_IBUFG_OUT, 
                 CLK0_OUT, 
                 DDR_CLKFX_OUT, 
                 LOCKED_OUT);

    input CE_IN;
    input CLKIN_IN;
    input CLR_IN;
    input PRE_IN;
    input RST_IN;
   output CLKFX_OUT;
   output CLKIN_IBUFG_OUT;
   output CLK0_OUT;
   output DDR_CLKFX_OUT;
   output LOCKED_OUT;
   
   wire CLKFB_IN;
   wire CLKFX_BUF;
   wire CLKFX_INV_IN;
   wire CLKIN_IBUFG;
   wire CLK0_BUF;
   wire C0_IN;
   wire GND_BIT;
   wire VCC_BIT;
   
   assign GND_BIT = 0;
   assign VCC_BIT = 1;
   assign CLKFX_OUT = C0_IN;
   assign CLKIN_IBUFG_OUT = CLKIN_IBUFG;
   assign CLK0_OUT = CLKFB_IN;
   BUFG  CLKFX_BUFG_INST (.I(CLKFX_BUF), 
                         .O(C0_IN));
   IBUFG  CLKIN_IBUFG_INST (.I(CLKIN_IN), 
                           .O(CLKIN_IBUFG));
   BUFG  CLK0_BUFG_INST (.I(CLK0_BUF), 
                        .O(CLKFB_IN));
   DCM #( .CLK_FEEDBACK("1X"), .CLKDV_DIVIDE(2.0), .CLKFX_DIVIDE(7), 
         .CLKFX_MULTIPLY(3), .CLKIN_DIVIDE_BY_2("FALSE"), 
         .CLKIN_PERIOD(20.000), .CLKOUT_PHASE_SHIFT("NONE"), 
         .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), .DFS_FREQUENCY_MODE("LOW"), 
         .DLL_FREQUENCY_MODE("LOW"), .DUTY_CYCLE_CORRECTION("TRUE"), 
         .FACTORY_JF(16'h8080), .PHASE_SHIFT(0), .STARTUP_WAIT("FALSE") ) 
         DCM_INST (.CLKFB(CLKFB_IN), 
                 .CLKIN(CLKIN_IBUFG), 
                 .DSSEN(GND_BIT), 
                 .PSCLK(GND_BIT), 
                 .PSEN(GND_BIT), 
                 .PSINCDEC(GND_BIT), 
                 .RST(RST_IN), 
                 .CLKDV(), 
                 .CLKFX(CLKFX_BUF), 
                 .CLKFX180(), 
                 .CLK0(CLK0_BUF), 
                 .CLK2X(), 
                 .CLK2X180(), 
                 .CLK90(), 
                 .CLK180(), 
                 .CLK270(), 
                 .LOCKED(LOCKED_OUT), 
                 .PSDONE(), 
                 .STATUS());
   INV  INV_INST (.I(C0_IN), 
                 .O(CLKFX_INV_IN));
   OFDDRCPE  OFDDRCPE_INST (.CE(CE_IN), 
                           .CLR(CLR_IN), 
                           .C0(C0_IN), 
                           .C1(CLKFX_INV_IN), 
                           .D0(VCC_BIT), 
                           .D1(GND_BIT), 
                           .PRE(PRE_IN), 
                           .Q(DDR_CLKFX_OUT));
endmodule
