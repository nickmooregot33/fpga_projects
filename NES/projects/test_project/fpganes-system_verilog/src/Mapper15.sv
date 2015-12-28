// #15 -  100-in-1 Contra Function 16
module Mapper15(input clk, input ce, input reset,
                input [31:0] flags,
                input [15:0] prg_ain, output [21:0] prg_aout,
                input prg_read, prg_write,                   // Read / write signals
                input [7:0] prg_din,
                output prg_allow,                            // Enable access to memory for the specified operation.
                input [13:0] chr_ain, output [21:0] chr_aout,
                output chr_allow,                      // Allow write
                output vram_a10,                             // Value for A10 address line
                output vram_ce);                             // True if the address should be routed to the internal 2kB VRAM.
// 15 bit  8 7  bit  0  Address bus
// ---- ---- ---- ----
// 1xxx xxxx xxxx xxSS
// |                ||
// |                ++- Select PRG ROM bank mode
// |                    0: 32K; 1: 128K (UNROM style); 2: 8K; 3: 16K
// +------------------- Always 1
// 7  bit  0  Data bus
// ---- ----
// bMBB BBBB
// |||| ||||
// ||++-++++- Select 16 KB PRG ROM bank
// |+-------- Select nametable mirroring mode (0=vertical; 1=horizontal)
// +--------- Select 8 KB half of 16 KB PRG ROM bank
//            (should be 0 except in bank mode 0)
  reg [1:0] prg_rom_bank_mode;
  reg prg_rom_bank_lowbit;
  reg mirroring;
  reg [5:0] prg_rom_bank;
  always @(posedge clk) if (reset) begin
    prg_rom_bank_mode <= 0;
    prg_rom_bank_lowbit <= 0;
    mirroring <= 0;
    prg_rom_bank <= 0;
  end else if (ce) begin
    if (prg_ain[15] && prg_write)
      {prg_rom_bank_mode, prg_rom_bank_lowbit, mirroring, prg_rom_bank} <= {prg_ain[1:0], prg_din[7:0]};
  end
  reg [6:0] prg_bank;
  always begin
    casez({prg_rom_bank_mode, prg_ain[14]})
    // Bank mode 0 ( 32K ) / CPU $8000-$BFFF: Bank B / CPU $C000-$FFFF: Bank (B OR 1)
    3'b00_0: prg_bank = {prg_rom_bank, prg_ain[13]};
    3'b00_1: prg_bank = {prg_rom_bank | 6'b1, prg_ain[13]};
    // Bank mode 1 ( 128K ) / CPU $8000-$BFFF: Switchable 16 KB bank B / CPU $C000-$FFFF: Fixed to last bank in the cart
    3'b01_0: prg_bank = {prg_rom_bank, prg_ain[13]};
    3'b01_1: prg_bank = {6'b111111, prg_ain[13]};
    // Bank mode 2 ( 8K ) / CPU $8000-$9FFF: Sub-bank b of 16 KB PRG ROM bank B / CPU $A000-$FFFF: Mirrors of $8000-$9FFF
    3'b10_?: prg_bank = {prg_rom_bank, prg_rom_bank_lowbit};
    // Bank mode 3 ( 16K ) / CPU $8000-$BFFF: 16 KB bank B / CPU $C000-$FFFF: Mirror of $8000-$BFFF
    3'b11_?: prg_bank = {prg_rom_bank, prg_ain[13]};
    endcase
  end
  assign prg_aout = {2'b00, prg_bank, prg_ain[12:0]};
  assign prg_allow = prg_ain[15] && !prg_write;
  assign chr_allow = flags[15]; // CHR RAM?
  assign chr_aout = {9'b10_0000_000, chr_ain[12:0]};
  assign vram_ce = chr_ain[13];
  assign vram_a10 = mirroring ? chr_ain[11] : chr_ain[10];
endmodule
