 
module PixelMuxer(input [3:0] bg, input [3:0] obj, input obj_prio, output [3:0] out, output is_obj);

  wire bg_flag = bg[0] | bg[1];
  wire obj_flag = obj[0] | obj[1];
  assign is_obj = !(obj_prio && bg_flag) && obj_flag;
  assign out = is_obj ? obj : bg;
endmodule
