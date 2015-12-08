
module Blend(input [5:0] rule, input disable_hq2x,
             input [14:0] E, input [14:0] A, input [14:0] B, input [14:0] D, input [14:0] F, input [14:0] H, output [14:0] Result);
  reg [1:0] input_ctrl;
  reg [8:0] op;
  localparam BLEND0 = 9'b1_xxx_x_xx_xx; // 0: A
  localparam BLEND1 = 9'b0_110_0_10_00; // 1: (A * 12 + B * 4) >> 4
  localparam BLEND2 = 9'b0_100_0_10_10; // 2: (A * 8 + B * 4 + C * 4) >> 4
  localparam BLEND3 = 9'b0_101_0_10_01; // 3: (A * 10 + B * 4 + C * 2) >> 4
  localparam BLEND4 = 9'b0_110_0_01_01; // 4: (A * 12 + B * 2 + C * 2) >> 4
  localparam BLEND5 = 9'b0_010_0_11_11; // 5: (A * 4 + (B + C) * 6) >> 4
  localparam BLEND6 = 9'b0_111_1_xx_xx; // 6: (A * 14 + B + C) >> 4
  localparam AB = 2'b00;
  localparam AD = 2'b01;
  localparam DB = 2'b10;
  localparam BD = 2'b11;
  wire is_diff;
  DiffCheck diff_checker(rule[1] ? B : H,
                         rule[0] ? D : F,
                         is_diff);
  always @* begin
    case({!is_diff, rule[5:2]})
    1,17:  {op, input_ctrl} = {BLEND1, AB};
    2,18:  {op, input_ctrl} = {BLEND1, DB};
    3,19:  {op, input_ctrl} = {BLEND1, BD};
    4,20:  {op, input_ctrl} = {BLEND2, DB};
    5,21:  {op, input_ctrl} = {BLEND2, AB};
    6,22:  {op, input_ctrl} = {BLEND2, AD};

    8: {op, input_ctrl} = {BLEND0, 2'bxx};
    9: {op, input_ctrl} = {BLEND0, 2'bxx};
    10: {op, input_ctrl} = {BLEND0, 2'bxx};
    11: {op, input_ctrl} = {BLEND1, AB};
    12: {op, input_ctrl} = {BLEND1, AB};
    13: {op, input_ctrl} = {BLEND1, AB};
    14: {op, input_ctrl} = {BLEND1, DB};
    15: {op, input_ctrl} = {BLEND1, BD};

    24: {op, input_ctrl} = {BLEND2, DB};
    25: {op, input_ctrl} = {BLEND5, DB};
    26: {op, input_ctrl} = {BLEND6, DB};
    27: {op, input_ctrl} = {BLEND2, DB};
    28: {op, input_ctrl} = {BLEND4, DB};
    29: {op, input_ctrl} = {BLEND5, DB};
    30: {op, input_ctrl} = {BLEND3, BD};
    31: {op, input_ctrl} = {BLEND3, DB};
    default: {op, input_ctrl} = 11'bx;
    endcase
    
    // Setting op[8] effectively disables HQ2X because blend will always return E.
    if (disable_hq2x)
      op[8] = 1;
  end
  // Generate inputs to the inner blender. Valid combinations.
  // 00: E A B
  // 01: E A D 
  // 10: E D B
  // 11: E B D
  wire [14:0] Input1 = E;
  wire [14:0] Input2 = !input_ctrl[1] ? A :
                       !input_ctrl[0] ? D : B;
  wire [14:0] Input3 = !input_ctrl[0] ? B : D;
  InnerBlend inner_blend1(op, Input1[4:0],   Input2[4:0],   Input3[4:0],   Result[4:0]);
  InnerBlend inner_blend2(op, Input1[9:5],   Input2[9:5],   Input3[9:5],   Result[9:5]);
  InnerBlend inner_blend3(op, Input1[14:10], Input2[14:10], Input3[14:10], Result[14:10]);
endmodule
