					
// This contains all 8 sprites. Will return the pixel value of the highest prioritized sprite.
// When load is set, and clocked, load_in is loaded into sprite 7 and all others are shifted down.
// Sprite 0 has highest prio.
// 226 LUTs, 68 Slices
module SpriteSet(input clk, input ce,   // Input clock
                 input enable,          // Enable pixel generation
                 input [3:0] load,      // Which parts of the state to load/shift.
                 input [26:0] load_in,  // State to load with 
                 output [4:0] bits,     // Output bits
                 output is_sprite0);    // Set to true if sprite #0 was output

  wire [26:0] load_out7, load_out6, load_out5, load_out4, load_out3, load_out2, load_out1, load_out0; 
  wire [4:0] bits7, bits6, bits5, bits4, bits3, bits2, bits1, bits0;
  Sprite sprite7(clk, ce, enable, load, load_in,   load_out7, bits7);
  Sprite sprite6(clk, ce, enable, load, load_out7, load_out6, bits6);
  Sprite sprite5(clk, ce, enable, load, load_out6, load_out5, bits5);
  Sprite sprite4(clk, ce, enable, load, load_out5, load_out4, bits4);
  Sprite sprite3(clk, ce, enable, load, load_out4, load_out3, bits3);
  Sprite sprite2(clk, ce, enable, load, load_out3, load_out2, bits2);
  Sprite sprite1(clk, ce, enable, load, load_out2, load_out1, bits1);
  Sprite sprite0(clk, ce, enable, load, load_out1, load_out0, bits0);          
  // Determine which sprite is visible on this pixel.
  assign bits = bits0[1:0] != 0 ? bits0 : 
                bits1[1:0] != 0 ? bits1 : 
                bits2[1:0] != 0 ? bits2 : 
                bits3[1:0] != 0 ? bits3 : 
                bits4[1:0] != 0 ? bits4 : 
                bits5[1:0] != 0 ? bits5 : 
                bits6[1:0] != 0 ? bits6 : 
                                  bits7;
  assign is_sprite0 = bits0[1:0] != 0;                             
endmodule  // SpriteSet
