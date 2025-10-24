/*
-----------------------------------------------
|      Top level Module for FPGA Debugger     |
|           Designed by Toby Wright           |
|              github.com/tobywr              |
|                   V1.0.0                    |
-----------------------------------------------
*/

`timescale 1ns / 1ps
module fpga_debug_top #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200,
    parameter DATA_WIDTH = 8,
    parameter REG_ADDR_BITS = 8,
    parameter FIFO_DEPTH = 16
) (
    input  logic clk,
    input  logic i_uart_rx_pin,
    output logic o_uart_tx_pin,
    input  logic rst_n,
    output logic led
);

  //alive blinking led.
  logic [25:0] blink_cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) blink_cnt <= '0;
    else blink_cnt <= blink_cnt + 1;
  end
  assign led = blink_cnt[25];

  //internal signals.

  //uart -> fifo
  logic [DATA_WIDTH-1:0] rx_data;
  logic rx_done;

  //FIFO -> command parser
  logic [DATA_WIDTH-1:0] fifo_read_data;
  logic fifo_empty;
  logic fifo_full;
  logic parser_read_en;

  //command parser -> regs
  logic [DATA_WIDTH-1:0] reg_read_data;
  logic [REG_ADDR_BITS-1:0] reg_addr_read;
  logic [REG_ADDR_BITS-1:0] reg_addr_write;
  logic [DATA_WIDTH-1:0] reg_write_data;
  logic reg_write_enable;

  //command parser -> uart tx
  logic [DATA_WIDTH-1:0] tx_data;
  logic tx_start;
  logic tx_busy;

  uart_rx #(
      .CLK_FREQ (CLK_FREQ),
      .BAUD_RATE(BAUD_RATE)
  ) u_uart_rx (
      .clk(clk),
      .rst_n(rst_n),
      .rx_i(i_uart_rx_pin),
      .rx_data_o(rx_data),
      .rx_done(rx_done)
  );

  fifo #(
      .DataWidth(DATA_WIDTH),
      .Depth(FIFO_DEPTH)
  ) u_fifo (
      .clk(clk),
      .rst_n(rst_n),
      .writeEN(rx_done),
      .writeData(rx_data),
      .readEN(parser_read_en),
      .readData(fifo_read_data),
      .full(fifo_full),
      .empty(fifo_empty)
  );

  command_parser #(
      .DATA_WIDTH(DATA_WIDTH),
      .REG_ADDR_BITS(REG_ADDR_BITS)
  ) u_command_parser (
      .clk(clk),
      .rst_n(rst_n),
      .readData(fifo_read_data),
      .empty(fifo_empty),
      .readEN(parser_read_en),
      .read_data(reg_read_data),
      .addr_read(reg_addr_read),
      .addr_write(reg_addr_write),
      .write_data(reg_write_data),
      .write_enable(reg_write_enable),
      .tx_data_o(tx_data),
      .tx_start(tx_start),
      .busy(tx_busy)
  );

  registers #(
      .DATA_WIDTH(DATA_WIDTH),
      .REG_FILE_SIZE(1 << REG_ADDR_BITS),
      .REG_ADDR_BITS(REG_ADDR_BITS)
  ) u_registers (
      .clk(clk),
      .rst_n(rst_n),
      .addr_read(reg_addr_read),
      .addr_write(reg_addr_write),
      .write_data(reg_write_data),
      .write_enable(reg_write_enable),
      .read_data(reg_read_data)
  );

  uart_tx #(
      .CLK_FREQ (CLK_FREQ),
      .BAUD_RATE(BAUD_RATE)
  ) u_uart_tx (
      .clk(clk),
      .rst_n(rst_n),
      .tx_data_i(tx_data),
      .tx_start(tx_start),
      .tx_o(o_uart_tx_pin),
      .tx_busy(tx_busy)
  );


endmodule
