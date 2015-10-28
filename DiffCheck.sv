// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

module DiffCheck(input [14:0] rgb1, input [14:0] rgb2, output result);
  wire [5:0] r = rgb1[4:0] - rgb2[4:0];
  wire [5:0] g = rgb1[9:5] - rgb2[9:5];
  wire [5:0] b = rgb1[14:10] - rgb2[14:10];
  wire [6:0] t = $signed(r) + $signed(b);
  wire [6:0] gx = {g[5], g};
  wire [7:0] y = $signed(t) + $signed(gx);
  wire [6:0] u = $signed(r) - $signed(b);
  wire [7:0] v = $signed({g, 1'b0}) - $signed(t);
  // if y is inside (-24..24)
  wire y_inside = (y < 8'h18 || y >= 8'he8);
  // if u is inside (-4, 4)
  wire u_inside = (u < 7'h4 || u >= 7'h7c);
  // if v is inside (-6, 6)
  wire v_inside = (v < 8'h6 || v >= 8'hfA);
  assign result = !(y_inside && u_inside && v_inside);
endmodule
