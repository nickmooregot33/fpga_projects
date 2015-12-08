`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:07:39 12/07/2015 
// Design Name: 
// Module Name:    magic_memory 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
/*
 * Magic memory
 */
module magic_memory
(
    input clk,

    /* Port A */
    input read,
    input write,
    input [1:0] wmask,
    input [15:0] address,
    input [7:0] wdata,
    output wire resp,
	 output reg [7:0] led_val,
    output reg [7:0] rdata
);

//timeunit 1ns;
//timeprecision 1ns;

reg [7:0] mem [0:2**16-1];
wire [15:0] internal_address;

/* Initialize memory contents from memory.lst file */
initial
begin
    $readmemh("../../fpganes/memory_files/loop.lst", mem);
end

/* Calculate internal address */
assign internal_address = address;

/* Read */
always @ ( internal_address[0],internal_address[1],internal_address[2],internal_address[3],internal_address[4],internal_address[5],internal_address[6],internal_address[7],internal_address[8],internal_address[9],internal_address[10],internal_address[11],internal_address[12],internal_address[13],internal_address[14],internal_address[15])
begin
    rdata = mem[internal_address];
	 if(internal_address == 16'h2000) begin
		led_val = mem[internal_address];
	 end
end

/* Write */
always @(posedge clk) //mem_write
begin
    if (!write)
        begin
            mem[internal_address] = wdata[7:0];
    end
	 //led_val = mem[16'h2000];
end

/* Magic memory responds immediately */
assign resp = read | write;
//assign led_val = mem[16'h2000];

endmodule // magic_memory

