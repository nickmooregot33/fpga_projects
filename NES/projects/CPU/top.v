`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:25:46 12/07/2015 
// Design Name: 
// Module Name:    top 
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
module top(	input clk,
				input RESET,
				input UART_RX
    );

/*module UartDemux(	input clk, 
							input RESET, 
							input UART_RX, 
							output reg [7:0] data, 
							output reg [7:0] addr, 
							output reg write, 
							output reg checksum_error
);*/

UartDemux uart(	.clk(clk),
						.RESET(), 
						.UART_RX(), 
						.data(), 
						.addr(), 
						.write(), 
						.checksum_error()
);


/*CPU(		input clk, 
				input ce, 
				input reset,
				input [7:0] DIN,
				input irq,
				input nmi,
				output reg [7:0] dout, output reg [15:0] aout,
				output reg mr,
				output reg mw);*/
CPU core(
			.clk(clk), 
			.ce(), 
			.reset(),
			.DIN(),
			.irq(),
			.nmi(),
			.dout(), 
			.aout(),
			.mr(),
			.mw()
);

/*module magic_memory
(
    input clk,

//     Port A 
    input read,
    input write,
    input [1:0] wmask,
    input [15:0] address,
    input [15:0] wdata,
    output logic resp,
    output logic [15:0] rdata
);*/

magic_memory
(
    .clk(clk),

    /* Port A */
    .read(),
    .write(),
    .wmask(),
    .address(),
    .wdata(),
    .resp(),
    .rdata()
);

