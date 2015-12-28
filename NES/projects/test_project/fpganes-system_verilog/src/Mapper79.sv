// #79,#113 - NINA-03 / NINA-06
module Mapper79(input clk, input ce, input reset,
                input [31:0] flags,
                input [15:0] prg_ain, output [21:0] prg_aout,
                input prg_read, prg_write,                   // Read / write signals
                input [7:0] prg_din,
                output prg_allow,                            // Enable access to memory for the specified operation.
                input [13:0] chr_ain, output [21:0] chr_aout,
                output chr_allow,                      // Allow write
                output vram_a10,                             // Value for A10 address line
                output vram_ce);                             // True if the address should be routed to the internal 2kB VRAM.
  reg [2:0] prg_bank;
  reg [3:0] chr_bank;
  reg mirroring;  // 0: Horizontal, 1: Vertical
  wire mapper113 = (flags[7:0] == 113); // NINA-06
  always @(posedge clk) if (reset) begin
    prg_bank <= 0;
    chr_bank <= 0;
    mirroring <= 0;
  end else if (ce) begin
    if (prg_ain[15:13] == 3'b010 && prg_ain[8] && prg_write)
      {mirroring, chr_bank[3], prg_bank, chr_bank[2:0]} <= prg_din;
  end
  assign prg_aout = {4'b00_00, prg_bank, prg_ain[14:0]};
  assign prg_allow = prg_ain[15] && !prg_write;
  assign chr_allow = flags[15];
  assign chr_aout = {5'b10_000, chr_bank, chr_ain[12:0]};
  assign vram_ce = chr_ain[13];
  wire mirrconfig = mapper113 ? mirroring : flags[14]; // Mapper #13 has mapper controlled mirroring
  assign vram_a10 = mirrconfig ? chr_ain[10] : chr_ain[11]; // 0: horiz, 1: vert
endmodule
