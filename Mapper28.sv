// Tepples/Multi-discrete mapper
// This mapper can emulate other mappers,  such as mapper #0, mapper #2
module Mapper28(input clk, input ce, input reset,
                input [31:0] flags,
                input [15:0] prg_ain, output [21:0] prg_aout,
                input prg_read, prg_write,                   // Read / write signals
                input [7:0] prg_din,
                output prg_allow,                            // Enable access to memory for the specified operation.
                input [13:0] chr_ain, output [21:0] chr_aout,
                output chr_allow,                      // Allow write
                output reg vram_a10,                         // Value for A10 address line
                output vram_ce);                             // True if the address should be routed to the internal 2kB VRAM.
    reg [6:0] a53prg;    // output PRG ROM (A14-A20 on ROM)
    reg [1:0] a53chr;    // output CHR RAM (A13-A14 on RAM)
   
    reg [3:0] inner;    // "inner" bank at 01h
    reg [5:0] mode;     // mode register at 80h
    reg [5:0] outer;    // "outer" bank at 81h  
    reg [1:0] selreg;   // selector register
    
    // Allow writes to 0x5000 only when launching through the proper mapper ID.
    wire [7:0] mapper = flags[7:0];
    wire allow_select = (mapper == 8'd28);
        
    always @(posedge clk) if (reset) begin
      mode[5:2] <= 0;         // NROM mode, 32K mode
      outer[5:0] <= 6'h3f;    // last bank
      inner <= 0;
      selreg <= 1;
      
      // Set value for mirroring
      if (mapper == 2 || mapper == 0 || mapper == 3)
        mode[1:0] <= flags[14] ? 2'b10 : 2'b11;
        
      // UNROM #2 - Current bank in $8000-$BFFF and fixed top half of outer bank in $C000-$FFFF
      if (mapper == 2)
        mode[5:2] <= 4'b1111;
        
      // CNROM #3 - Fixed PRG bank, switchable CHR bank.
      if (mapper == 3)
        selreg <= 0;

      // AxROM #7 - Switch 32kb rom bank + switchable nametables
      if (mapper == 7) begin
        mode[1:0] <= 2'b00;   // Switchable VRAM page.
        mode[5:2] <= 4'b1100; // 256K banks, (B)NROM mode
      end
    end else if (ce) begin
      if ((prg_ain[15:12] == 4'h5) & prg_write && allow_select) selreg <= {prg_din[7], prg_din[0]};        // select register
      if (prg_ain[15] & prg_write) begin
        case (selreg)
        2'h0:  {mode[0], a53chr}  <= {(mode[1] ? mode[0] : prg_din[4]), prg_din[1:0]};  // CHR RAM bank
        2'h1:  {mode[0], inner}   <= {(mode[1] ? mode[0] : prg_din[4]), prg_din[3:0]};  // "inner" bank
        2'h2:  {mode}             <= {prg_din[5:0]};                                    // mode register
        2'h3:  {outer}            <= {prg_din[5:0]};                                    // "outer" bank
        endcase
      end
    end
    
    always begin
      // mirroring mode
      casez(mode[1:0])
      2'b0?   :   vram_a10 = {mode[0]};        // 1 screen lower
      2'b10   :   vram_a10 = {chr_ain[10]};    // vertical
      2'b11   :   vram_a10 = {chr_ain[11]};    // horizontal
      endcase

      // PRG ROM bank size select
      casez({mode[5:2], prg_ain[14]})
      5'b00_0?_?  :  a53prg = {outer[5:0],             prg_ain[14]};  // 32K banks, (B)NROM mode
      5'b01_0?_?  :  a53prg = {outer[5:1], inner[0],   prg_ain[14]};  // 64K banks, (B)NROM mode
      5'b10_0?_?  :  a53prg = {outer[5:2], inner[1:0], prg_ain[14]};  // 128K banks, (B)NROM mode
      5'b11_0?_?  :  a53prg = {outer[5:3], inner[2:0], prg_ain[14]};  // 256K banks, (B)NROM mode
      
      5'b00_10_1,
      5'b00_11_0  :  a53prg = {outer[5:0], inner[0]};             // 32K banks, UNROM mode
      5'b01_10_1,
      5'b01_11_0  :  a53prg = {outer[5:1], inner[1:0]};           // 64K banks, UNROM mode
      5'b10_10_1,
      5'b10_11_0  :  a53prg = {outer[5:2], inner[2:0]};           // 128K banks, UNROM mode
      5'b11_10_1,
      5'b11_11_0  :  a53prg = {outer[5:3], inner[3:0]};           // 256K banks, UNROM mode
      
      default     :  a53prg = {outer[5:0],             prg_ain[14]};  // 16K fixed bank
      endcase
    end

  assign vram_ce = chr_ain[13];
  assign prg_aout = {1'b0, (a53prg & 7'b0011111), prg_ain[13:0]};
  assign prg_allow = prg_ain[15] && !prg_write;
  assign chr_allow = flags[15];
  assign chr_aout = {7'b10_0000_0, a53chr, chr_ain[12:0]};
endmodule
