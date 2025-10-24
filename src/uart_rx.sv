/*
-----------------------------------------------
|        UART RX Module for FPGA Debugger     |
|           Designed by Toby Wright           |
|              github.com/tobywr              |
|                   V1.0.0                    |
-----------------------------------------------
*/

`timescale 1ns / 1ps

module uart_rx #(
    parameter CLK_FREQ  = 50000000,  //50MHz clock
    parameter BAUD_RATE = 115200
) (
    input logic clk,
    input logic rst_n,

    input logic rx_i,

    output logic [7:0] rx_data_o,
    output logic rx_done
);

  localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;
  localparam HALF_BAUD = BAUD_TICK / 2;

  logic [15:0] baud_cnt = 0;
  logic [3:0] bit_cnt = 0;
  logic [7:0] rx_shift = 0;
  logic [1:0] rx_sync = 2'b11;
  logic rx_busy = 0;
  logic start_edge = 0;

  always_ff @(posedge clk) begin
    rx_sync <= {rx_sync[0], rx_i};
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      start_edge <= 0;
    end else begin
      start_edge <= (!rx_busy && rx_sync == 2'b10);
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_busy   <= 0;
      rx_done   <= 0;
      baud_cnt  <= 0;
      bit_cnt   <= 0;
      rx_shift  <= 0;
      rx_data_o <= 0;
    end else begin
      //default
      rx_done <= 0;
      if (start_edge) begin
        rx_busy  <= 1;
        baud_cnt <= 0;
        bit_cnt  <= 0;
      end else if (rx_busy) begin
        baud_cnt <= baud_cnt + 1;

        if ((bit_cnt == 0 && baud_cnt == HALF_BAUD) || (bit_cnt > 0 && baud_cnt == BAUD_TICK)) begin
          baud_cnt <= 0;
          bit_cnt  <= bit_cnt + 1;

          if (bit_cnt >= 1 && bit_cnt <= 8) begin
            rx_shift[bit_cnt-1] <= rx_sync[0];
          end

          if (bit_cnt == 9) begin
            rx_data_o <= rx_shift;
            rx_done   <= 1;
            rx_busy   <= 0;
          end
        end
      end
    end
  end

endmodule
