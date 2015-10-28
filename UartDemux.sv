
// Decodes incoming UART signals and demuxes them into addr/data lines.
// Packet Format: 
//   1 byte checksum | 1 byte address | 1 byte count | (count + 1) data bytes
module UartDemux(input clk, input RESET, input UART_RX, output reg [7:0] data, output reg [7:0] addr, output reg write, output reg checksum_error);
  wire [7:0] indata;
  wire       insend;
  Rs232Rx uart(clk, UART_RX, indata, insend);
  reg [1:0] state = 0;
  reg [7:0] cksum;
  reg [7:0] count;
  wire [7:0] new_cksum = cksum + indata;
  always @(posedge clk) if (RESET) begin
    write <= 0;
    state <= 0;
    count <= 0;
    cksum <= 0;
    addr <= 0;
    data <= 0;
    checksum_error <= 0;
  end else begin
    write <= 0;
    if (insend) begin
      cksum <= new_cksum;
      count <= count - 8'd1;
      if (state == 0) begin
        state <= 1;
        cksum <= indata;
      end else if (state == 1) begin
        addr <= indata;
        state <= 2;
      end else if (state == 2) begin
        count <= indata;
        state <= 3;
      end else begin
        data <= indata;
        write <= 1;
        if (count == 1) begin
          state <= 0;
          if (new_cksum != 0)
            checksum_error <= 1;
        end
      end
    end
  end
endmodule

