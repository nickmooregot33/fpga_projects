
module AddressGenerator(input clk, input ce,
                        input [4:0] Operation, 
                        input [1:0] MuxCtrl,
                        input [7:0] DataBus, T, X, Y,
                        output [15:0] AX,
                        output Carry);
  // Actual contents of registers
  reg [7:0] AL, AH;
  // Last operation generated a carry?
  reg SavedCarry;
  assign AX = {AH, AL};

  wire [2:0] ALCtrl = Operation[4:2];
  wire [1:0] AHCtrl = Operation[1:0];

  // Possible new value for AL.
  wire [7:0] NewAL;
  assign {Carry,NewAL} = {1'b0, (MuxCtrl[1] ? T : AL)} + {1'b0, (MuxCtrl[0] ? Y : X)};
  
  // The other one
  wire TmpVal = (!AHCtrl[1] | SavedCarry);
  wire [7:0] TmpAdd = (AHCtrl[1] ? AH : AL) + {7'b0, TmpVal};
  
  always @(posedge clk) if (ce) begin
    SavedCarry <= Carry;
    if (ALCtrl[2])
      case(ALCtrl[1:0])
      0: AL <= NewAL;
      1: AL <= DataBus;
      2: AL <= TmpAdd;
      3: AL <= T;
      endcase
     
    case(AHCtrl[1:0])
    0: AH <= AH;
    1: AH <= 0;
    2: AH <= TmpAdd;
    3: AH <= DataBus;
    endcase
  end
endmodule
