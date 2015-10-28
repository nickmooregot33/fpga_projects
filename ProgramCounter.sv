
module ProgramCounter(input clk, input ce,
                      input [1:0] LoadPC,
                      input GotInterrupt,
                      input [7:0] DIN,
                      input [7:0] T,
                      output reg [15:0] PC, output JumpNoOverflow);
  reg [15:0] NewPC;
  assign JumpNoOverflow = ((PC[8] ^ NewPC[8]) == 0) & LoadPC[0] & LoadPC[1];

  always begin
    // Load PC Control
    case (LoadPC) 
    0,1: NewPC = PC + {15'b0, (LoadPC[0] & ~GotInterrupt)};
    2:   NewPC = {DIN,T};
    3:   NewPC = PC + {{8{T[7]}},T};
    endcase
  end
  
  always @(posedge clk)
    if (ce)
      PC <= NewPC;    
endmodule

