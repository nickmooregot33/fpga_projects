
// Generates addresses in VRAM where we'll fetch sprite graphics from,
// and populates load, load_in so the SpriteGen can be loaded.
// 10 LUT, 4 Slices
module SpriteAddressGen(input clk, input ce,
                        input enabled,          // If unset, |load| will be all zeros.
                        input obj_size,         // 0: Sprite Height 8, 1: Sprite Height 16.
                        input obj_patt,         // Object pattern table selection
                        input [2:0] cycle,      // Current load cycle. At #4, first bitmap byte is loaded. At #6, second bitmap byte is.
                        input [7:0] temp,       // Input temp data from SpriteTemp. #0 = Y Coord, #1 = Tile, #2 = Attribs, #3 = X Coord
                        output [12:0] vram_addr,// Low bits of address in VRAM that we'd like to read.
                        input [7:0] vram_data,  // Byte of VRAM in the specified address
                        output [3:0] load,      // Which subset of load_in that is now valid, will be loaded into SpritesGen.
                        output [26:0] load_in); // Bits to load into SpritesGen.
  reg [7:0] temp_tile;    // Holds the tile that we will get
  reg [3:0] temp_y;       // Holds the Y coord (will be swapped based on FlipY).
  reg flip_x, flip_y;     // If incoming bitmap data needs to be flipped in the X or Y direction.
  wire load_y =    (cycle == 0);
  wire load_tile = (cycle == 1);
  wire load_attr = (cycle == 2) && enabled;
  wire load_x =    (cycle == 3) && enabled;
  wire load_pix1 = (cycle == 5) && enabled;
  wire load_pix2 = (cycle == 7) && enabled;
  reg dummy_sprite; // Set if attrib indicates the sprite is invalid.
  // Flip incoming vram data based on flipx. Zero out the sprite if it's invalid. The bits are already flipped once.
  wire [7:0] vram_f = dummy_sprite ? 0 : 
                      !flip_x ?      {vram_data[0], vram_data[1], vram_data[2], vram_data[3], vram_data[4], vram_data[5], vram_data[6], vram_data[7]} : 
                                     vram_data;
  wire [3:0] y_f = temp_y ^ {flip_y, flip_y, flip_y, flip_y};
  assign load = {load_pix1, load_pix2, load_x, load_attr};
  assign load_in = {vram_f, vram_f, temp, temp[1:0], temp[5]};
  // If $2000.5 = 0, the tile index data is used as usual, and $2000.3 
  // selects the pattern table to use. If $2000.5 = 1, the MSB of the range 
  // result value become the LSB of the indexed tile, and the LSB of the tile 
  // index value determines pattern table selection. The lower 3 bits of the 
  // range result value are always used as the fine vertical offset into the 
  // selected pattern.
  assign vram_addr = {obj_size ? temp_tile[0] : obj_patt, 
                      temp_tile[7:1], obj_size ? y_f[3] : temp_tile[0], cycle[1], y_f[2:0] };
  always @(posedge clk) if (ce) begin
    if (load_y) temp_y <= temp[3:0];
    if (load_tile) temp_tile <= temp;
    if (load_attr) {flip_y, flip_x, dummy_sprite} <= {temp[7:6], temp[4]};
  end
//  always @(posedge clk) begin
//    if (load[3]) $write("Loading pix1: %x\n", load_in[26:19]);
//    if (load[2]) $write("Loading pix2: %x\n", load_in[18:11]);
//    if (load[1]) $write("Loading x: %x\n", load_in[10:3]);
//
//    if (valid_sprite && enabled)
//      $write("%d. Found %d. Flip:%d%d, Addr: %x, Vram: %x!\n", cycle, temp, flip_x, flip_y, vram_addr, vram_data);
//  end

endmodule  // SpriteAddressGen
