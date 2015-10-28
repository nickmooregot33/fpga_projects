// #71,#232 - Camerica
module Mapper71(input clk, input ce, input reset,
                input [31:0] flags,
                input [15:0] prg_ain, output [21:0] prg_aout,
                input prg_read, prg_write,                   // Read / write signals
                input [7:0] prg_din,
                output prg_allow,                            // Enable access to memory for the specified operation.
                input [13:0] chr_ain, output [21:0] chr_aout,
                output chr_allow,                      // Allow write
                output vram_a10,                             // Value for A10 address line
                output vram_ce);                             // True if the address should be routed to the internal 2kB VRAM.
  reg [3:0] prg_bank;
  reg ciram_select;
  wire mapper232 = (flags[7:0] == 232);
  always @(posedge clk) if (reset) begin
    prg_bank <= 0;
    ciram_select <= 0;
  end else if (ce) begin
    if (prg_ain[15] && prg_write) begin
      $write("%X <= %X (bank = %x)\n", prg_ain, prg_din, prg_bank);
      if (!prg_ain[14] && mapper232) // $8000-$BFFF Outer bank select (only on iNES 232)
        prg_bank[3:2] <= prg_din[4:3];
      if (prg_ain[14:13] == 0)       // $8000-$9FFF Fire Hawk Mirroring
        ciram_select <= prg_din[4];
      if (prg_ain[14])               // $C000-$FFFF Bank select
        prg_bank <= {mapper232 ? prg_bank[3:2] : prg_din[3:2], prg_din[1:0]};
    end
  end
  reg [3:0] prgout;
  always begin
    casez({prg_ain[14], mapper232})
    2'b0?: prgout = prg_bank;
    2'b10: prgout = 4'b1111;
    2'b11: prgout = {prg_bank[3:2], 2'b11};
    endcase
  end
  assign prg_aout = {4'b00_00, prgout, prg_ain[13:0]};
  assign prg_allow = prg_ain[15] && !prg_write;
  assign chr_allow = flags[15];
  assign chr_aout = {9'b10_0000_000, chr_ain[12:0]};
  assign vram_ce = chr_ain[13];
  // XXX(ludde): Fire hawk uses flags[14] == 0 while no other game seems to do that.
  // So when flags[14] == 0 we use ciram_select instead.
  assign vram_a10 = flags[14] ? chr_ain[10] : ciram_select;
endmodule
