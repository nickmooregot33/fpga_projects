



// iNES mapper 64 and 158 - Tengen's version of MMC3
module Rambo1(input clk, input ce, input reset,
              input [31:0] flags,
              input [15:0] prg_ain, output [21:0] prg_aout,
              input prg_read, prg_write,                   // Read / write signals
              input [7:0] prg_din,
              output prg_allow,                            // Enable access to memory for the specified operation.
              input [13:0] chr_ain, output [21:0] chr_aout,
              output chr_allow,                            // Allow write
              output vram_a10,                             // Value for A10 address line
              output vram_ce,                              // True if the address should be routed to the internal 2kB VRAM.
              output reg irq);
  reg [3:0] bank_select;             // Register to write to next
  reg prg_rom_bank_mode;             // Mode for PRG banking
  reg chr_K;                         // Mode for CHR banking
  reg chr_a12_invert;                // Mode for CHR banking
  reg mirroring;                     // 0 = vertical, 1 = horizontal
  reg irq_enable, irq_reload;        // IRQ enabled, and IRQ reload requested
  reg [7:0] irq_latch, counter;      // IRQ latch value and current counter
  reg want_irq;
  reg [7:0] chr_bank_0, chr_bank_1;  // Selected CHR banks
  reg [7:0] chr_bank_2, chr_bank_3, chr_bank_4, chr_bank_5;
  reg [7:0] chr_bank_8, chr_bank_9;
  reg [5:0] prg_bank_0, prg_bank_1, prg_bank_2;  // Selected PRG banks
  reg irq_cycle_mode;
  reg [1:0] cycle_counter;
 
  // Mapper has vram_a10 wired to CHR A17
  wire mapper64 = (flags[7:0] == 64);

  reg is_interrupt;  // Not a reg!
  
  // This code detects rising edges on a12.
  reg old_a12_edge;
  reg [1:0] a12_ctr;
  wire a12_edge = (chr_ain[12] && a12_ctr == 0) || old_a12_edge;
  always @(posedge clk) begin
    old_a12_edge <= a12_edge && !ce;
    a12_ctr <= chr_ain[12] ? 2'b11 : (a12_ctr != 0 && ce) ? a12_ctr - 2'b01 : a12_ctr;
  end
  
  always @(posedge clk) if (reset) begin
    bank_select <= 0;
    prg_rom_bank_mode <= 0;
    chr_K <= 0;
    chr_a12_invert <= 0;
    mirroring <= 0;
    {irq_enable, irq_reload} <= 0;
    {irq_latch, counter} <= 0;
    want_irq <= 0;
    {chr_bank_0, chr_bank_1} <= 0;
    {chr_bank_2, chr_bank_3, chr_bank_4, chr_bank_5} <= 0;
    {chr_bank_8, chr_bank_9} <= 0;
    {prg_bank_0, prg_bank_1, prg_bank_2} <= 0;
    irq_cycle_mode <= 0;
    cycle_counter <= 0;
    irq <= 0;
  end else if (ce) begin
    cycle_counter <= cycle_counter + 1;
        
    if (prg_write && prg_ain[15]) begin
      case({prg_ain[14:13], prg_ain[0]})
      // Bank select ($8000-$9FFE, even)
      3'b00_0: {chr_a12_invert, prg_rom_bank_mode, chr_K, bank_select} <= {prg_din[7:5], prg_din[3:0]}; 
      // Bank data ($8001-$9FFF, odd)
      3'b00_1:
        case (bank_select) 
        0: chr_bank_0 <= prg_din;       // Select 2 (K=0) or 1 (K=1) KB CHR bank at PPU $0000 (or $1000);
        1: chr_bank_1 <= prg_din;       // Select 2 (K=0) or 1 (K=1) KB CHR bank at PPU $0800 (or $1800);
        2: chr_bank_2 <= prg_din;       // Select 1 KB CHR bank at PPU $1000-$13FF (or $0000-$03FF);
        3: chr_bank_3 <= prg_din;       // Select 1 KB CHR bank at PPU $1400-$17FF (or $0400-$07FF);
        4: chr_bank_4 <= prg_din;       // Select 1 KB CHR bank at PPU $1800-$1BFF (or $0800-$0BFF);
        5: chr_bank_5 <= prg_din;       // Select 1 KB CHR bank at PPU $1C00-$1FFF (or $0C00-$0FFF);
        6: prg_bank_0 <= prg_din[5:0];  // Select 8 KB PRG ROM bank at $8000-$9FFF (or $C000-$DFFF);
        7: prg_bank_1 <= prg_din[5:0];  // Select 8 KB PRG ROM bank at $A000-$BFFF
        8: chr_bank_8 <= prg_din;       // If K=1, Select 1 KB CHR bank at PPU $0400 (or $1400);
        9: chr_bank_9 <= prg_din;       // If K=1, Select 1 KB CHR bank at PPU $0C00 (or $1C00)
        15: prg_bank_2 <= prg_din[5:0]; // Select 8 KB PRG ROM bank at $C000-$DFFF (or $8000-$9FFF);
        endcase
      3'b01_0: mirroring <= prg_din[0];                   // Mirroring ($A000-$BFFE, even)
      3'b01_1: begin end
      3'b10_0: irq_latch <= prg_din;                      // IRQ latch ($C000-$DFFE, even)
      3'b10_1: begin 
                 {irq_reload, irq_cycle_mode} <= {1'b1, prg_din[0]}; // IRQ reload ($C001-$DFFF, odd)
                 cycle_counter <= 0;
               end
      3'b11_0: {irq_enable, irq} <= 2'b0;                 // IRQ disable ($E000-$FFFE, even)
      3'b11_1: irq_enable <= 1;                           // IRQ enable ($E001-$FFFF, odd)
      endcase
    end
    is_interrupt = irq_cycle_mode ? (cycle_counter == 3) : a12_edge;
    if (is_interrupt) begin
      if (irq_reload || counter == 0) begin
        counter <= irq_latch;
        want_irq <= irq_reload;
      end else begin
        counter <= counter - 1;
        want_irq <= 1;
      end
      if (counter == 0 && want_irq && !irq_reload && irq_enable)
        irq <= 1;
      irq_reload <= 0;
    end
    
  end
  // The PRG bank to load. Each increment here is 8kb. So valid values are 0..63.
  reg [5:0] prgsel;
  always @* begin
    casez({prg_ain[14:13], prg_rom_bank_mode})
    3'b00_0: prgsel = prg_bank_0;  // $8000 is R:6
    3'b01_0: prgsel = prg_bank_1;  // $A000 is R:7
    3'b10_0: prgsel = prg_bank_2;  // $C000 is R:F
    3'b11_0: prgsel = 6'b111111;   // $E000 fixed to last bank
    3'b00_1: prgsel = prg_bank_2;  // $8000 is R:F
    3'b01_1: prgsel = prg_bank_0;  // $A000 is R:6
    3'b10_1: prgsel = prg_bank_1;  // $C000 is R:7
    3'b11_1: prgsel = 6'b111111;   // $E000 fixed to last bank
    endcase
  end
  // The CHR bank to load. Each increment here is 1kb. So valid values are 0..255.
  reg [7:0] chrsel;
  always @* begin
    casez({chr_ain[12] ^ chr_a12_invert, chr_ain[11], chr_ain[10], chr_K})
    4'b00?_0: chrsel = {chr_bank_0[7:1], chr_ain[10]};
    4'b01?_0: chrsel = {chr_bank_1[7:1], chr_ain[10]};
    4'b000_1: chrsel = chr_bank_0;
    4'b001_1: chrsel = chr_bank_8;
    4'b010_1: chrsel = chr_bank_1;
    4'b011_1: chrsel = chr_bank_9;
    4'b100_?: chrsel = chr_bank_2;
    4'b101_?: chrsel = chr_bank_3;
    4'b110_?: chrsel = chr_bank_4;
    4'b111_?: chrsel = chr_bank_5;
    endcase
  end
  assign prg_aout = {3'b00_0,  prgsel, prg_ain[12:0]};
  assign {chr_allow, chr_aout} = {flags[15], 4'b10_00, chrsel, chr_ain[9:0]};
  assign prg_allow = prg_ain[15] && !prg_write;
  assign vram_a10 = mapper64 ? chrsel[7] :  // Mapper 64 controls mirroring by switching the top bits of the CHR address
                    mirroring ? chr_ain[11] : chr_ain[10];
  assign vram_ce = chr_ain[13];
endmodule
