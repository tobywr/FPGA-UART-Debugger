/*
-----------------------------------------------
|         FIFO buffer for FPGA Debugger       |
|           Designed by Toby Wright           |
|              github.com/tobywr              |
|                   V1.0.0                    |
-----------------------------------------------
*/

`timescale 1ns / 1ps

module fifo #(
    parameter DataWidth = 8,
    parameter Depth = 16,
    localparam PtrWidth = $clog2(Depth)  // number of bits req. to fit 8 in binary.
) (
    input logic rst_n,
    input logic clk,

    input logic writeEN,
    input logic [DataWidth-1:0] writeData,
    input logic readEN,

    output logic [DataWidth-1:0] readData,
    output logic full,
    output logic empty
);

  logic [DataWidth-1:0] mem[Depth];
  logic [PtrWidth:0] wrPtr, wrPtrNext;  //write pointer (address to write to)
  logic [PtrWidth:0] rdPtr, rdPtrNext;  //read pointer (address to read from)

  always_comb begin
    wrPtrNext = wrPtr;
    rdPtrNext = rdPtr;

    if (writeEN && !full) begin
      wrPtrNext = wrPtr + 1;
    end

    if (readEN && !empty) begin
      rdPtrNext = rdPtr + 1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wrPtr <= '0;
      rdPtr <= '0;
      for (int i = 0; i < Depth; i = i + 1) begin
        mem[i] <= 0;
      end
    end else begin
      wrPtr <= wrPtrNext;
      rdPtr <= rdPtrNext;
      if (writeEN && !full) begin
        mem[wrPtr[PtrWidth-1:0]] <= writeData;  //only writes when not full and writeEn is high
      end
    end
  end

  assign readData = mem[rdPtr[PtrWidth-1:0]];
  assign empty = (wrPtr[PtrWidth] == rdPtr[PtrWidth]) && (wrPtr[PtrWidth-1:0] == rdPtr[PtrWidth-1:0]);
  assign full = (wrPtr[PtrWidth] != rdPtr[PtrWidth]) && (wrPtr[PtrWidth-1:0] == rdPtr[PtrWidth-1:0]);
endmodule
