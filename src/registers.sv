/*
-----------------------------------------------
| Register Module for FPGA Debugger over UART |
|           Designed by Toby Wright           |
|              github.com/tobywr              |
|                   V1.0.0                    |
-----------------------------------------------
*/


module registers #(
    parameter DATA_WIDTH = 8,
    parameter REG_FILE_SIZE = 256,
    parameter REG_ADDR_BITS = 8
) (
    input logic                     clk,
    input logic                     rst_n,
    input logic [REG_ADDR_BITS-1:0] addr_read,
    input logic [REG_ADDR_BITS-1:0] addr_write,
    input logic [   DATA_WIDTH-1:0] write_data,
    input logic                     write_enable,

    output logic [DATA_WIDTH-1:0] read_data
);
  logic [DATA_WIDTH-1:0] register[0:REG_FILE_SIZE-1];  //creating registers

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      //reset all registers to 0 when reset is high
      for (int i = 0; i < REG_FILE_SIZE; i = i + 1) begin
        register[i] <= '0;
      end
    end else if (write_enable && addr_write != 0) begin
      register[addr_write] <= write_data;
    end
  end

  // forcing address 0 to read as zero in all registers.
  always_comb begin
    if (addr_read == 0) begin
      read_data = '0;
    end else begin
      read_data = register[addr_read];
    end
  end


endmodule
