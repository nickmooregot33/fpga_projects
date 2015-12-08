// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

//`include "MicroCode.v"

module MyAddSub(input [7:0] A,B,
                input CI,ADD,
                output [7:0] S,
                output CO,OFL);
  wire C0,C1,C2,C3,C4,C5,C6;
  wire C6O;
  wire [7:0] I = A ^ B ^ {8{~ADD}};
  MUXCY_L MUXCY_L0 (.LO(C0),.CI(CI),.DI(A[0]),.S(I[0]) );
  MUXCY_L MUXCY_L1 (.LO(C1),.CI(C0),.DI(A[1]),.S(I[1]) );
  MUXCY_L MUXCY_L2 (.LO(C2),.CI(C1),.DI(A[2]),.S(I[2]) );
  MUXCY_L MUXCY_L3 (.LO(C3),.CI(C2),.DI(A[3]),.S(I[3]) );
  MUXCY_L MUXCY_L4 (.LO(C4),.CI(C3),.DI(A[4]),.S(I[4]) );
  MUXCY_L MUXCY_L5 (.LO(C5),.CI(C4),.DI(A[5]),.S(I[5]) );
  MUXCY_D MUXCY_D6 (.LO(C6),.O(C6O),.CI(C5),.DI(A[6]),.S(I[6]) );
  MUXCY   MUXCY_7  (.O(CO),.CI(C6),.DI(A[7]),.S(I[7]) );
  XORCY XORCY0 (.O(S[0]),.CI(CI),.LI(I[0]));
  XORCY XORCY1 (.O(S[1]),.CI(C0),.LI(I[1]));
  XORCY XORCY2 (.O(S[2]),.CI(C1),.LI(I[2]));
  XORCY XORCY3 (.O(S[3]),.CI(C2),.LI(I[3]));
  XORCY XORCY4 (.O(S[4]),.CI(C3),.LI(I[4]));
  XORCY XORCY5 (.O(S[5]),.CI(C4),.LI(I[5]));
  XORCY XORCY6 (.O(S[6]),.CI(C5),.LI(I[6]));
  XORCY XORCY7 (.O(S[7]),.CI(C6),.LI(I[7]));
  XOR2 X1(.O(OFL),.I0(C6O),.I1(CO));
endmodule
