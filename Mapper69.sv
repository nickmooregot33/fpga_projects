// 69 - Sunsoft FME-7
module Mapper69(input clk, input ce, input reset,
                input [31:0] flags,
                input [15:0] prg_ain, output [21:0] prg_aout,
                input prg_read, prg_write,                   // Read / write signals
                input [7:0] prg_din,
                output prg_allow,                          // Enable access to memory for the specified operation.
                input [13:0] chr_ain, output [21:0] chr_aout,
                output chr_allow,                             // Allow write
                output reg vram_a10,                          // Value for A10 address line
                output vram_ce,                               // True if the address should be routed to the internal 2kB VRAM.
                output reg irq);
  reg [7:0] chr_bank[0:7];
  reg [4:0] prg_bank[0:3];
  reg [1:0] mirroring;
  reg irq_countdown, irq_trigger;
  reg [15:0] irq_counter;
  reg [3:0] addr;
  reg ram_enable, ram_select;
  wire [16:0] new_irq_counter = irq_counter - {15'b0, irq_countdown};
  always @(posedge clk) if (reset) begin
    chr_bank[0] <= 0;
    chr_bank[1] <= 0;
    chr_bank[2] <= 0;
    chr_bank[3] <= 0;
    chr_bank[4] <= 0;
    chr_bank[5] <= 0;
    chr_bank[6] <= 0;
    chr_bank[7] <= 0;
    prg_bank[0] <= 0;
    prg_bank[1] <= 0;
    prg_bank[2] <= 0;
    prg_bank[3] <= 0;
    mirroring <= 0;
    irq_countdown <= 0;
    irq_trigger <= 0;
    irq_counter <= 0;
    addr <= 0;
    ram_enable <= 0;
    ram_select <= 0;
    irq <= 0;
  end else if (ce) begin
    irq_counter <= new_irq_counter[15:0];
    if (irq_trigger && new_irq_counter[16]) irq <= 1;
    if (!irq_trigger) irq <= 0;
      
    if (prg_ain[15] & prg_write) begin
      case (prg_ain[14:13])
      0: addr <= prg_din[3:0];
      1: begin
          case(addr)
          0,1,2,3,4,5,6,7: chr_bank[addr[2:0]] <= prg_din;
          8,9,10,11:       prg_bank[addr[1:0]] <= prg_din[4:0];
          12:              mirroring <= prg_din[1:0];
          13:              {irq_countdown, irq_trigger} <= {prg_din[7], prg_din[0]};
          14:              irq_counter[7:0] <= prg_din;
          15:              irq_counter[15:8] <= prg_din;
          endcase
          if (addr == 8) {ram_enable, ram_select} <= prg_din[7:6];
        end
      endcase
    end
  end
  always begin
    casez(mirroring[1:0])
    2'b00   :   vram_a10 = {chr_ain[10]};    // vertical
    2'b01   :   vram_a10 = {chr_ain[11]};    // horizontal
    2'b1?   :   vram_a10 = {mirroring[0]};   // 1 screen lower
    endcase
  end
  reg [4:0] prgout;
  reg [7:0] chrout;
  always begin
    casez(prg_ain[15:13])
    3'b011:  prgout = prg_bank[0];
    3'b100:  prgout = prg_bank[1];
    3'b101:  prgout = prg_bank[2];
    3'b110:  prgout = prg_bank[3];
    3'b111:  prgout = 5'b11111;
    default: prgout = 5'bxxxxx;
    endcase
    chrout = chr_bank[chr_ain[12:10]];
  end
  wire ram_cs = (prg_ain[15] == 0 && ram_select);
  assign prg_aout = {1'b0, ram_cs, 2'b00, prgout[4:0], prg_ain[12:0]};
  assign prg_allow = ram_cs ? ram_enable : !prg_write;
  assign chr_allow = flags[15];
  assign chr_aout = {4'b10_00, chrout, chr_ain[9:0]};
  assign vram_ce = chr_ain[13];
endmodule
