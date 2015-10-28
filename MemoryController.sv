// Asynchronous PSRAM controller for byte access
// After outputting a byte to read, the result is available 70ns later.
module MemoryController(
                 input clk,
                 input read_a,             // Set to 1 to read from RAM
                 input read_b,             // Set to 1 to read from RAM
                 input write,              // Set to 1 to write to RAM
                 input [23:0] addr,        // Address to read / write
                 input [7:0] din,          // Data to write
                 output reg [7:0] dout_a,  // Last read data a
                 output reg [7:0] dout_b,  // Last read data b
                 output reg busy,          // 1 while an operation is in progress

                 output reg MemOE,         // Output Enable. Enable when Low.
                 output reg MemWR,         // Write Enable. WRITE when Low.
                 output MemAdv,            // Address valid. Keep LOW for Async.
                 output MemClk,            // Clock for sync oper. Keep LOW for Async.
                 output reg RamCS,         // Chip Enable. Active = LOW
                 output RamCRE,            // CRE = Control Register. LOW = Normal mode.
                 output reg RamUB,         // Upper byte enable
                 output reg RamLB,         // Lower byte enable
                 output reg [22:0] MemAdr,
                 inout [15:0] MemDB);
                 
  // These are always low for async operations
  assign MemAdv = 0;
  assign MemClk = 0;
  assign RamCRE = 0;
  reg [7:0] data_to_write;
  assign MemDB = MemOE ? {data_to_write, data_to_write} : 16'bz; // MemOE == 0 means we need to output tristate
  reg [1:0] cycles;
  reg r_read_a;
  
  always @(posedge clk) begin
    // Initiate read or write
    if (!busy) begin
      if (read_a || read_b || write) begin
        MemAdr <= addr[23:1];
        RamUB <= !(addr[0] != 0); // addr[0] == 0 asserts RamUB, active low.
        RamLB <= !(addr[0] == 0);
        RamCS <= 0;    // 0 means active
        MemWR <= !(write != 0); // Active Low
        MemOE <= !(write == 0);
        busy <= 1;
        data_to_write <= din;
        cycles <= 0;
        r_read_a <= read_a;
      end else begin
        MemOE <= 1;
        MemWR <= 1;
        RamCS <= 1;
        RamUB <= 1;
        RamLB <= 1;
        busy <= 0;
        cycles <= 0;
      end
    end else begin
      if (cycles == 2) begin
        // Now we have waited 3x45 = 135ns, latch incoming data on read.
        if (!MemOE) begin
          if (r_read_a) dout_a <= RamUB ? MemDB[7:0] : MemDB[15:8];
          else dout_b <= RamUB ? MemDB[7:0] : MemDB[15:8];
        end
        MemOE <= 1; // Deassert Output Enable.
        MemWR <= 1; // Deassert Write
        RamCS <= 1; // Deassert Chip Select
        RamUB <= 1; // Deassert upper/lower byte
        RamLB <= 1;
        busy <= 0;
        cycles <= 0;
      end else begin
        cycles <= cycles + 1;
      end
    end
  end
endmodule  // MemoryController
