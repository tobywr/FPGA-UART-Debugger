/*
-----------------------------------------------
|        UART TX Module for FPGA Debugger     |
|           Designed by Toby Wright           |
|              github.com/tobywr              |
|                   V1.0.0                    |
-----------------------------------------------
*/

`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ  = 50000000,  //50MHz Clock
    parameter BAUD_RATE = 115200
) (
    input logic clk,
    input logic rst_n,

    input logic [7:0] tx_data_i,
    input logic tx_start,

    output logic tx_o,
    output logic tx_busy
);

  localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;

  logic [15:0] baud_cnt = '0;
  logic [ 3:0] bit_idx = '0;
  logic [ 9:0] tx_shift = 10'b1111111111;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_o <= 1;
      tx_busy <= 0;
      baud_cnt <= 0;
      bit_idx <= 0;
      tx_shift <= 10'b1111111111;
    end else if (tx_start && !tx_busy) begin
      tx_shift <= {1'b1, tx_data_i, 1'b0};
      tx_busy  <= 1;
      baud_cnt <= 0;
      bit_idx  <= 0;
    end else if (tx_busy) begin
      if (baud_cnt == BAUD_TICK - 1) begin
        baud_cnt <= 0;
        tx_o <= tx_shift[bit_idx];
        bit_idx <= bit_idx + 1;

        if (bit_idx == 9) begin
          tx_busy <= 0;
          tx_o <= 1;
        end
      end else begin
        baud_cnt <= baud_cnt + 1;
      end
    end
  end

endmodule
