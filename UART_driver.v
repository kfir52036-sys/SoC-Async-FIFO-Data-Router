module UART_driver(
  input SYS_CLK,
  input RST_N,
  input [31:0] DATA_UART,
  input VALID_UART,
  output reg READY_UART,
  output reg TX
  );
  
  reg [7:0] baud_rate;
  reg [1:0] state;
  reg [31:0] saved_data;
  reg [2:0] bit_cnt;
  reg [1:0] byte_cnt;
  
  localparam IDLE = 2'b00;
  localparam START = 2'b01;
  localparam DATA = 2'b10;
  localparam STOP = 2'b11;
  
  always @(posedge SYS_CLK or negedge RST_N) begin
    if (!RST_N) begin
      state <= IDLE;
      READY_UART <= 1'b1;
      TX <= 1'b1;
      saved_data <= 0;
      baud_rate <= 0;
      bit_cnt <= 0;
      byte_cnt <= 0;
    end
    else begin
      case (state)
        IDLE: begin
          TX <= 1'b1;
          READY_UART <= 1'b1;
          if (VALID_UART == 1) begin
            saved_data <= DATA_UART;
            READY_UART <= 1'b0;
            baud_rate <= 0;
            bit_cnt <= 0;
            byte_cnt <= 0;
            state <= START;
          end
        end
        
        START: begin
          TX <= 1'b0;
          if (baud_rate == 216) begin
            baud_rate <= 0;
            state <= DATA;
          end
          else begin
            baud_rate <= baud_rate + 1;
          end
        end
        
        DATA: begin
          TX <= saved_data [{byte_cnt,bit_cnt}];
          if (baud_rate == 216) begin
            baud_rate <= 0;
            if (bit_cnt == 7) begin
              bit_cnt <= 3'b000;
              state <= STOP;
            end
            else begin
              bit_cnt <= bit_cnt + 1;
            end
          end
          else begin
            baud_rate <= baud_rate + 1;
          end
        end
        
        STOP: begin
          TX <= 1'b1;
          if (baud_rate == 216) begin
            baud_rate <= 0;
            if (byte_cnt==3) begin
              state <= IDLE;
            end
            else begin
              byte_cnt <= byte_cnt + 1;
              state <= START;
            end
          end
          else begin
            baud_rate <= baud_rate + 1;
          end
        end
        
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end
  
endmodule
