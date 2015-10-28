  
// Generates the current scanline / cycle counters
module ClockGen(input clk, input ce, input reset,
                input is_rendering,
                output reg [8:0] scanline,
                output reg [8:0] cycle,
                output reg is_in_vblank,
                output end_of_line,
                output at_last_cycle_group,
                output exiting_vblank,
                output entering_vblank,
                output reg is_pre_render);
  reg second_frame;
  
  // Scanline 0..239 = picture scan lines
  // Scanline 240 = dummy scan line
  // Scanline 241..260 = VBLANK
  // Scanline -1 = Pre render scanline (Fetches objects for next line)
  assign at_last_cycle_group = (cycle[8:3] == 42);
  // Every second pre-render frame is only 340 cycles instead of 341.
  assign end_of_line = at_last_cycle_group && cycle[3:0] == (is_pre_render && second_frame && is_rendering ? 3 : 4);
  // Set the clock right before vblank begins
  assign entering_vblank = end_of_line && scanline == 240;
  // Set the clock right before vblank ends
  assign exiting_vblank = end_of_line && scanline == 260;
  // New value for is_in_vblank flag
  wire new_is_in_vblank = entering_vblank ? 1'b1 : exiting_vblank ? 1'b0 : is_in_vblank;
  // Set if the current line is line 0..239
  always @(posedge clk) if (reset) begin
    cycle <= 0;
    is_in_vblank <= 1;
  end else if (ce) begin
    cycle <= end_of_line ? 0 : cycle + 1;
    is_in_vblank <= new_is_in_vblank;
  end
//  always @(posedge clk) if (ce) begin
//    $write("%x %x %x %x %x\n", new_is_in_vblank, entering_vblank, exiting_vblank, is_in_vblank, entering_vblank ? 1'b1 : exiting_vblank ? 1'b0 : is_in_vblank);
    
//  end
  always @(posedge clk) if (reset) begin
    scanline <= 0;
    is_pre_render <= 0;
    second_frame <= 0;
  end else if (ce && end_of_line) begin
    // Once the scanline counter reaches end of 260, it gets reset to -1.
    scanline <= exiting_vblank ? 9'b111111111 : scanline + 1;
    // The pre render flag is set while we're on scanline -1.
    is_pre_render <= exiting_vblank;
    
    if (exiting_vblank)
      second_frame <= !second_frame;
  end
  
endmodule // ClockGen
