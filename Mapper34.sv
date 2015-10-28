
// 34 - BxROM or NINA-001
module Mapper34(input clk, input ce, input reset,
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
  reg [3:0] chr_bank_0, chr_bank_1;
  
  wire NINA = (flags[13:11] != 0); // NINA is used when there is more than 8kb of CHR
  always @(posedge clk) if (reset) begin
    prg_bank <= 0;
    chr_bank_0 <= 0;
    chr_bank_1 <= 1; // To be compatible with BxROM
  end else if (ce && prg_write) begin
    if (!NINA) begin // BxROM
      if (prg_ain[15])
        prg_bank <= prg_din[1:0];
    end else begin // NINA
      if (prg_ain == 16'h7ffd)
        prg_bank <= prg_din[1:0];
      else if (prg_ain == 16'h7ffe)
        chr_bank_0 <= prg_din[3:0];
      else if (prg_ain == 16'h7fff)
        chr_bank_1 <= prg_din[3:0];
    end
  end

  wire [21:0] prg_aout_tmp = {5'b00_000, prg_bank, prg_ain[14:0]};
  assign chr_allow = flags[15];
  assign chr_aout = {6'b10_0000, chr_ain[12] == 0 ? chr_bank_0 : chr_bank_1, chr_ain[11:0]};
  assign vram_ce = chr_ain[13];
  assign vram_a10 = flags[14] ? chr_ain[10] : chr_ain[11];

  wire prg_is_ram = (prg_ain >= 'h6000 && prg_ain < 'h8000) && NINA;
  assign prg_allow = prg_ain[15] && !prg_write ||
                     prg_is_ram;
  wire [21:0] prg_ram = {9'b11_1100_000, prg_ain[12:0]};
  assign prg_aout = prg_is_ram ? prg_ram : prg_aout_tmp;
endmodule
