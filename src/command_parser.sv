/*
-----------------------------------------------
|        Command Parser for FPGA Debugger     |
|           Designed by Toby Wright           |
|              github.com/tobywr              |
|                   V1.0.0                    |
-----------------------------------------------
*/

module command_parser #(
    parameter DATA_WIDTH = 8,
    parameter REG_ADDR_BITS = 8
) (
    input logic clk,
    input logic rst_n,

    //data from FIFO memory
    input logic [DATA_WIDTH-1:0] readData,
    input logic empty,
    output logic readEN,

    //data from reg
    input logic [DATA_WIDTH-1:0] read_data,
    output logic [REG_ADDR_BITS-1:0] addr_read,
    output logic [REG_ADDR_BITS-1:0] addr_write,
    output logic [DATA_WIDTH-1:0] write_data,
    output logic write_enable,

    //uart TX logic
    output logic [7:0] tx_data_o,
    output logic tx_start,
    input logic busy
);

  typedef enum logic [3:0] {
    IDLE,
    PARSE_ADDR_UPPER,
    PARSE_ADDR_LOWER,
    PARSE_DATA_UPPER,
    PARSE_DATA_LOWER,
    EXECUTE_WRITE,
    EXECUTE_READ,
    RESPOND_SEND
  } state_t;

  state_t state_reg, next_state;

  //internal reg's for parsed values.
  logic [7:0] cmd_reg, cmd_next;
  logic [REG_ADDR_BITS-1:0] addr_reg, addr_next;
  logic [DATA_WIDTH-1:0] data_reg, data_next;
  logic [2:0] response_idx, response_idx_next;  //ccounter for sending response chars

  //variables for comb logic.
  logic [3:0] hex_nibble;  //result of ascii->hex (4 bit)
  logic [7:0] ascii_char;  //result of hex->ascii (8 bit)

  logic [3:0] nibble_to_send;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_reg <= IDLE;
      cmd_reg <= 8'h00;
      addr_reg <= '0;
      data_reg <= '0;
      response_idx <= '0;
    end else begin
      state_reg <= next_state;  //update state every clock edge
      cmd_reg <= cmd_next;
      addr_reg <= addr_next;
      data_reg <= data_next;
      response_idx <= response_idx_next;
    end
  end

  always_comb begin

    next_state = state_reg;
    cmd_next = cmd_reg;
    addr_next = addr_reg;
    data_next = data_reg;
    response_idx_next = response_idx;

    readEN = 1'b0;
    write_enable = 1'b0;
    tx_start = 1'b0;
    addr_read = addr_reg;
    addr_write = addr_reg;
    write_data = data_reg;
    tx_data_o = 8'h00;
    hex_nibble = 4'hX;  //default to dont care.
    ascii_char = "?";  //default to ?

    //Ascii to hex conversion from fifo data input (from cli.)
    case (readData)
      "0": hex_nibble = 4'h0;
      "1": hex_nibble = 4'h1;
      "2": hex_nibble = 4'h2;
      "3": hex_nibble = 4'h3;
      "4": hex_nibble = 4'h4;
      "5": hex_nibble = 4'h5;
      "6": hex_nibble = 4'h6;
      "7": hex_nibble = 4'h7;
      "8": hex_nibble = 4'h8;
      "9": hex_nibble = 4'h9;
      "a", "A": hex_nibble = 4'hA;
      "b", "B": hex_nibble = 4'hB;
      "c", "C": hex_nibble = 4'hC;
      "d", "D": hex_nibble = 4'hD;
      "e", "E": hex_nibble = 4'hE;
      "f", "F": hex_nibble = 4'hF;
      default: hex_nibble = 4'hX;  //default dont care.
    endcase

    case (state_reg)
      IDLE: begin
        if (!empty) begin
          readEN = 1'b1;
          if (readData == "w") begin
            cmd_next   = "w";
            next_state = PARSE_ADDR_UPPER;
          end else if (readData == "r") begin
            cmd_next   = "r";
            next_state = PARSE_ADDR_UPPER;
          end
        end
      end

      PARSE_ADDR_UPPER: begin
        if (!empty) begin
          addr_next[REG_ADDR_BITS-1:REG_ADDR_BITS-4] = hex_nibble;
          addr_next[REG_ADDR_BITS-5:0] = addr_reg[REG_ADDR_BITS-5:0];
          readEN = 1'b1;
          next_state = PARSE_ADDR_LOWER;
        end
      end

      PARSE_ADDR_LOWER: begin
        if (!empty) begin
          addr_next[REG_ADDR_BITS-1:REG_ADDR_BITS-4] = addr_reg[REG_ADDR_BITS-1:REG_ADDR_BITS-4];
          addr_next[REG_ADDR_BITS-5:0] = hex_nibble;
          if (cmd_reg == "w") begin
            readEN = 1'b1;
            next_state = PARSE_DATA_UPPER;
          end else begin  // 'r' command used.
            next_state = EXECUTE_READ;
          end
        end
      end

      PARSE_DATA_UPPER: begin
        if (!empty) begin
          data_next[DATA_WIDTH-1:DATA_WIDTH-4] = hex_nibble;
          data_next[DATA_WIDTH-5:0] = data_reg[DATA_WIDTH-5:0];
          readEN = 1'b1;
          next_state = PARSE_DATA_LOWER;
        end
      end

      PARSE_DATA_LOWER: begin
        if (!empty) begin
          data_next[DATA_WIDTH-5:0] = hex_nibble;
          data_next[DATA_WIDTH-1:DATA_WIDTH-4] = data_reg[DATA_WIDTH-1:DATA_WIDTH-4];
          next_state = EXECUTE_WRITE;
        end
      end

      EXECUTE_WRITE: begin
        write_enable = 1'b1;
        response_idx_next = 0;
        next_state = IDLE;
      end

      EXECUTE_READ: begin
        data_next = read_data;
        response_idx_next = 0;
        next_state = RESPOND_SEND;
      end

      RESPOND_SEND: begin
        //only send if tx not busy.
        if (!busy) begin
          tx_start = 1'b1;
          //determine which nibble to send.
          if (response_idx == 2) nibble_to_send = data_reg[7:4];
          else if (response_idx == 3) nibble_to_send = data_reg[3:0];
          else nibble_to_send = 4'hX;  //default.

          //hex to ascii conversion.
          case (nibble_to_send)
            4'h0: ascii_char = "0";
            4'h1: ascii_char = "1";
            4'h2: ascii_char = "2";
            4'h3: ascii_char = "3";
            4'h4: ascii_char = "4";
            4'h5: ascii_char = "5";
            4'h6: ascii_char = "6";
            4'h7: ascii_char = "7";
            4'h8: ascii_char = "8";
            4'h9: ascii_char = "9";
            4'hA: ascii_char = "A";
            4'hB: ascii_char = "B";
            4'hC: ascii_char = "C";
            4'hD: ascii_char = "D";
            4'hE: ascii_char = "E";
            4'hF: ascii_char = "F";
            default: ascii_char = "?";
          endcase

          //select which char to send
          case (response_idx)
            0: tx_data_o = "\n";  //newline
            1: tx_data_o = ">";  //prompt
            2: tx_data_o = ascii_char;  //upper nibble
            3: tx_data_o = ascii_char;  //lower nibble.
          endcase

          if (response_idx == 3) begin
            next_state = IDLE;
          end else begin
            response_idx_next = response_idx + 1;
          end
        end
      end
      default: next_state = IDLE;
    endcase
  end
endmodule
