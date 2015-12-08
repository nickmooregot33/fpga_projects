// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

// Module handles updating the loopy scroll register
module LoopyGen(input clk, input ce,
                input is_rendering,
                input [2:0] ain,   // input address from CPU
                input [7:0] din,   // data input
                input read,        // read
                input write,       // write
                input is_pre_render, // Is this the pre-render scanline
                input [8:0] cycle,
                output [14:0] loopy,
                output [2:0] fine_x_scroll);  // Current loopy value
  // Controls how much to increment on each write
  reg ppu_incr; // 0 = 1, 1 = 32
  // Current VRAM address
  reg [14:0] loopy_v;
  // Temporary VRAM address
  reg [14:0] loopy_t;
  // Fine X scroll (3 bits)
  reg [2:0] loopy_x;
  // Latch
  reg ppu_address_latch;
  initial begin
    ppu_incr = 0;
    loopy_v = 0;
    loopy_t = 0;
    loopy_x = 0;
    ppu_address_latch = 0;  
  end
  // Handle updating loopy_t and loopy_v
  always @(posedge clk) if (ce) begin
    if (is_rendering) begin
      // Increment course X scroll right after attribute table byte was fetched.
      if (cycle[2:0] == 3 && (cycle < 256 || cycle >= 320 && cycle < 336)) begin
        loopy_v[4:0] <= loopy_v[4:0] + 1;
        loopy_v[10] <= loopy_v[10] ^ (loopy_v[4:0] == 31);
      end

      // Vertical Increment  
      if (cycle == 251) begin
        loopy_v[14:12] <= loopy_v[14:12] + 1;
        if (loopy_v[14:12] == 7) begin
          if (loopy_v[9:5] == 29) begin
            loopy_v[9:5] <= 0;
            loopy_v[11] <= !loopy_v[11];
          end else begin
            loopy_v[9:5] <= loopy_v[9:5] + 1;
          end
        end
      end
      
      // Horizontal Reset at cycle 257
      if (cycle == 256)
        {loopy_v[10], loopy_v[4:0]} <= {loopy_t[10], loopy_t[4:0]};
  
      // On cycle 256 of each scanline, copy horizontal bits from loopy_t into loopy_v
      // On cycle 304 of the pre-render scanline, copy loopy_t into loopy_v
      if (cycle == 304 && is_pre_render) begin
        loopy_v <= loopy_t;
      end
    end
    if (write && ain == 0) begin
      loopy_t[10] <= din[0];
      loopy_t[11] <= din[1];
      ppu_incr <= din[2];
    end else if (write && ain == 5) begin
      if (!ppu_address_latch) begin
        loopy_t[4:0] <= din[7:3];
        loopy_x <= din[2:0];
      end else begin
        loopy_t[9:5] <= din[7:3];
        loopy_t[14:12] <= din[2:0];
      end
      ppu_address_latch <= !ppu_address_latch;
    end else if (write && ain == 6) begin
      if (!ppu_address_latch) begin
        loopy_t[13:8] <= din[5:0];
        loopy_t[14] <= 0;
      end else begin
        loopy_t[7:0] <= din;
        loopy_v <= {loopy_t[14:8], din};
      end
      ppu_address_latch <= !ppu_address_latch;
    end else if (read && ain == 2) begin
      ppu_address_latch <= 0; //Reset PPU address latch
    end else if ((read || write) && ain == 7 && !is_rendering) begin
      // Increment address every time we accessed a reg
      loopy_v <= loopy_v + (ppu_incr ? 32 : 1);
    end
  end
  assign loopy = loopy_v;
  assign fine_x_scroll = loopy_x;
endmodule
