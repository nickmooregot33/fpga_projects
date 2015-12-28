
module Rs232Rx(input clk, input UART_RX, output [7:0] data, output send);
  reg [8:0] recvbuf;
  reg [5:0] timeout = 10/2 - 1;
  reg recving;
  reg data_valid = 0;
  assign data = recvbuf[7:0];
  assign send = data_valid;
  always @(posedge clk) begin
    data_valid <= 0;
    timeout <= timeout - 6'd1;
    if (timeout == 0) begin
      timeout <= 10 - 1;
      recvbuf <= (recving ? {UART_RX, recvbuf[8:1]} : 9'b100000000);
      recving <= 1;
      if (recving && recvbuf[0]) begin
        recving <= 0;
        data_valid <= UART_RX;
      end
    end
    // Once we see a start bit we want to wait
    // another half period for it to become stable.
    if (!recving && UART_RX)
      timeout <= 10/2 - 1;
  end
endmodule
