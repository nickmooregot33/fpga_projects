
// 11 - Color Dreams
// 66 - GxROM
module Mapper66(input clk, input ce, input reset,
                input [31:0] flags,
                input [15:0] prg_ain, output [21:0] prg_aout,
                input prg_read, prg_write,                   // Read / write signals
                input [7:0] prg_din,
                output prg_allow,                            // Enable access to memory for the specified operation.
                input [13:0] chr_ain, output [21:0] chr_aout,
                output chr_allow,                      // Allow write
                output vram_a10,                             // Value for A10 address line
                output vram_ce);                             // True if the address should be routed to the internal 2kB VRAM.
  reg [1:0] prg_bank;
  reg [3:0] chr_bank;
  wire GXROM = (flags[7:0] == 66);
  always @(posedge clk) if (reset) begin
    prg_bank <= 0;
    chr_bank <= 0;
  end else if (ce) begin
    if (prg_ain[15] & prg_write) begin
      if (GXROM)
        {prg_bank, chr_bank} <= {prg_din[5:4], 2'b0, prg_din[1:0]};
      else // Color Dreams
        {chr_bank, prg_bank} <= {prg_din[7:4], prg_din[1:0]};
    end
  end
  assign prg_aout = {5'b00_000, prg_bank, prg_ain[14:0]};
  assign prg_allow = prg_ain[15] && !prg_write;
  assign chr_allow = flags[15];
  assign chr_aout = {5'b10_000, chr_bank, chr_ain[12:0]};
  assign vram_ce = chr_ain[13];
  assign vram_a10 = flags[14] ? chr_ain[10] : chr_ain[11];
endmodule
