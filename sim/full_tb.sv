`timescale 1ns / 1ps

module full_tb;

  localparam CLK_FREQ = 50000000;
  localparam BAUD_RATE = 115200;
  localparam CLK_PERIOD = 20ns;
  localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;

  logic clk;
  logic rst_n;
  logic i_uart_rx_pin;
  logic o_uart_tx_pin;
  logic led;

  //instantiate dut
  fpga_debug_top #(
      .CLK_FREQ (CLK_FREQ),
      .BAUD_RATE(BAUD_RATE)
  ) u_dut (
      .clk(clk),
      .rst_n(rst_n),
      .i_uart_rx_pin(i_uart_rx_pin),
      .o_uart_tx_pin(o_uart_tx_pin),
      .led(led)
  );

  //clock gen
  always #10ns clk = ~clk;

  //UART send task.
  task send_uart_byte(input [7:0] input_byte);
    //start bit
    i_uart_rx_pin = 1'b0;
    #(BAUD_TICK * CLK_PERIOD);
    //8 data bits. (LSB first)
    for (int i = 0; i < 8; i = i + 1) begin
      i_uart_rx_pin = input_byte[i];
      #(BAUD_TICK * CLK_PERIOD);
    end
    //stop bit
    i_uart_rx_pin = 1'b1;
    #(BAUD_TICK * CLK_PERIOD);
  endtask

  //main sim
  initial begin
    clk = 1'b0;
    rst_n = 1'b0;  //start in rst
    i_uart_rx_pin = 1'b1;  //uart idle is high.
    //hold rst
    #10000ns;
    rst_n = 1'b1;
    $display("Waiting for logic to settle after rst");
    #10000ns;
    $display("[%0t ns] Logic settled after reset", $time);
    //simulate write command.
    $display("[%0t ns] --- Sending write command : w01AA ---", $time);
    send_uart_byte("w");
    send_uart_byte("0");
    send_uart_byte("1");
    send_uart_byte("A");
    send_uart_byte("A");
    #10000ns;
    //read from reg 01.
    $display("[%0t ns] --- Reading from reg 01 ---", $time);
    send_uart_byte("r");
    send_uart_byte("0");
    send_uart_byte("1");
    $display("[%0t ns] --- Waiting for response ---", $time);
    wait (o_uart_tx_pin == 0);

    $display("[%0t ns] --- Start bit detected of response! ---", $time);
    #1000000ns;  //wait 1ms for response to show.
    $display("Simulation complete. Check waveforms to see UART_TX output and check if correct.");
    $finish;
  end

endmodule
