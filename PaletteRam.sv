 

module PaletteRam(input clk, input ce, input [4:0] addr, input [5:0] din, output [5:0] dout, input write);
  reg [5:0] palette [0:31];
  initial begin
     $readmemh("oam_palette.txt", palette);
  end
  // Force read from backdrop channel if reading from any addr 0.
  wire [4:0] addr2 = (addr[1:0] == 0) ? 0 : addr;
  assign dout = palette[addr2];
  always @(posedge clk) if (ce && write) begin
    // Allow writing only to x0
    if (!(addr[3:2] != 0 && addr[1:0] == 0))
      palette[addr2] <= din;
  end
endmodule  // PaletteRam
