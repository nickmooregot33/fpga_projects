// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

module Mac(input clk, input use_accum, input [17:0] A, input [17:0] B, input [17:0] D, output [47:0] P);
  wire [7:0] OPMODE = use_accum ? 8'b00011001 : 8'b00010001;
   DSP48A1 #(
      .A0REG(0),              // First stage A input pipeline register (0/1)
      .A1REG(0),              // Second stage A input pipeline register (0/1)
      .B0REG(0),              // First stage B input pipeline register (0/1)
      .B1REG(0),              // Second stage B input pipeline register (0/1)
      .CARRYINREG(0),         // CARRYIN input pipeline register (0/1)
      .CARRYINSEL("OPMODE5"), // Specify carry-in source, "CARRYIN" or "OPMODE5" 
      .CARRYOUTREG(0),        // CARRYOUT output pipeline register (0/1)
      .CREG(0),               // C input pipeline register (0/1)
      .DREG(0),               // D pre-adder input pipeline register (0/1)
      .MREG(0),               // M pipeline register (0/1)
      .OPMODEREG(0),          // Enable=1/disable=0 OPMODE input pipeline registers
      .PREG(1),               // P output pipeline register (0/1)
      .RSTTYPE("SYNC")        // Specify reset type, "SYNC" or "ASYNC" 
   )
   
   DSP48A1_inst (
      // Cascade Ports: 18-bit (each) output: Ports to cascade from one DSP48 to another
//      .BCOUT(BCOUT),           // 18-bit output: B port cascade output
//      .PCOUT(PCOUT),           // 48-bit output: P cascade output (if used, connect to PCIN of another DSP48A1)
      // Data Ports: 1-bit (each) output: Data input and output ports
//      .CARRYOUT(CARRYOUT),     // 1-bit output: carry output (if used, connect to CARRYIN pin of another
//                               // DSP48A1)

//      .CARRYOUTF(CARRYOUTF),   // 1-bit output: fabric carry output
//      .M(M),                   // 36-bit output: fabric multiplier data output
      .P(P),                   // 48-bit output: data output
      // Cascade Ports: 48-bit (each) input: Ports to cascade from one DSP48 to another
//      .PCIN(0),             // 48-bit input: P cascade input (if used, connect to PCOUT of another DSP48A1)
      // Control Input Ports: 1-bit (each) input: Clocking and operation mode
      .CLK(clk),               // 1-bit input: clock input
      .OPMODE(OPMODE),         // 8-bit input: operation mode input
      // Data Ports: 18-bit (each) input: Data input and output ports
      .A(A),                   // 18-bit input: A data input
      .B(B),                   // 18-bit input: B data input (connected to fabric or BCOUT of adjacent DSP48A1)
  //    .C(C),                   // 48-bit input: C data input
 //     .CARRYIN(CARRYIN),       // 1-bit input: carry input signal (if used, connect to CARRYOUT pin of another
 //                              // DSP48A1)

      .D(D),                 // 18-bit input: B pre-adder data input
      // Reset/Clock Enable Input Ports: 1-bit (each) input: Reset and enable input ports
      .CEA(1'b0),              // 1-bit input: active high clock enable input for A registers
      .CEB(1'b0),              // 1-bit input: active high clock enable input for B registers
      .CEC(1'b0),              // 1-bit input: active high clock enable input for C registers
      .CECARRYIN(1'b0),        // 1-bit input: active high clock enable input for CARRYIN registers
      .CED(1'b0),              // 1-bit input: active high clock enable input for D registers
      .CEM(1'b0),              // 1-bit input: active high clock enable input for multiplier registers
      .CEOPMODE(1'b0),         // 1-bit input: active high clock enable input for OPMODE registers
      .CEP(1'b1),              // 1-bit input: active high clock enable input for P registers
      .RSTA(1'b0),             // 1-bit input: reset input for A pipeline registers
      .RSTB(1'b0),             // 1-bit input: reset input for B pipeline registers
      .RSTC(1'b0),             // 1-bit input: reset input for C pipeline registers
      .RSTCARRYIN(1'b0),       // 1-bit input: reset input for CARRYIN pipeline registers
      .RSTD(1'b0),             // 1-bit input: reset input for D pipeline registers
      .RSTM(1'b0),             // 1-bit input: reset input for M pipeline registers
      .RSTOPMODE(1'b0),        // 1-bit input: reset input for OPMODE pipeline registers
      .RSTP(1'b0)              // 1-bit input: reset input for P pipeline registers
   );
endmodule
