
module NewAlu(input  [10:0] OP, // ALU Operation
           input  [7:0] A,   // Registers input
           input  [7:0] X,   //       ""
           input  [7:0] Y,   //       ""
           input  [7:0] S,   //       ""
           input  [7:0] M,  // Secondary input to ALU
           input  [7:0] T,  // Secondary input to ALU
                             // -- Flags Input
           input        CI,  // Carry In
           input        VI,  // Overflow In
                             // -- Flags output
           output reg   CO,  // Carry out
           output reg   VO,  // Overflow out
           output reg   SO,  // Sign out
           output reg   ZO,  // zero out
                             // -- Result output
           output reg [7:0] Result,// Result out
           output reg [7:0] IntR); // Intermediate result out
  // Crack the ALU Operation
  wire [1:0] o_left_input, o_right_input;
  wire [2:0] o_first_op, o_second_op;
  wire o_fc;
  assign {o_left_input, o_right_input, o_first_op, o_second_op, o_fc} = OP;
  
  // Determine left, right inputs to Add/Sub ALU.
  reg [7:0] L, R;
  reg CR;
  always begin
    casez(o_left_input)
    0: L = A;
    1: L = Y;
    2: L = X;
    3: L = A & X;
    endcase
    casez(o_right_input)
    0: R = M;
    1: R = T;
    2: R = L;
    3: R = S;
    endcase
    CR = CI;
    casez(o_first_op[2:1])
    0: {CR, IntR} = {R, CI & o_first_op[0]};  // SHL, ROL
    1: {IntR, CR} = {CI & o_first_op[0], R};  // SHR, ROR
    2: IntR = R;                              // Passthrough
    3: IntR = R + (o_first_op[0] ? 8'b1 : 8'b11111111); // INC/DEC
    endcase
  end
  wire [7:0] AddR;
  wire AddCO, AddVO;
  MyAddSub addsub(.A(L),.B(IntR),.CI(o_second_op[0] ? CR : 1'b1),.ADD(!o_second_op[2]), .S(AddR), .CO(AddCO), .OFL(AddVO));
  // Produce the output of the second stage.
  always begin
    casez(o_second_op)
    0:       {CO, Result} = {CR,    L | IntR};
    1:       {CO, Result} = {CR,    L & IntR};
    2:       {CO, Result} = {CR,    L ^ IntR};
    3, 6, 7: {CO, Result} = {AddCO, AddR};
    4, 5:    {CO, Result} = {CR,    IntR};
    endcase
    // Final result
    ZO = (Result == 0);
    // Compute overflow flag
    VO = VI;
    casez(o_second_op)
    1: if (!o_fc) VO = IntR[6]; // Set V to 6th bit for BIT
    3: VO = AddVO;              // ADC always sets V
    7: if (o_fc) VO = AddVO;    // Only SBC sets V.
    endcase
    // Compute sign flag. It's always the uppermost bit of the result,
    // except for BIT that sets it to the 7th input bit
    SO = (o_second_op == 1 && !o_fc) ? IntR[7] : Result[7];
  end
endmodule
