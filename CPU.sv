
module CPU(input clk, input ce, input reset,
           input [7:0] DIN,
           input irq,
           input nmi,
           output reg [7:0] dout, output reg [15:0] aout,
           output reg mr,
           output reg mw);
  reg [7:0] A, X, Y;
  reg [7:0] SP, T, P;
  reg [7:0] IR;
  reg [2:0] State;
  reg GotInterrupt;
  
  reg IsResetInterrupt;
  wire [15:0] PC;
  reg JumpTaken;
  wire JumpNoOverflow;

  // De-multiplex microcode
  wire [37:0] MicroCode;
  wire [1:0] LoadSP = MicroCode[1:0];            // 7 LUT
  wire [1:0] LoadPC = MicroCode[3:2];            // 12 LUT
  wire [1:0] AddrBus = MicroCode[5:4];           // 18 LUT
  wire [2:0] MemWrite = MicroCode[8:6];          // 10 LUT
  wire [4:0] AddrCtrl = MicroCode[13:9];       
  wire       FlagCtrl = MicroCode[14];           // RegWrite + FlagCtrl = 22 LUT
  wire [1:0] LoadT = MicroCode[16:15];           // 13 LUT
  wire [1:0] StateCtrl = MicroCode[18:17];
  wire [2:0] FlagsCtrl = MicroCode[21:19];
  wire [15:0] IrFlags = MicroCode[37:22];

  // Load Instruction Register? Force BRK on Interrupt.
  wire [7:0] NextIR = (State == 0) ? (GotInterrupt ? 8'd0 : DIN) : IR;
  wire IsBranchCycle1 = (IR[4:0] == 5'b10000) && State[0];

  // Compute next state.
  reg [2:0] NextState;
  always begin
    case (StateCtrl)
    0: NextState = State + 3'd1;
    1: NextState = (AXCarry ? 3'd4 : 3'd5);
    2: NextState = (IsBranchCycle1 && JumpTaken) ? 2 : 0; // Override next state if the branch is taken.
    3: NextState = (JumpNoOverflow ? 3'd0 : 3'd4);
    endcase
  end

  wire [15:0] AX;
  wire AXCarry;
AddressGenerator addgen(clk, ce, AddrCtrl, {IrFlags[0], IrFlags[1]}, DIN, T, X, Y, AX, AXCarry);

// Microcode table has a 1 clock latency (block ram).
MicroCodeTable micro2(clk, ce, reset, NextIR, NextState, MicroCode);

  wire [7:0] AluR;
  wire [7:0] AluIntR;
  wire CO, VO, SO,ZO;
NewAlu new_alu(IrFlags[15:5], A,X,Y,SP,DIN,T, P[0], P[6], CO, VO, SO, ZO, AluR, AluIntR);

// Registers
always @(posedge clk) if (reset) begin
  A <= 0;
  X <= 0;
  Y <= 0;
end else if (ce) begin
  if (FlagCtrl & IrFlags[2]) X <= AluR;
  if (FlagCtrl & IrFlags[3]) A <= AluR;
  if (FlagCtrl & IrFlags[4]) Y <= AluR;
end

// Program counter
ProgramCounter pc(clk, ce, LoadPC, GotInterrupt, DIN, T, PC, JumpNoOverflow);

reg IsNMIInterrupt;
reg LastNMI;
// NMI is triggered at any time, except during reset, or when we're in the middle of
// reading the vector address
wire turn_nmi_on = (AddrBus != 3) && !IsResetInterrupt && nmi && !LastNMI;
// Controls whether we'll remember the state in LastNMI
wire nmi_remembered = (AddrBus != 3) && !IsResetInterrupt ? nmi : LastNMI;
// NMI flag is cleared right after we read the vector address
wire turn_nmi_off = (AddrBus == 3) && (State[0] == 0);
// Controls whether IsNmiInterrupt will get set
wire nmi_active = turn_nmi_on ? 1 : turn_nmi_off ? 0 : IsNMIInterrupt;
always @(posedge clk) begin
  if (reset) begin
    IsNMIInterrupt <= 0;
    LastNMI <= 0;
  end else if (ce) begin
    IsNMIInterrupt <= nmi_active;
    LastNMI <= nmi_remembered;
  end
end

// Generate outputs from module...
always begin
  dout = 8'bX;
  case (MemWrite[1:0])
  'b00: dout = T;
  'b01: dout = AluR;
  'b10: dout = {P[7:6], 1'b1, !GotInterrupt, P[3:0]};
  'b11: dout = State[0] ? PC[7:0] : PC[15:8];
  endcase
  mw = MemWrite[2] && !IsResetInterrupt; // Prevent writing while handling a reset
  mr = !mw;
end

always begin
  case (AddrBus)
  0: aout = PC;
  1: aout = AX;
  2: aout = {8'h01, SP};
  // irq/BRK vector FFFE
  // nmi vector FFFA
  // Reset vector FFFC
  3: aout = {13'b1111_1111_1111_1, !IsNMIInterrupt, !IsResetInterrupt, ~State[0]};
  endcase 
end

 
always @(posedge clk) begin
  if (reset) begin
    // Reset runs the BRK instruction as usual.
    State <= 0;
    IR <= 0;
    GotInterrupt <= 1;
    IsResetInterrupt <= 1;
    P <= 'h24;
    SP <= 0;
    T <= 0;
    JumpTaken <= 0;
  end else if (ce) begin      
    // Stack pointer control.
    // The operand is an optimization that either
    // returns -1,0,1 depending on LoadSP 
    case (LoadSP)
    0,2,3: SP <= SP + { {7{LoadSP[0]}}, LoadSP[1] };
    1: SP <= X;
    endcase 

    // LoadT control
    case (LoadT)
    2: T <= DIN;
    3: T <= AluIntR;
    endcase

    if (FlagCtrl) begin
      case(FlagsCtrl)
      0: P <= P;      // No Op
      1: {P[0], P[1], P[6], P[7]} <= {CO, ZO, VO, SO}; // ALU
      2: P[2] <= 1;     // BRK
      3: P[6] <= 0;     // CLV
      4: {P[7:6],P[3:0]} <= {DIN[7:6], DIN[3:0]}; // RTI/PLP
      5: P[0] <= IR[5]; // CLC/SEC
      6: P[2] <= IR[5]; // CLI/SEI
      7: P[3] <= IR[5]; // CLD/SED
      endcase
    end

    // Compute if the jump is to be taken. Result is stored in a flipflop, so
    // it won't be available until next cycle.
    // NOTE: Using DIN here. DIN is IR at cycle 0. This means JumpTaken will
    // contain the Jump status at cycle 1.
    case (DIN[7:5])
    0: JumpTaken <= ~P[7]; // BPL
    1: JumpTaken <=  P[7]; // BMI
    2: JumpTaken <= ~P[6]; // BVC
    3: JumpTaken <=  P[6]; // BVS
    4: JumpTaken <= ~P[0]; // BCC
    5: JumpTaken <=  P[0]; // BCS
    6: JumpTaken <= ~P[1]; // BNE
    7: JumpTaken <=  P[1]; // BEQ
    endcase
    
    // Check the interrupt status on the last cycle of the current instruction,
    // (or on cycle #1 of any branch instruction)
    if (StateCtrl == 2'b10) begin
      GotInterrupt <= (irq & ~P[2]) | nmi_active;
      IsResetInterrupt <= 0;
    end

    IR <= NextIR;
    State <= NextState;
  end
end
endmodule
