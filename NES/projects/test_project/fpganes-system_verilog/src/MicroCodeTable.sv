
module MicroCodeTable(input clk, input ce, input reset, input [7:0] IR, input [2:0] State, output [37:0] Mout);
  wire [8:0] M;
  MicroCodeTableInner inner(clk, ce, reset, IR, State, M);
  reg [14:0] A[0:31];
  reg [18:0] B[0:255];
  initial begin
A[0] = 15'b_10__0_10101_0xx_01_00; // ['[PC++]', '[PC++]->AL', '[PC++]->?', '[PC++]->T', 'PC+1->PC', '']
A[1] = 15'b_xx__0_0xx11_0xx_01_00; // [PC++]->AH
A[2] = 15'b_xx__1_00000_0xx_00_00; // ['ALU([AX])->A', 'ALU([AX])->?', '[PC]->,ALU()->A', 'Setappropriateflags', 'ALU([SP])->A', '[SP]->P', 'ALU()->X,Y', 'ALU()->A']
A[3] = 15'b_10__0_00000_0xx_00_00; // ['[AX]->T', 'ALU([AX])->?', 'ALU([AX])->A', 'ALU([AX])->', '[PC]->', 'NO-OP', '[VECT]->T', '']
A[4] = 15'b_11__1_00000_100_00_00; // ['T->[AX],ALU(T)->T', 'T->[AX],ALU(T)->T:A']
A[5] = 15'b_xx__0_xxxxx_100_00_00; // T->[AX]
A[6] = 15'b_xx__0_00000_101_00_00; // ALU()->[AX]
A[7] = 15'b_0x__0_10000_0xx_00_00; // ['[AX]->?,AL+X->AL', '[AX]->?,AL+X/Y->AL', 'KEEP_AC']
A[8] = 15'b_xx__0_10011_0xx_01_00; // ['[PC++]->AH,AL+X/Y->AL', '[PC++]->AH,AL+X->AL', '[PC++]->AH,AL+Y->AL']
A[9] = 15'b_10__0_0xx10_0xx_00_00; // ['[AX]->?,AH+FIX->AH', '[AX]->T,AH+FIX->AH']
A[10] = 15'b_10__0_11000_0xx_00_00; // [AX]->T,AL+1->AL
A[11] = 15'b_xx__0_11111_0xx_00_00; // [AX]->AH,T->AL
A[12] = 15'b_xx__0_10011_0xx_00_00; // [AX]->AH,T+Y->AL
A[13] = 15'b_xx__1_xxxxx_0xx_01_00; // ['ALU([PC++])->A', 'ALU([PC++])->?', 'ALU([PC++])->Reg']
A[14] = 15'b_xx__0_xxxxx_101_00_11; // ALU(A)->[SP--]
A[15] = 15'b_xx__0_xxxxx_110_00_11; // P->[SP--]
A[16] = 15'b_10__0_xxxxx_0xx_00_10; // ['SP++', 'SP+1->SP', '[SP]->T,SP+1->SP']
A[17] = 15'b_xx__0_xxxxx_0xx_11_00; // PC+T->PC
A[18] = 15'b_xx__0_xxxxx_0xx_00_01; // X->S
A[19] = 15'b_xx__0_xxxxx_0xx_10_00; // ['[PC]:T->PC', '[AX]:T->PC', '[VECT]:T->PC', '[SP]:T->PC']
A[20] = 15'b_0x__0_xxxxx_111_00_11; // ['PCH->[SP--]', 'PCL->[SP--],', 'PCH->[SP--](KEEPAC)', 'PCL->[SP--](KEEPAC)']
A[21] = 15'b_xx__1_xxxxx_110_00_11; // P->[SP--]
A[22] = 15'b_xx__1_xxxxx_0xx_00_10; // [SP]->P,SP+1->SP
A[23] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
A[24] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
A[25] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
A[26] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
A[27] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
A[28] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
A[29] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
A[30] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
A[31] = 15'b_xx__x_xxxxx_xxx_xx_xx; // []
B[0] = 19'bxxxxxxxxxx0_000_00_010;
B[32] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[64] = 19'bxxxxxxxxxx0_000_00_100;
B[96] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[128] = 19'b011010x10x0_xxx_00_xxx;
B[160] = 19'bxx0010x10x0_100_00_001;
B[192] = 19'b010010x1100_000_00_001;
B[224] = 19'b100010x1100_000_00_001;
B[1] = 19'b000010x0001_010_00_001;
B[33] = 19'b000010x0011_010_00_001;
B[65] = 19'b000010x0101_010_00_001;
B[97] = 19'b000010x0111_010_00_001;
B[129] = 19'b001010x10x1_xxx_00_xxx;
B[161] = 19'bxx0010x10x1_010_00_001;
B[193] = 19'b000010x1101_000_00_001;
B[225] = 19'b000010x1111_010_00_001;
B[2] = 19'bxx0100010x0_000_00_001;
B[34] = 19'bxx0100110x0_000_00_001;
B[66] = 19'bxx0101010x0_000_00_001;
B[98] = 19'bxx0101110x0_000_00_001;
B[130] = 19'b101010x10x0_xxx_00_xxx;
B[162] = 19'bxx0010x10x0_001_00_001;
B[194] = 19'bxx0111010x0_000_00_001;
B[226] = 19'bxx0111110x0_000_00_001;
B[3] = 19'b00010000001_010_00_001;
B[35] = 19'b00010010011_010_00_001;
B[67] = 19'b00010100101_010_00_001;
B[99] = 19'b00010110111_010_00_001;
B[131] = 19'b111010x10x1_xxx_00_xxx;
B[163] = 19'bxx0010x10x1_011_00_001;
B[195] = 19'b00011101101_000_00_001;
B[227] = 19'b00011111111_010_00_001;
B[4] = 19'b000010x0000_xxx_00_xxx;
B[36] = 19'b000010x0010_000_00_001;
B[68] = 19'b000010x0100_xxx_00_xxx;
B[100] = 19'b000010x0110_xxx_00_xxx;
B[132] = 19'b011010x10x0_xxx_00_xxx;
B[164] = 19'bxx0010x10x0_100_00_001;
B[196] = 19'b010010x1100_000_00_001;
B[228] = 19'b100010x1100_000_00_001;
B[5] = 19'b000010x0001_010_00_001;
B[37] = 19'b000010x0011_010_00_001;
B[69] = 19'b000010x0101_010_00_001;
B[101] = 19'b000010x0111_010_00_001;
B[133] = 19'b001010x10x1_xxx_00_xxx;
B[165] = 19'bxx0010x10x1_010_00_001;
B[197] = 19'b000010x1101_000_00_001;
B[229] = 19'b000010x1111_010_00_001;
B[6] = 19'bxx0100010x0_000_00_001;
B[38] = 19'bxx0100110x0_000_00_001;
B[70] = 19'bxx0101010x0_000_00_001;
B[102] = 19'bxx0101110x0_000_00_001;
B[134] = 19'b101010x10x0_xxx_00_xxx;
B[166] = 19'bxx0010x10x0_001_00_001;
B[198] = 19'bxx0111010x0_000_00_001;
B[230] = 19'bxx0111110x0_000_00_001;
B[7] = 19'b00010000001_010_00_001;
B[39] = 19'b00010010011_010_00_001;
B[71] = 19'b00010100101_010_00_001;
B[103] = 19'b00010110111_010_00_001;
B[135] = 19'b111010x10x1_xxx_00_xxx;
B[167] = 19'bxx0010x10x1_011_00_001;
B[199] = 19'b00011101101_000_00_001;
B[231] = 19'b00011111111_010_00_001;
B[8] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[40] = 19'bxxxxxxxxxx0_000_00_100;
B[72] = 19'b001010x10x0_xxx_00_xxx;
B[104] = 19'bxx0010x10x0_010_00_001;
B[136] = 19'b011011010x0_100_00_001;
B[168] = 19'b001010x10x0_100_00_001;
B[200] = 19'b011011110x0_100_00_001;
B[232] = 19'b101011110x0_001_00_001;
B[9] = 19'b000010x0001_010_00_001;
B[41] = 19'b000010x0011_010_00_001;
B[73] = 19'b000010x0101_010_00_001;
B[105] = 19'b000010x0111_010_00_001;
B[137] = 19'b001010x10x1_xxx_00_xxx;
B[169] = 19'bxx0010x10x1_010_00_001;
B[201] = 19'b000010x1101_000_00_001;
B[233] = 19'b000010x1111_010_00_001;
B[10] = 19'b001000010x0_010_00_001;
B[42] = 19'b001000110x0_010_00_001;
B[74] = 19'b001001010x0_010_00_001;
B[106] = 19'b001001110x0_010_00_001;
B[138] = 19'b101010x10x0_010_00_001;
B[170] = 19'b001010x10x0_001_00_001;
B[202] = 19'b101011010x0_001_00_001;
B[234] = 19'bxx0111110x0_000_00_001;
B[11] = 19'b000010x0001_010_00_001;
B[43] = 19'b000010x0011_010_00_001;
B[75] = 19'b000010x0101_010_00_001;
B[107] = 19'b000010x0111_010_00_001;
B[139] = 19'b111010x10x1_xxx_00_xxx;
B[171] = 19'bxx0010x10x1_011_00_001;
B[203] = 19'b000010x1101_000_00_001;
B[235] = 19'b000010x1111_010_00_001;
B[12] = 19'b000010x0000_xxx_00_xxx;
B[44] = 19'b000010x0010_000_00_001;
B[76] = 19'bxxxxxxxxxx0_000_00_001;
B[108] = 19'bxxxxxxxxxx0_000_00_001;
B[140] = 19'b011010x10x0_xxx_00_xxx;
B[172] = 19'bxx0010x10x0_100_00_001;
B[204] = 19'b010010x1100_000_00_001;
B[236] = 19'b100010x1100_000_00_001;
B[13] = 19'b000010x0001_010_00_001;
B[45] = 19'b000010x0011_010_00_001;
B[77] = 19'b000010x0101_010_00_001;
B[109] = 19'b000010x0111_010_00_001;
B[141] = 19'b001010x10x1_xxx_00_xxx;
B[173] = 19'bxx0010x10x1_010_00_001;
B[205] = 19'b000010x1101_000_00_001;
B[237] = 19'b000010x1111_010_00_001;
B[14] = 19'bxx0100010x0_000_00_001;
B[46] = 19'bxx0100110x0_000_00_001;
B[78] = 19'bxx0101010x0_000_00_001;
B[110] = 19'bxx0101110x0_000_00_001;
B[142] = 19'b101010x10x0_xxx_00_xxx;
B[174] = 19'bxx0010x10x0_001_00_001;
B[206] = 19'bxx0111010x0_000_00_001;
B[238] = 19'bxx0111110x0_000_00_001;
B[15] = 19'b00010000001_010_00_001;
B[47] = 19'b00010010011_010_00_001;
B[79] = 19'b00010100101_010_00_001;
B[111] = 19'b00010110111_010_00_001;
B[143] = 19'b111010x10x1_xxx_00_xxx;
B[175] = 19'bxx0010x10x1_011_00_001;
B[207] = 19'b00011101101_000_00_001;
B[239] = 19'b00011111111_010_00_001;
B[16] = 19'bxxxxxxxxxx0_xxx_11_xxx;
B[48] = 19'bxxxxxxxxxx0_xxx_11_xxx;
B[80] = 19'bxxxxxxxxxx0_xxx_11_xxx;
B[112] = 19'bxxxxxxxxxx0_xxx_11_xxx;
B[144] = 19'b011010x10x0_xxx_11_xxx;
B[176] = 19'bxx0010x10x0_xxx_11_xxx;
B[208] = 19'bxxxxxxxxxx0_xxx_11_xxx;
B[240] = 19'bxxxxxxxxxx0_xxx_11_xxx;
B[17] = 19'b000010x0001_010_11_001;
B[49] = 19'b000010x0011_010_11_001;
B[81] = 19'b000010x0101_010_11_001;
B[113] = 19'b000010x0111_010_11_001;
B[145] = 19'b001010x10x1_xxx_11_xxx;
B[177] = 19'bxx0010x10x1_010_11_001;
B[209] = 19'b000010x1101_000_11_001;
B[241] = 19'b000010x1111_010_11_001;
B[18] = 19'bxx0100010x0_000_11_001;
B[50] = 19'bxx0100110x0_000_11_001;
B[82] = 19'bxx0101010x0_000_11_001;
B[114] = 19'bxx0101110x0_000_11_001;
B[146] = 19'b101010x10x0_xxx_11_xxx;
B[178] = 19'bxx0010x10x0_xxx_11_xxx;
B[210] = 19'bxx0111010x0_000_11_001;
B[242] = 19'bxx0111110x0_000_11_001;
B[19] = 19'b00010000001_010_11_001;
B[51] = 19'b00010010011_010_11_001;
B[83] = 19'b00010100101_010_11_001;
B[115] = 19'b00010110111_010_11_001;
B[147] = 19'b111010x10x1_xxx_11_xxx;
B[179] = 19'bxx0010x10x1_011_11_001;
B[211] = 19'b00011101101_000_11_001;
B[243] = 19'b00011111111_010_11_001;
B[20] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[52] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[84] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[116] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[148] = 19'b011010x10x0_xxx_00_xxx;
B[180] = 19'bxx0010x10x0_100_00_001;
B[212] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[244] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[21] = 19'b000010x0001_010_00_001;
B[53] = 19'b000010x0011_010_00_001;
B[85] = 19'b000010x0101_010_00_001;
B[117] = 19'b000010x0111_010_00_001;
B[149] = 19'b001010x10x1_xxx_00_xxx;
B[181] = 19'bxx0010x10x1_010_00_001;
B[213] = 19'b000010x1101_000_00_001;
B[245] = 19'b000010x1111_010_00_001;
B[22] = 19'bxx0100010x0_000_00_001;
B[54] = 19'bxx0100110x0_000_00_001;
B[86] = 19'bxx0101010x0_000_00_001;
B[118] = 19'bxx0101110x0_000_00_001;
B[150] = 19'b101010x10x0_xxx_10_xxx;
B[182] = 19'bxx0010x10x0_001_10_001;
B[214] = 19'bxx0111010x0_000_00_001;
B[246] = 19'bxx0111110x0_000_00_001;
B[23] = 19'b00010000001_010_00_001;
B[55] = 19'b00010010011_010_00_001;
B[87] = 19'b00010100101_010_00_001;
B[119] = 19'b00010110111_010_00_001;
B[151] = 19'b111010x10x1_xxx_10_xxx;
B[183] = 19'bxx0010x10x1_011_10_001;
B[215] = 19'b00011101101_000_00_001;
B[247] = 19'b00011111111_010_00_001;
B[24] = 19'bxxxxxxxxxx0_000_10_101;
B[56] = 19'bxxxxxxxxxx0_000_10_101;
B[88] = 19'bxxxxxxxxxx0_000_10_110;
B[120] = 19'bxxxxxxxxxx0_000_10_110;
B[152] = 19'b011010x10x0_010_10_001;
B[184] = 19'bxx1110x10x0_000_10_011;
B[216] = 19'bxxxxxxxxxx0_000_10_111;
B[248] = 19'bxxxxxxxxxx0_000_10_111;
B[25] = 19'b000010x0001_010_10_001;
B[57] = 19'b000010x0011_010_10_001;
B[89] = 19'b000010x0101_010_10_001;
B[121] = 19'b000010x0111_010_10_001;
B[153] = 19'b001010x10x1_xxx_10_xxx;
B[185] = 19'bxx0010x10x1_010_10_001;
B[217] = 19'b000010x1101_000_10_001;
B[249] = 19'b000010x1111_010_10_001;
B[26] = 19'bxx0100010x0_000_10_001;
B[58] = 19'bxx0100110x0_000_10_001;
B[90] = 19'bxx0101010x0_000_10_001;
B[122] = 19'bxx0101110x0_000_10_001;
B[154] = 19'b101010x10x0_xxx_10_xxx;
B[186] = 19'bxx1110x10x0_001_10_001;
B[218] = 19'bxx0111010x0_000_10_001;
B[250] = 19'bxx0111110x0_000_10_001;
B[27] = 19'b00010000001_010_10_001;
B[59] = 19'b00010010011_010_10_001;
B[91] = 19'b00010100101_010_10_001;
B[123] = 19'b00010110111_010_10_001;
B[155] = 19'b111010x10x1_xxx_10_xxx;
B[187] = 19'bxx0010x10x1_xxx_10_xxx;
B[219] = 19'b00011101101_000_10_001;
B[251] = 19'b00011111111_010_10_001;
B[28] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[60] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[92] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[124] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[156] = 19'b011010x10x0_xxx_00_xxx;
B[188] = 19'bxx0010x10x0_100_00_001;
B[220] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[252] = 19'bxxxxxxxxxx0_xxx_00_xxx;
B[29] = 19'b000010x0001_010_00_001;
B[61] = 19'b000010x0011_010_00_001;
B[93] = 19'b000010x0101_010_00_001;
B[125] = 19'b000010x0111_010_00_001;
B[157] = 19'b001010x10x1_xxx_00_xxx;
B[189] = 19'bxx0010x10x1_010_00_001;
B[221] = 19'b000010x1101_000_00_001;
B[253] = 19'b000010x1111_010_00_001;
B[30] = 19'bxx0100010x0_000_00_001;
B[62] = 19'bxx0100110x0_000_00_001;
B[94] = 19'bxx0101010x0_000_00_001;
B[126] = 19'bxx0101110x0_000_00_001;
B[158] = 19'b101010x10x0_xxx_10_xxx;
B[190] = 19'bxx0010x10x0_001_10_001;
B[222] = 19'bxx0111010x0_000_00_001;
B[254] = 19'bxx0111110x0_000_00_001;
B[31] = 19'b00010000001_010_00_001;
B[63] = 19'b00010010011_010_00_001;
B[95] = 19'b00010100101_010_00_001;
B[127] = 19'b00010110111_010_00_001;
B[159] = 19'b111010x10x1_xxx_10_xxx;
B[191] = 19'bxx0010x10x1_011_10_001;
B[223] = 19'b00011101101_000_00_001;
B[255] = 19'b00011111111_010_00_001;
  end  
  wire [14:0] R = A[M[4:0]];
  reg [18:0] AluFlags;
  always @(posedge clk) if (reset) begin
    AluFlags <= 0;
  end else if (ce) begin  
    AluFlags <= B[IR];
  end

  assign Mout = {AluFlags,// 19
                 M[8:7],  // NextState // 2
                 R[14:13],// LoadT     // 2
                 R[12],   // FlagCtrl  // 1
                 R[11:7], // AddrCtrl  // 5
                 R[6:4],  // MemWrite  // 3
                 M[6:5],  // AddrBus   // 2
                 R[3:2],  // LoadPC    // 2
                 R[1:0]   // LoadSP    // 2
                 };
endmodule

