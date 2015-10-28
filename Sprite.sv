
// 8 of these exist, they are used to output sprites.
module Sprite(input clk, input ce,
              input enable,
              input [3:0] load, 
              input [26:0] load_in,
              output [26:0] load_out,
              output [4:0] bits); // Low 4 bits = pixel, high bit = prio
  reg [1:0] upper_color; // Upper 2 bits of color
  reg [7:0] x_coord;     // X coordinate where we want things
  reg [7:0] pix1, pix2;  // Shift registers, output when x_coord == 0
  reg aprio;             // Current prio
  wire active = (x_coord == 0);
  always @(posedge clk) if (ce) begin
    if (enable) begin
      if (!active) begin
        // Decrease until x_coord is zero.
        x_coord <= x_coord - 8'h01;
      end else begin
        pix1 <= pix1 >> 1;
        pix2 <= pix2 >> 1;
      end
    end
    if (load[3]) pix1 <= load_in[26:19];
    if (load[2]) pix2 <= load_in[18:11];
    if (load[1]) x_coord <= load_in[10:3];
    if (load[0]) {upper_color, aprio} <= load_in[2:0];
  end
  assign bits = {aprio, upper_color, active && pix2[0], active && pix1[0]};
  assign load_out = {pix1, pix2, x_coord, upper_color, aprio};
endmodule  // SpriteGen
