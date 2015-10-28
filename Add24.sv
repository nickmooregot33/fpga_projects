
module Add24(input [4:0] a, input [4:0] b, output [4:0] r);
  wire [5:0] t = a + b;
  wire [1:0] u = t[5:3] == 0 ? 0 : 
                 t[5:3] == 1 ? 1 : 
                 t[5:3] == 2 ? 2 : 
                 t[5:3] == 3 ? 0 : 
                 t[5:3] == 4 ? 1 : 
                 t[5:3] == 5 ? 2 : 
                 t[5:3] == 6 ? 0 : 1;
  assign r = {u, t[2:0]};
endmodule
