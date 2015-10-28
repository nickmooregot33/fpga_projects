 
module PPU(input clk, input ce, input reset,   // input clock  21.48 MHz / 4. 1 clock cycle = 1 pixel
           output [5:0] color, // output color value, one pixel outputted every clock
           input [7:0] din,   // input data from bus
           output [7:0] dout, // output data to CPU
           input [2:0] ain,   // input address from CPU
           input read,        // read
           input write,       // write
           output nmi,    // one while inside vblank
           output vram_r, // read from vram active
           output vram_w, // write to vram active
           output [13:0] vram_a, // vram address
           input [7:0] vram_din, // vram input
           output [7:0] vram_dout,
           output [8:0] scanline,
           output [8:0] cycle,
           output [19:0] mapper_ppu_flags);
  // These are stored in control register 0
  reg obj_patt; // Object pattern table
  reg bg_patt;  // Background pattern table
  reg obj_size; // 1 if sprites are 16 pixels high, else 0.
  reg vbl_enable;  // Enable VBL flag
  // These are stored in control register 1
  reg grayscale; // Disable color burst
  reg playfield_clip;     // 0: Left side 8 pixels playfield clipping
  reg object_clip;        // 0: Left side 8 pixels object clipping
  reg enable_playfield;   // Enable playfield display
  reg enable_objects;     // Enable objects display
  reg [2:0] color_intensity; // Color intensity
  
  initial begin
    obj_patt = 0;
    bg_patt = 0;
    obj_size = 0;
    vbl_enable = 0;
    grayscale = 0;
    playfield_clip = 0;
    object_clip = 0;
    enable_playfield = 0;
    enable_objects = 0;
    color_intensity = 0;
  end
  
  reg nmi_occured;         // True if NMI has occured but not cleared.
  reg [7:0] vram_latch;
  // Clock generator
  wire is_in_vblank;        // True if we're in VBLANK
  //wire [8:0] scanline;      // Current scanline
  //wire [8:0] cycle;         // Current cycle inside of the line
  wire end_of_line;         // At the last pixel of a line
  wire at_last_cycle_group; // At the very last cycle group of the scan line.
  wire exiting_vblank;      // At the very last cycle of the vblank
  wire entering_vblank;     // 
  wire is_pre_render_line;  // True while we're on the pre render scanline
  wire is_rendering = (enable_playfield || enable_objects) && !is_in_vblank && scanline != 240;
  
  ClockGen clock(clk, ce, reset, is_rendering, scanline, cycle, is_in_vblank, end_of_line, at_last_cycle_group,
                 exiting_vblank, entering_vblank, is_pre_render_line);
  
  
  // The loopy module handles updating of the loopy address
  wire [14:0] loopy;
  wire [2:0] fine_x_scroll;
  LoopyGen loopy0(clk, ce, is_rendering, ain, din, read, write, is_pre_render_line, cycle, loopy, fine_x_scroll);
  // Set to true if the current ppu_addr pointer points into
  // palette ram.
  wire is_pal_address = (loopy[13:8] == 6'b111111);

  // Paints background
  wire [7:0] bg_name_table;
  wire [3:0] bg_pixel_noblank;
  BgPainter bg_painter(clk, ce, !at_last_cycle_group, cycle[2:0], fine_x_scroll, loopy, bg_name_table, vram_din, bg_pixel_noblank);
  
  // Blank out BG in the leftmost 8 pixels?
  wire show_bg_on_pixel = (playfield_clip || (cycle[7:3] != 0)) && enable_playfield;
  wire [3:0] bg_pixel = {bg_pixel_noblank[3:2], show_bg_on_pixel ? bg_pixel_noblank[1:0] : 2'b00};

  // This will set oam_ptr to 0 right before the scanline 240 and keep it there throughout vblank.
  wire before_line = (enable_playfield || enable_objects) && (exiting_vblank || end_of_line && !is_in_vblank);
  wire [7:0] oam_bus;
  wire sprite_overflow;
  wire obj0_on_line;                        // True if sprite#0 is included on the current line
  SpriteRAM sprite_ram(clk, ce,
                       before_line,         // Condition for resetting the sprite line state.
                       is_rendering,        // Condition for enabling sprite ram logic. Check so we're not on 
                       exiting_vblank,
                       obj_size,
                       scanline, cycle,
                       oam_bus,
                       write && (ain == 3), // Write to oam_ptr
                       write && (ain == 4), // Write to oam[oam_ptr]
                       din,
                       sprite_overflow,
                       obj0_on_line);
  wire [4:0] obj_pixel_noblank;
  wire [12:0] sprite_vram_addr;
  wire is_obj0_pixel;               // True if obj_pixel originates from sprite0.
  wire [3:0] spriteset_load;          // Which subset of the |load_in| to load into SpriteSet
  wire [26:0] spriteset_load_in;      // Bits to load into SpriteSet
  // Between 256..319 (64 cycles), fetches bitmap data for the 8 sprites and fills in the SpriteSet
  // so that it can start drawing on the next frame.
  SpriteAddressGen address_gen(clk, ce,
                               cycle[8] && !cycle[6],     // Load sprites between 256..319
                               obj_size, obj_patt,        // Object size and pattern table
                               cycle[2:0],                // Cycle counter
                               oam_bus,                   // Info from temp buffer.
                               sprite_vram_addr,          // [out] VRAM Address that we want data from
                               vram_din,                  // [in] Data at the specified address
                               spriteset_load,
                               spriteset_load_in);        // Which parts of SpriteGen to load
  // Between 0..255 (256 cycles), draws pixels.
  // Between 256..319 (64 cycles), will be populated for next line
  SpriteSet sprite_gen(clk, ce, !cycle[8], spriteset_load, spriteset_load_in, obj_pixel_noblank, is_obj0_pixel);
  // Blank out obj in the leftmost 8 pixels?    
  wire show_obj_on_pixel = (object_clip || (cycle[7:3] != 0)) && enable_objects;
  wire [4:0] obj_pixel = {obj_pixel_noblank[4:2], show_obj_on_pixel ? obj_pixel_noblank[1:0] : 2'b00};
  
  reg sprite0_hit_bg;            // True if sprite#0 has collided with the BG in the last frame.
  always @(posedge clk) if (ce) begin
    if (exiting_vblank)
      sprite0_hit_bg <= 0;
    else if (is_rendering &&         // Object rendering is enabled
             !cycle[8] &&            // X Pixel 0..255
             cycle[7:0] != 255 &&    // X pixel != 255
             !is_pre_render_line &&  // Y Pixel 0..239
             obj0_on_line &&         // True if sprite#0 is included on the scan line.
             is_obj0_pixel &&        // True if the pixel came from tempram #0.
             show_obj_on_pixel &&
             bg_pixel[1:0] != 0) begin // Background pixel nonzero.
      sprite0_hit_bg <= 1;
      
    end

//    if (!cycle[8] && is_visible_line && obj0_on_line && is_obj0_pixel)
//      $write("Sprite0 hit bg scan %d!!\n", scanline);

//    if (is_obj0_pixel)
//      $write("drawing obj0 pixel %d/%d\n", scanline, cycle);
  end
 
  wire [3:0] pixel;
  wire pixel_is_obj;
  PixelMuxer pixel_muxer(bg_pixel, obj_pixel[3:0], obj_pixel[4], pixel, pixel_is_obj);
 
  // Compute the value to put on the VRAM address bus
  assign vram_a = !is_rendering    ? loopy[13:0] : // VRAM
                  (cycle[2:1] == 0)     ? {2'b10, loopy[11:0]} : // Name table
                  (cycle[2:1] == 1)     ? {2'b10, loopy[11:10], 4'b1111, loopy[9:7], loopy[4:2]} : // Attribute table
                  cycle[8] && !cycle[6] ? {1'b0, sprite_vram_addr} : 
                                          {1'b0, bg_patt, bg_name_table, cycle[1], loopy[14:12]}; // Pattern table bitmap #0, #1
  // Read from VRAM, either when user requested a manual read, or when we're generating pixels.
  assign vram_r = read && (ain == 7) ||
                  is_rendering && cycle[0] == 0 && !end_of_line;
  
  // Write to VRAM?
  assign vram_w = write && (ain == 7) && !is_pal_address && !is_rendering;

  wire [5:0] color2;
  PaletteRam palette_ram(clk, ce, 
                         is_rendering ? {pixel_is_obj, pixel[3:0]} : (is_pal_address ? loopy[4:0] : 5'b0000), // Read addr
                         din[5:0], // Value to write
                         color2,    // Output color
                         write && (ain == 7) && is_pal_address); // Condition for writing
  assign color = grayscale ? {color2[5:4], 4'b0} : color2;
//  always @(posedge clk)  
//  if (scanline == 194 && cycle < 8 && color == 15) begin
//    $write("Pixel black %x %x %x %x %x\n", bg_pixel,obj_pixel,pixel,pixel_is_obj,color);
//  end

 
  always @(posedge clk) if (ce) begin
//    if (!is_in_vblank && write)
//      $write("%d/%d: $200%d <= %x\n", scanline, cycle, ain, din);
    if (write) begin
      case (ain)
      0: begin // PPU Control Register 1
      // t:....BA.. ........ = d:......BA
        obj_patt <= din[3];
        bg_patt <= din[4];
        obj_size <= din[5];
        vbl_enable <= din[7];
        
        //$write("PPU Control #0 <= %X\n", din);
      end
      1: begin // PPU Control Register 2
        grayscale <= din[0];
        playfield_clip <= din[1];
        object_clip <= din[2];
        enable_playfield <= din[3];
        enable_objects <= din[4];
        color_intensity <= din[7:5];
        if (!din[3] && scanline == 59)
          $write("Disabling playfield at cycle %d\n", cycle);
      end
      endcase
    end
     
    // Reset frame specific counters upon exiting vblank
    if (exiting_vblank)
      nmi_occured <= 0;
    // Set the 
    if (entering_vblank)
      nmi_occured <= 1;
    // Reset NMI register when reading from Status
    if (read && ain == 2)
      nmi_occured <= 0;
  end
  
  // If we're triggering a VBLANK NMI 
  assign nmi = nmi_occured && vbl_enable;

  // One cycle after vram_r was asserted, the value
  // is available on the bus.
  reg vram_read_delayed;
  always @(posedge clk) if (ce) begin
    if (vram_read_delayed)
      vram_latch <= vram_din;
    vram_read_delayed = vram_r;
  end
  
  // Value currently being written to video ram
  assign vram_dout = din;

  reg [7:0] latched_dout;
  always @* begin
    case (ain)
    2: latched_dout = {nmi_occured,
               sprite0_hit_bg,
               sprite_overflow,
               5'b00000};
    4: latched_dout = oam_bus;
    default: if (is_pal_address) begin
        latched_dout = {2'b00, color};
      end else begin
        latched_dout = vram_latch;
      end 
    endcase
  end
  
  assign dout = latched_dout;
  
  
  assign mapper_ppu_flags = {scanline, cycle, obj_size, is_rendering};

endmodule  // PPU
