// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

////`include "cpu.v"
//`include "apu.v"
//`include "ppu.v"
//`include "mmu.v"



module NES(input clk, input reset, input ce,
           input [31:0] mapper_flags,
           output [15:0] sample, // sample generated from APU
           output [5:0] color,  // pixel generated from PPU
           output joypad_strobe,// Set to 1 to strobe joypads. Then set to zero to keep the value.
           output [1:0] joypad_clock, // Set to 1 for each joypad to clock it.
           input [1:0] joypad_data, // Data for each joypad.
           input [4:0] audio_channels, // Enabled audio channels

           
           // Access signals for the SRAM.
           output [21:0] memory_addr,   // address to access
           output memory_read_cpu,      // read into CPU latch
           input [7:0] memory_din_cpu,  // next cycle, contents of latch A (CPU's data)
           output memory_read_ppu,      // read into CPU latch
           input [7:0] memory_din_ppu,  // next cycle, contents of latch B (PPU's data)
           output memory_write,         // is a write operation
           output [7:0] memory_dout,
           
           output [8:0] cycle,
           output [8:0] scanline,
           
           output reg [31:0] dbgadr,
           output [1:0] dbgctr
           );
  reg [7:0] from_data_bus;
  wire [7:0] cpu_dout;
  wire odd_or_even; // Is this an odd or even clock cycle?

  // The CPU runs at one third the speed of the PPU.
  // CPU is clocked at cycle #2. PPU is clocked at cycle #0, #1, #2.
  // CPU does its memory I/O on cycle #0. It will be available in time for cycle #2.
  reg [1:0] cpu_cycle_counter;
  always @(posedge clk) begin
    if (reset)
      cpu_cycle_counter <= 0;
    else if (ce)
      cpu_cycle_counter <= (cpu_cycle_counter == 2) ? 0 : cpu_cycle_counter + 1;
  end

  // Sample the NMI flag on cycle #0, otherwise if NMI happens on cycle #0 or #1,
  // the CPU will use it even though it shouldn't be used until the next CPU cycle.
  wire nmi;
  reg nmi_active;
  always @(posedge clk) begin
    if (reset)
      nmi_active <= 0;
    else if (ce && cpu_cycle_counter == 0)
      nmi_active <= nmi;
  end

  wire apu_ce =        ce && (cpu_cycle_counter == 2);

  // -- CPU
  wire [15:0] cpu_addr;
  wire cpu_mr, cpu_mw;
  wire pause_cpu;
  reg apu_irq_delayed;
  reg mapper_irq_delayed;
  CPU cpu(clk, apu_ce && !pause_cpu, reset, from_data_bus, apu_irq_delayed | mapper_irq_delayed, nmi_active, cpu_dout, cpu_addr, cpu_mr, cpu_mw);

  // -- DMA
  wire [15:0] dma_aout;
  wire dma_aout_enable;
  wire dma_read;
  wire [7:0] dma_data_to_ram;
  wire apu_dma_request, apu_dma_ack;
  wire [15:0] apu_dma_addr;

  // Determine the values on the bus outgoing from the CPU chip (after DMA / APU)
  wire [15:0] addr = dma_aout_enable ? dma_aout : cpu_addr;
  wire [7:0]  dbus = dma_aout_enable ? dma_data_to_ram : cpu_dout;
  wire mr_int      = dma_aout_enable ? dma_read : cpu_mr;
  wire mw_int      = dma_aout_enable ? !dma_read : cpu_mw;

  DmaController dma(clk, apu_ce, reset, 
                    odd_or_even,                    // Even or odd cycle
                    (addr == 'h4014 && mw_int),     // Sprite trigger
                    apu_dma_request,                // DMC Trigger
                    cpu_mr,                         // CPU in a read cycle?
                    cpu_dout,                       // Data from cpu
                    from_data_bus,                  // Data from RAM etc.
                    apu_dma_addr,                   // DMC addr
                    dma_aout,
                    dma_aout_enable, 
                    dma_read,
                    dma_data_to_ram,
                    apu_dma_ack,
                    pause_cpu);

  // -- Audio Processing Unit  
  wire apu_cs = addr >= 'h4000 && addr < 'h4018;
  wire [7:0] apu_dout;
  wire apu_irq;
  APU apu(clk, apu_ce, reset,
          addr[4:0], dbus, apu_dout, 
          mw_int && apu_cs, mr_int && apu_cs,
          audio_channels,
          sample,
          apu_dma_request,
          apu_dma_ack,
          apu_dma_addr,
          from_data_bus,
          odd_or_even,
          apu_irq);

  // Joypads are mapped into the APU's range.
  wire joypad1_cs = (addr == 'h4016);
  wire joypad2_cs = (addr == 'h4017);
  assign joypad_strobe = (joypad1_cs && mw_int && cpu_dout[0]);
  assign joypad_clock =  {joypad2_cs && mr_int, joypad1_cs && mr_int};

      
  // -- PPU
  // PPU _reads_ need to happen on the same cycle the cpu runs on, to guarantee we
  // see proper values of register $2002.
  wire mr_ppu     = mr_int && (cpu_cycle_counter == 2);
  wire mw_ppu     = mw_int && (cpu_cycle_counter == 0);
  wire ppu_cs = addr >= 'h2000 && addr < 'h4000;
  wire [7:0] ppu_dout;           // Data from PPU to CPU
  wire chr_read, chr_write;      // If PPU reads/writes from VRAM
  wire [13:0] chr_addr;          // Address PPU accesses in VRAM
  wire [7:0] chr_from_ppu;       // Data from PPU to VRAM
  wire [7:0] chr_to_ppu;
  wire [19:0] mapper_ppu_flags;  // PPU flags for mapper cheating
  PPU ppu(clk, ce, reset, color, dbus, ppu_dout, addr[2:0],
          ppu_cs && mr_ppu, ppu_cs && mw_ppu,
          nmi,
          chr_read, chr_write, chr_addr, chr_to_ppu, chr_from_ppu,
          scanline, cycle, mapper_ppu_flags);

  // -- Memory mapping logic
  wire [15:0] prg_addr = addr;
  wire [7:0] prg_din = dbus;
  wire prg_read = mr_int && (cpu_cycle_counter == 0) && !apu_cs && !ppu_cs;
  wire prg_write = mw_int && (cpu_cycle_counter == 0) && !apu_cs && !ppu_cs;
  wire prg_allow, vram_a10, vram_ce, chr_allow;
  wire [21:0] prg_linaddr, chr_linaddr;
  wire [7:0] prg_dout_mapper, chr_from_ppu_mapper;
  wire cart_ce = (cpu_cycle_counter == 0) && ce;
  wire mapper_irq;
  wire has_chr_from_ppu_mapper;
  MultiMapper multi_mapper(clk, cart_ce, ce, reset, mapper_ppu_flags, mapper_flags, 
                           prg_addr, prg_linaddr, prg_read, prg_write, prg_din, prg_dout_mapper, from_data_bus, prg_allow,
                           chr_read, chr_addr, chr_linaddr, chr_from_ppu_mapper, has_chr_from_ppu_mapper, chr_allow, vram_a10, vram_ce, mapper_irq);
  assign chr_to_ppu = has_chr_from_ppu_mapper ? chr_from_ppu_mapper : memory_din_ppu;
                             
  // Mapper IRQ seems to be delayed by one PPU clock.   
  // APU IRQ seems delayed by one APU clock.
  always @(posedge clk) if (reset) begin
    mapper_irq_delayed <= 0;
    apu_irq_delayed <= 0;
  end else begin
    if (ce)
      mapper_irq_delayed <= mapper_irq;
    if (apu_ce)
      apu_irq_delayed <= apu_irq;
  end
   
  // -- Multiplexes CPU and PPU accesses into one single RAM
  MemoryMultiplex mem(clk, ce, prg_linaddr, prg_read && prg_allow, prg_write && prg_allow, prg_din, 
                               chr_linaddr, chr_read,              chr_write && (chr_allow || vram_ce), chr_from_ppu,
                               memory_addr, memory_read_cpu, memory_read_ppu, memory_write, memory_dout);

  always @* begin
    if (apu_cs) begin
      if (joypad1_cs)
        from_data_bus = {7'b0100000, joypad_data[0]};
      else if (joypad2_cs)
        from_data_bus = {7'b0100000, joypad_data[1]};
      else
        from_data_bus = apu_dout;
    end else if (ppu_cs) begin
      from_data_bus = ppu_dout;
    end else if (prg_allow) begin
      from_data_bus = memory_din_cpu;
    end else begin
      from_data_bus = prg_dout_mapper;
    end
  end
  
endmodule
