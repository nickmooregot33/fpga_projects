
module SpriteRAM(input clk, input ce,
                 input reset_line,          // OAM evaluator needs to be reset before processing is started.
                 input sprites_enabled,     // Set to 1 if evaluations are enabled
                 input exiting_vblank,      // Set to 1 when exiting vblank so spr_overflow can be reset
                 input obj_size,            // Set to 1 if objects are 16 pixels.
                 input [8:0] scanline,      // Current scan line (compared against Y)
                 input [8:0] cycle,         // Current cycle.
                 output reg [7:0] oam_bus,  // Current value on the OAM bus, returned to NES through $2004.
                 input oam_ptr_load,        // Load oam with specified value, when writing to NES $2003.
                 input oam_load,            // Load oam_ptr with specified value, when writing to NES $2004.
                 input [7:0] data_in,       // New value for oam or oam_ptr
                 output reg spr_overflow,   // Set to true if we had more than 8 objects on a scan line. Reset when exiting vblank.
                 output reg sprite0);       // True if sprite#0 is included on the scan line currently being painted.
  reg [7:0] sprtemp[0:31];   // Sprite Temporary Memory. 32 bytes.
  reg [7:0] oam[0:255];      // Sprite OAM. 256 bytes.
  reg [7:0] oam_ptr;         // Pointer into oam_ptr.
  reg [2:0] p;               // Upper 3 bits of pointer into temp, the lower bits are oam_ptr[1:0].
  reg [1:0] state;           // Current state machine state
  wire [7:0] oam_data = oam[oam_ptr];
  // Compute the current address we read/write in sprtemp.
  reg [4:0] sprtemp_ptr;
  // Check if the current Y coordinate is inside.
  wire [8:0] spr_y_coord = scanline - {1'b0, oam_data};
  wire spr_is_inside = (spr_y_coord[8:4] == 0) && (obj_size || spr_y_coord[3] == 0);
  reg [7:0] new_oam_ptr;     // [wire] New value for oam ptr
  reg [1:0] oam_inc;         // [wire] How much to increment oam ptr
  reg sprite0_curr;          // If sprite0 is included on the line being processed.
  reg oam_wrapped;           // [wire] if new_oam or new_p wrapped.
  
  wire [7:0] sprtemp_data = sprtemp[sprtemp_ptr];
  always @*  begin
    // Compute address to read/write in temp sprite ram
    casez({cycle[8], cycle[2]}) 
    2'b0_?: sprtemp_ptr = {p, oam_ptr[1:0]};
    2'b1_0: sprtemp_ptr = {cycle[5:3], cycle[1:0]}; // 1-4. Read Y, Tile, Attribs
    2'b1_1: sprtemp_ptr = {cycle[5:3], 2'b11};      // 5-8. Keep reading X.
    endcase
  end
    
  always @* begin
    /* verilator lint_off CASEOVERLAP */
    // Compute value to return to cpu through $2004. And also the value that gets written to temp sprite ram.
    casez({sprites_enabled, cycle[8], cycle[6], state, oam_ptr[1:0]})
    7'b1_10_??_??: oam_bus = sprtemp_data;         // At cycle 256-319 we output what's in sprite temp ram
    7'b1_??_00_??: oam_bus = 8'b11111111;                  // On the first 64 cycles (while inside state 0), we output 0xFF.
    7'b1_??_01_00: oam_bus = {4'b0000, spr_y_coord[3:0]};  // Y coord that will get written to temp ram.
    7'b?_??_??_10: oam_bus = {oam_data[7:5], 3'b000, oam_data[1:0]}; // Bits 2-4 of attrib are always zero when reading oam.
    default:       oam_bus = oam_data;                     // Default to outputting from oam.
    endcase
  end

  always @* begin
    // Compute incremented oam counters
    casez ({oam_load, state, oam_ptr[1:0]})
    5'b1_??_??: oam_inc = {oam_ptr[1:0] == 3, 1'b1};       // Always increment by 1 when writing to oam.
    5'b0_00_??: oam_inc = 2'b01;                           // State 0: On the the first 64 cycles we fill temp ram with 0xFF, increment low bits.
    5'b0_01_00: oam_inc = {!spr_is_inside, spr_is_inside}; // State 1: Copy Y coordinate and increment oam by 1 if it's inside, otherwise 4.
    5'b0_01_??: oam_inc = {oam_ptr[1:0] == 3, 1'b1};       // State 1: Copy remaining 3 bytes of the oam.
    // State 3: We've had more than 8 sprites. Set overflow flag if we found a sprite that overflowed.
    // NES BUG: It increments both low and high counters.
    5'b0_11_??: oam_inc = 2'b11;
    // While in the final state, keep incrementing the low bits only until they're zero.
    5'b0_10_??: oam_inc = {1'b0, oam_ptr[1:0] != 0};
    endcase
    /* verilator lint_on CASEOVERLAP */
    new_oam_ptr[1:0] = oam_ptr[1:0] + {1'b0, oam_inc[0]};
    {oam_wrapped, new_oam_ptr[7:2]} = {1'b0, oam_ptr[7:2]} + {6'b0, oam_inc[1]};
  end
  always @(posedge clk) if (ce) begin
     
    // Some bits of the OAM are hardwired to zero.
    if (oam_load)
      oam[oam_ptr] <= (oam_ptr & 3) == 2 ? data_in & 8'hE3: data_in;
    if (cycle[0] && sprites_enabled || oam_load || oam_ptr_load) begin
      oam_ptr <= oam_ptr_load ? data_in : new_oam_ptr;
    end
    // Set overflow flag?
    if (sprites_enabled && state == 2'b11 && spr_is_inside)
      spr_overflow <= 1;
    // Remember if sprite0 is included on the scanline, needed for hit test later.
    sprite0_curr <= (state == 2'b01 && oam_ptr[7:2] == 0 && spr_is_inside || sprite0_curr);
    
//    if (scanline == 0 && cycle[0] && (state == 2'b01 || state == 2'b00))
//      $write("Drawing sprite %d/%d. bus=%d oam_ptr=%X->%X oam_data=%X p=%d (%d %d %d)\n", scanline, cycle, oam_bus, oam_ptr, new_oam_ptr, oam_data, p,
//         cycle[0] && sprites_enabled, oam_load, oam_ptr_load);
    
    // Always writing to temp ram while we're in state 0 or 1.
    if (!state[1]) sprtemp[sprtemp_ptr] <= oam_bus;
    // Update state machine on every second cycle.
    if (cycle[0]) begin
      // Increment p whenever oam_ptr carries in state 0 or 1.
      if (!state[1] && oam_ptr[1:0] == 2'b11) p <= p + 1;
      // Set sprite0 if sprite1 was included on the scan line
      casez({state, (p == 7) && (oam_ptr[1:0] == 2'b11), oam_wrapped})
      4'b00_0_?: state <= 2'b00;  // State #0: Keep filling
      4'b00_1_?: state <= 2'b01;  // State #0: Until we filled 64 items.
      4'b01_?_1: state <= 2'b10;  // State #1: Goto State 2 if processed all OAM
      4'b01_1_0: state <= 2'b11;  // State #1: Goto State 3 if we found 8 sprites
      4'b01_0_0: state <= 2'b01;  // State #1: Keep comparing Y coordinates.
      4'b11_?_1: state <= 2'b10;  // State #3: Goto State 2 if processed all OAM
      4'b11_?_0: state <= 2'b11;  // State #3: Keep comparing Y coordinates
      4'b10_?_?: state <= 2'b10;  // Stuck in state 2.
      endcase
    end
    if (reset_line) begin
      state <= 0;
      p <= 0;
      oam_ptr <= 0;
      sprite0_curr <= 0;
      sprite0 <= sprite0_curr;
    end
    if (exiting_vblank)
      spr_overflow <= 0;
  end
endmodule  // SpriteRAM

