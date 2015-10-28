// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.


// Mapper Status:
// 0 = Working
// 1 = Working
// 2 = Working
// 3 = Working
// 4 = Working

// 5 = Not Implemented (MMC5)
// 7 = Working
// 9 = Working
// 11 = Working
// 13 = Working
// 15 = Works
// 28 = Working
// 34 = Working
// 41 = Working
// 47 = Working
// 64 = Tons of GFX bugs
// 66 = Working
// 68 = Working
// 69 = Working
// 71 = Working
// 79 = Working
// 105 = Working
// 113 = Working
// 118 = Working
// 119 = Working
// 158 = Tons of GFX bugs
// 228 = Working
// 232 = Working
// 232 = Not Tested

module MultiMapper(input clk, input ce, input ppu_ce, input reset,
                   input [19:0] ppuflags,                           // Misc flags from PPU for MMC5 cheating
                   input [31:0] flags,                              // Misc flags from ines header {prg_size(3), chr_size(3), mapper(8)}
                   input [15:0] prg_ain, output reg [21:0] prg_aout,// PRG Input / Output Address Lines
                   input prg_read, prg_write,                       // PRG Read / write signals
                   input [7:0] prg_din, output reg [7:0] prg_dout,  // PRG Data
                   input [7:0] prg_from_ram,                        // PRG Data from RAM
                   output reg prg_allow,                            // PRG Allow write access
                   input chr_read,                                  // Read from CHR
                   input [13:0] chr_ain, output reg [21:0] chr_aout,// CHR Input / Output Address Lines
                   output reg [7:0] chr_dout,                       // Value to override CHR data with
                   output reg has_chr_dout,                         // True if CHR data should be overridden
                   output reg chr_allow,                            // CHR Allow write
                   output reg vram_a10,                             // CHR Value for A10 address line
                   output reg vram_ce,                              // CHR True if the address should be routed to the internal 2kB VRAM.
                   output reg irq);
  wire mmc0_prg_allow, mmc0_vram_a10, mmc0_vram_ce, mmc0_chr_allow;
  wire [21:0] mmc0_prg_addr, mmc0_chr_addr;
  MMC0 mmc0(clk, ce, flags, prg_ain, mmc0_prg_addr, prg_read, prg_write, prg_din, mmc0_prg_allow,
                            chr_ain, mmc0_chr_addr, mmc0_chr_allow, mmc0_vram_a10, mmc0_vram_ce);

  wire mmc1_prg_allow, mmc1_vram_a10, mmc1_vram_ce, mmc1_chr_allow;
  wire [21:0] mmc1_prg_addr, mmc1_chr_addr;
  MMC1 mmc1(clk, ce, reset, flags, prg_ain, mmc1_prg_addr, prg_read, prg_write, prg_din, mmc1_prg_allow,
                                   chr_ain, mmc1_chr_addr, mmc1_chr_allow, mmc1_vram_a10, mmc1_vram_ce);

  wire map28_prg_allow, map28_vram_a10, map28_vram_ce, map28_chr_allow;
  wire [21:0] map28_prg_addr, map28_chr_addr;
  Mapper28 map28(clk, ce, reset, flags, prg_ain, map28_prg_addr, prg_read, prg_write, prg_din, map28_prg_allow,
                                        chr_ain, map28_chr_addr, map28_chr_allow, map28_vram_a10, map28_vram_ce);

  wire mmc2_prg_allow, mmc2_vram_a10, mmc2_vram_ce, mmc2_chr_allow;
  wire [21:0] mmc2_prg_addr, mmc2_chr_addr;
  MMC2 mmc2(clk, ppu_ce, reset, flags, prg_ain, mmc2_prg_addr, prg_read, prg_write, prg_din, mmc2_prg_allow,
                                   chr_read, chr_ain, mmc2_chr_addr, mmc2_chr_allow, mmc2_vram_a10, mmc2_vram_ce);

  wire mmc3_prg_allow, mmc3_vram_a10, mmc3_vram_ce, mmc3_chr_allow, mmc3_irq;
  wire [21:0] mmc3_prg_addr, mmc3_chr_addr;
  MMC3 mmc3(clk, ppu_ce, reset, flags, prg_ain, mmc3_prg_addr, prg_read, prg_write, prg_din, mmc3_prg_allow,
                                   chr_ain, mmc3_chr_addr, mmc3_chr_allow, mmc3_vram_a10, mmc3_vram_ce, mmc3_irq);

  wire mmc5_prg_allow, mmc5_vram_a10, mmc5_vram_ce, mmc5_chr_allow, mmc5_irq;
  wire [21:0] mmc5_prg_addr, mmc5_chr_addr;
  wire [7:0] mmc5_chr_dout, mmc5_prg_dout;
  wire mmc5_has_chr_dout;
  MMC5 mmc5(clk, ppu_ce, reset, flags, ppuflags, prg_ain, mmc5_prg_addr, prg_read, prg_write, prg_din, mmc5_prg_dout, mmc5_prg_allow,
                                   chr_ain, mmc5_chr_addr, mmc5_chr_dout, mmc5_has_chr_dout, 
                                   mmc5_chr_allow, mmc5_vram_a10, mmc5_vram_ce, mmc5_irq);

  wire map13_prg_allow, map13_vram_a10, map13_vram_ce, map13_chr_allow;
  wire [21:0] map13_prg_addr, map13_chr_addr;
  Mapper13 map13(clk, ce, reset, flags, prg_ain, map13_prg_addr, prg_read, prg_write, prg_din, map13_prg_allow,
                                        chr_ain, map13_chr_addr, map13_chr_allow, map13_vram_a10, map13_vram_ce);

  wire map15_prg_allow, map15_vram_a10, map15_vram_ce, map15_chr_allow;
  wire [21:0] map15_prg_addr, map15_chr_addr;
  Mapper15 map15(clk, ce, reset, flags, prg_ain, map15_prg_addr, prg_read, prg_write, prg_din, map15_prg_allow,
                                        chr_ain, map15_chr_addr, map15_chr_allow, map15_vram_a10, map15_vram_ce);

  wire map34_prg_allow, map34_vram_a10, map34_vram_ce, map34_chr_allow;
  wire [21:0] map34_prg_addr, map34_chr_addr;
  Mapper34 map34(clk, ce, reset, flags, prg_ain, map34_prg_addr, prg_read, prg_write, prg_din, map34_prg_allow,
                                        chr_ain, map34_chr_addr, map34_chr_allow, map34_vram_a10, map34_vram_ce);

  wire map41_prg_allow, map41_vram_a10, map41_vram_ce, map41_chr_allow;
  wire [21:0] map41_prg_addr, map41_chr_addr;
  Mapper41 map41(clk, ce, reset, flags, prg_ain, map41_prg_addr, prg_read, prg_write, prg_din, map41_prg_allow,
                                        chr_ain, map41_chr_addr, map41_chr_allow, map41_vram_a10, map41_vram_ce);

  wire map66_prg_allow, map66_vram_a10, map66_vram_ce, map66_chr_allow;
  wire [21:0] map66_prg_addr, map66_chr_addr;
  Mapper66 map66(clk, ce, reset, flags, prg_ain, map66_prg_addr, prg_read, prg_write, prg_din, map66_prg_allow,
                                        chr_ain, map66_chr_addr, map66_chr_allow, map66_vram_a10, map66_vram_ce);

  wire map68_prg_allow, map68_vram_a10, map68_vram_ce, map68_chr_allow;
  wire [21:0] map68_prg_addr, map68_chr_addr;
  Mapper68 map68(clk, ce, reset, flags, prg_ain, map68_prg_addr, prg_read, prg_write, prg_din, map68_prg_allow,
                                        chr_ain, map68_chr_addr, map68_chr_allow, map68_vram_a10, map68_vram_ce);

  wire map69_prg_allow, map69_vram_a10, map69_vram_ce, map69_chr_allow, map69_irq;
  wire [21:0] map69_prg_addr, map69_chr_addr;
  Mapper69 map69(clk, ce, reset, flags, prg_ain, map69_prg_addr, prg_read, prg_write, prg_din, map69_prg_allow,
                                        chr_ain, map69_chr_addr, map69_chr_allow, map69_vram_a10, map69_vram_ce, map69_irq);

  wire map71_prg_allow, map71_vram_a10, map71_vram_ce, map71_chr_allow;
  wire [21:0] map71_prg_addr, map71_chr_addr;
  Mapper71 map71(clk, ce, reset, flags, prg_ain, map71_prg_addr, prg_read, prg_write, prg_din, map71_prg_allow,
                                        chr_ain, map71_chr_addr, map71_chr_allow, map71_vram_a10, map71_vram_ce);

  wire map79_prg_allow, map79_vram_a10, map79_vram_ce, map79_chr_allow;
  wire [21:0] map79_prg_addr, map79_chr_addr;
  Mapper79 map79(clk, ce, reset, flags, prg_ain, map79_prg_addr, prg_read, prg_write, prg_din, map79_prg_allow,
                                        chr_ain, map79_chr_addr, map79_chr_allow, map79_vram_a10, map79_vram_ce);


  wire map228_prg_allow, map228_vram_a10, map228_vram_ce, map228_chr_allow;
  wire [21:0] map228_prg_addr, map228_chr_addr;
  Mapper228 map228(clk, ce, reset, flags, prg_ain, map228_prg_addr, prg_read, prg_write, prg_din, map228_prg_allow,
                                          chr_ain, map228_chr_addr, map228_chr_allow, map228_vram_a10, map228_vram_ce);


  wire map234_prg_allow, map234_vram_a10, map234_vram_ce, map234_chr_allow;
  wire [21:0] map234_prg_addr, map234_chr_addr;
  Mapper234 map234(clk, ce, reset, flags, prg_ain, map234_prg_addr, prg_read, prg_write, prg_from_ram, map234_prg_allow,
                                          chr_ain, map234_chr_addr, map234_chr_allow, map234_vram_a10, map234_vram_ce);

  wire rambo1_prg_allow, rambo1_vram_a10, rambo1_vram_ce, rambo1_chr_allow, rambo1_irq;
  wire [21:0] rambo1_prg_addr, rambo1_chr_addr;
  Rambo1 rambo1(clk, ce, reset, flags, prg_ain, rambo1_prg_addr, prg_read, prg_write, prg_din, rambo1_prg_allow,
                                   chr_ain, rambo1_chr_addr, rambo1_chr_allow, rambo1_vram_a10, rambo1_vram_ce, rambo1_irq);

  wire [21:0] nesev_prg_addr, nesev_chr_addr;
  wire nesev_irq;
  NesEvent nesev(clk, ce, reset, prg_ain, nesev_prg_addr, chr_ain, nesev_chr_addr, mmc1_chr_addr[16:13], mmc1_prg_addr, nesev_irq);
  
  // Mask 
  reg [5:0] prg_mask;
  reg [6:0] chr_mask;

  always @* begin
    case(flags[10:8])
    0: prg_mask = 6'b000000;
    1: prg_mask = 6'b000001;
    2: prg_mask = 6'b000011;
    3: prg_mask = 6'b000111;
    4: prg_mask = 6'b001111;
    5: prg_mask = 6'b011111;
    default: prg_mask = 6'b111111;
    endcase

    case(flags[13:11])
    0: chr_mask = 7'b0000000;
    1: chr_mask = 7'b0000001;
    2: chr_mask = 7'b0000011;
    3: chr_mask = 7'b0000111;
    4: chr_mask = 7'b0001111;
    5: chr_mask = 7'b0011111;
    6: chr_mask = 7'b0111111;
    7: chr_mask = 7'b1111111;
    endcase
    
    irq = 0;
    prg_dout = 8'hff;
    has_chr_dout = 0;
    chr_dout = mmc5_chr_dout;
        
    case(flags[7:0])
    1:  {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {mmc1_prg_addr, mmc1_prg_allow, mmc1_chr_addr, mmc1_vram_a10, mmc1_vram_ce, mmc1_chr_allow};
    9:  {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {mmc2_prg_addr, mmc2_prg_allow, mmc2_chr_addr, mmc2_vram_a10, mmc2_vram_ce, mmc2_chr_allow};
    118, // TxSROM connects A17 to CIRAM A10.
    119, // TQROM  uses the Nintendo MMC3 like other TxROM boards but uses the CHR bank number specially.
    47,  // Mapper 047 is a MMC3 multicart
    4:  {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow, irq} = {mmc3_prg_addr, mmc3_prg_allow, mmc3_chr_addr, mmc3_vram_a10, mmc3_vram_ce, mmc3_chr_allow, mmc3_irq};

    5:  {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow, has_chr_dout, prg_dout, irq} = {mmc5_prg_addr, mmc5_prg_allow, mmc5_chr_addr, mmc5_vram_a10, mmc5_vram_ce, mmc5_chr_allow, mmc5_has_chr_dout, mmc5_prg_dout, mmc5_irq};

    0,
    2,
    3,
    7,
    28: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {map28_prg_addr, map28_prg_allow, map28_chr_addr, map28_vram_a10, map28_vram_ce, map28_chr_allow};

    13: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {map13_prg_addr, map13_prg_allow, map13_chr_addr, map13_vram_a10, map13_vram_ce, map13_chr_allow};
    15: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {map15_prg_addr, map15_prg_allow, map15_chr_addr, map15_vram_a10, map15_vram_ce, map15_chr_allow};

    34: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {map34_prg_addr, map34_prg_allow, map34_chr_addr, map34_vram_a10, map34_vram_ce, map34_chr_allow};
    41: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {map41_prg_addr, map41_prg_allow, map41_chr_addr, map41_vram_a10, map41_vram_ce, map41_chr_allow};

    64,
    158: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow, irq} = {rambo1_prg_addr, rambo1_prg_allow, rambo1_chr_addr, rambo1_vram_a10, rambo1_vram_ce, rambo1_chr_allow, rambo1_irq};

    11,
    66: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {map66_prg_addr, map66_prg_allow, map66_chr_addr, map66_vram_a10, map66_vram_ce, map66_chr_allow};
    68: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}      = {map68_prg_addr, map68_prg_allow, map68_chr_addr, map68_vram_a10, map68_vram_ce, map68_chr_allow};
    69: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow, irq} = {map69_prg_addr, map69_prg_allow, map69_chr_addr, map69_vram_a10, map69_vram_ce, map69_chr_allow, map69_irq};

    71,
    232: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}     = {map71_prg_addr, map71_prg_allow, map71_chr_addr, map71_vram_a10, map71_vram_ce, map71_chr_allow};

    79,
    113: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}     = {map79_prg_addr, map79_prg_allow, map79_chr_addr, map79_vram_a10, map79_vram_ce, map79_chr_allow};

    105: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow, irq}= {nesev_prg_addr, mmc1_prg_allow, nesev_chr_addr, mmc1_vram_a10, mmc1_vram_ce, mmc1_chr_allow, nesev_irq};

    228: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}     = {map228_prg_addr, map228_prg_allow, map228_chr_addr, map228_vram_a10, map228_vram_ce, map228_chr_allow};
    234: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow}     = {map234_prg_addr, map234_prg_allow, map234_chr_addr, map234_vram_a10, map234_vram_ce, map234_chr_allow};
    default: {prg_aout, prg_allow, chr_aout, vram_a10, vram_ce, chr_allow} = {mmc0_prg_addr, mmc0_prg_allow, mmc0_chr_addr, mmc0_vram_a10, mmc0_vram_ce, mmc0_chr_allow};
    endcase
    if (prg_aout[21:20] == 2'b00)
      prg_aout[19:0] = {prg_aout[19:14] & prg_mask, prg_aout[13:0]};
    if (chr_aout[21:20] == 2'b10)
      chr_aout[19:0] = {chr_aout[19:13] & chr_mask, chr_aout[12:0]};
    // Remap the CHR address into VRAM, if needed.
    chr_aout = vram_ce ? {11'b11_0000_0000_0, vram_a10, chr_ain[9:0]} : chr_aout;
    prg_aout = (prg_ain < 'h2000) ? {11'b11_1000_0000_0, prg_ain[10:0]} : prg_aout;
    prg_allow = prg_allow || (prg_ain < 'h2000);
  end
endmodule

// PRG       = 0....
// CHR       = 10...
// CHR-VRAM  = 1100
// CPU-RAM   = 1110
// CARTRAM   = 1111
                 