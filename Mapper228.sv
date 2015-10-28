
// iNES Mapper 228 represents the board used by Active Enterprises for Action 52 and Cheetahmen II.
module Mapper228(input clk, input ce, input reset,
                input [31:0] flags,
                input [15:0] prg_ain, output [21:0] prg_aout,
                input prg_read, prg_write,                   // Read / write signals
                input [7:0] prg_din,
                output prg_allow,                          // Enable access to memory for the specified operation.
                input [13:0] chr_ain, output [21:0] chr_aout,
                output chr_allow,                             // Allow write
                output vram_a10,                              // Value for A10 address line
                output vram_ce);                              // True if the address should be routed to the internal 2kB VRAM.
  reg mirroring;
  reg [1:0] prg_chip;
  reg [4:0] prg_bank;
  reg prg_bank_mode;
  reg [5:0] chr_bank;
  always @(posedge clk) if (reset) begin
    {mirroring, prg_chip, prg_bank, prg_bank_mode} <= 0;
    chr_bank <= 0;
  end else if (ce) begin
    if (prg_ain[15] & prg_write) begin
      {mirroring, prg_chip, prg_bank, prg_bank_mode} <= prg_ain[13:5];
      chr_bank <= {prg_ain[3:0], prg_din[1:0]};
    end
  end
  assign vram_a10 = mirroring ? chr_ain[11] : chr_ain[10];
  wire prglow = prg_bank_mode ? prg_bank[0] : prg_ain[14];
  wire [1:0] addrsel = {prg_chip[1], prg_chip[1] ^ prg_chip[0]};
  assign prg_aout = {1'b0, addrsel, prg_bank[4:1], prglow, prg_ain[13:0]};
  assign prg_allow = prg_ain[15] && !prg_write;
  assign chr_allow = flags[15];
  assign chr_aout = {3'b10_0, chr_bank, chr_ain[12:0]};
  assign vram_ce = chr_ain[13];
endmodule
