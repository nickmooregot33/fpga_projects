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
    input [15:0] wdata,
    output wire resp,
    output reg [15:0] rdata
);

//timeunit 1ns;
//timeprecision 1ns;

reg [7:0] mem [0:2**($bits(address))-1];
wire [15:0] internal_address;

/* Initialize memory contents from memory.lst file */
initial
begin
    $readmemh("memory.lst", mem);
end

/* Calculate internal address */
assign internal_address = {address[15:1], 1'b0};

/* Read */
always @ (*)
begin
    rdata = {mem[internal_address+1], mem[internal_address]};
end

/* Write */
always @(posedge clk) //mem_write
begin
    if (write)
    begin
        if (wmask[1])
        begin
            mem[internal_address+1] = wdata[15:8];
        end

        if (wmask[0])
        begin
            mem[internal_address] = wdata[7:0];
        end
    end
end 

/* Magic memory responds immediately */
assign resp = read | write;

endmodule // magic_memory
