

// #105 - NES-EVENT. Retrofits an MMC3 with lots of extra logic.
module NesEvent(input clk, input ce, input reset,
                input [15:0] prg_ain, output reg [21:0] prg_aout,
                input [13:0] chr_ain, output [21:0] chr_aout,
                input [3:0] mmc1_chr,                   // Upper 4 CHR output control bits from MMC chip
                input [21:0] mmc1_aout,                 // PRG output address from MMC chip
                output irq);
  // $A000-BFFF:   [...I OAA.]
  //      I = IRQ control / initialization toggle
  //      O = PRG Mode/Chip select
  //      A = PRG Reg 'A'
  // Mapper gets "initialized" by setting I bit to 0 then to 1.
  // On powerup and reset, the first 32k of PRG (from the first PRG chip) is selected at $8000 *no matter what*.
  // PRG cannot be swapped until the mapper has been "initialized" by setting the 'I' bit to 0, then to '1'.  This
  // toggling will "unlock" PRG swapping on the mapper.
  reg unlocked, old_val;
  reg [29:0] counter;
  
  reg [3:0] oldbits;
  always @(posedge clk) if (reset) begin
    old_val <= 0;
    unlocked <= 0;
    counter <= 0;
  end else if (ce) begin
    // Handle unlock.
    if (mmc1_chr[3] && !old_val) unlocked <= 1;
    old_val <= mmc1_chr[3];
    // The 'I' bit in $A000 controls the IRQ counter.  When cleared, the IRQ counter counts up every cycle.  When
    // set, the IRQ counter is reset to 0 and stays there (does not count), and the pending IRQ is acknowledged.
    counter <= mmc1_chr[3] ? 0 : counter + 1;
    
    if (mmc1_chr != oldbits) begin
      $write("NESEV Control Bits: %X => %X (%d)\n", oldbits, mmc1_chr, unlocked);
      oldbits <= mmc1_chr;
    end
  end
  // In the official tournament, 'C' was closed, and the others were open, so the counter had to reach $2800000.
  assign irq = (counter[29:25] == 5'b10100);
  always begin
    if (!prg_ain[15]) begin
      // WRAM is always routed as usual.
      prg_aout = mmc1_aout; 
    end else if (!unlocked) begin
      // Not initialized yet, mapper switch disabled.
      prg_aout = {7'b00_0000_0, prg_ain[14:0]}; 
    end else if (mmc1_chr[2] == 0) begin
      // O=0:  Use first PRG chip (first 128k), use 'A' PRG Reg, 32k swap
      prg_aout = {5'b00_000, mmc1_chr[1:0], prg_ain[14:0]};
    end else begin
      // O=1:  Use second PRG chip (second 128k), use 'B' PRG Reg, MMC1 style swap
      prg_aout = mmc1_aout;
    end
  end
  // 8kB CHR RAM.
  assign chr_aout = {9'b10_0000_000, chr_ain[12:0]};
endmodule
