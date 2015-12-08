
module Mapper234(input clk, input ce, input reset,
                input [31:0] flags,
                input [15:0] prg_ain, output [21:0] prg_aout,
                input prg_read, prg_write,                   // Read / write signals
                input [7:0] prg_din,
                output prg_allow,                          // Enable access to memory for the specified operation.
                input [13:0] chr_ain, output [21:0] chr_aout,
                output chr_allow,                             // Allow write
                output vram_a10,                              // Value for A10 address line
                output vram_ce);                              // True if the address should be routed to the internal 2kB VRAM.
  reg [2:0] block, inner_chr;
  reg mode, mirroring, inner_prg;
  always @(posedge clk) if (reset) begin
    block <= 0;
    {mode, mirroring} <= 0;
    inner_chr <= 0;
    inner_prg <= 0;
  end else if (ce) begin
    if (prg_read && prg_ain[15:7] == 9'b1111_1111_1) begin
      // Outer bank control $FF80 - $FF9F
      if (prg_ain[6:0] < 7'h20 && (block == 0)) begin
        {mirroring, mode} <= prg_din[7:6];
        block <= prg_din[3:1];
        {inner_chr[2], inner_prg} <= {prg_din[0], prg_din[0]};
      end
      // Inner bank control ($FFE8-$FFF7)
      if (prg_ain[6:0] >= 7'h68 && prg_ain[6:0] < 7'h78) begin
        {inner_chr[2], inner_prg} <= mode ? {prg_din[6], prg_din[0]} : {inner_chr[2], inner_prg};
        inner_chr[1:0] <= prg_din[5:4];
      end
    end
  end
  assign vram_a10 = mirroring ? chr_ain[11] : chr_ain[10];
  assign prg_aout = {3'b00_0, block, inner_prg, prg_ain[14:0]};
  assign chr_aout = {3'b10_0, block, inner_chr, chr_ain[12:0]};
  assign prg_allow = prg_ain[15] && !prg_write;
  assign chr_allow = flags[15];
  assign vram_ce = chr_ain[13];
endmodule

