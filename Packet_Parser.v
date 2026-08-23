module Packet_Parser(
  input [63:0] FIFO_DATA ,
  input FIFO_EMPTY,
  input ROUTER_READY,
  input SYS_CLK,
  input RST_N,
  output reg FIFO_READ,
  output reg [31:0] PARSED_DATA ,
  output reg PARSED_VALID,
  output reg [1:0] DEST_ID,
  output reg HEADER_ERR,
  output reg DATA_ERR);
  
  localparam IDLE = 2'b00;
  localparam PARSE_HEADER = 2'b01;
  localparam CHECK_PAYLOAD = 2'b10;
  localparam ROUTE = 2'b11;
  
  reg [1:0] state;
  
  always @(posedge SYS_CLK or negedge RST_N) begin
    if (!RST_N) begin
      state <= IDLE;
      FIFO_READ <= 1'b0;
      PARSED_DATA <= 32'b0;
      PARSED_VALID <= 1'b0;
      DEST_ID <= 2'b0;
      HEADER_ERR <= 1'b0;
      DATA_ERR <= 1'b0;
    end
    else begin
      case (state)
        IDLE: begin
          PARSED_VALID <= 1'b0;
          HEADER_ERR <= 1'b0;
          DATA_ERR <= 1'b0;
          if (FIFO_EMPTY == 1'b0) begin
            FIFO_READ <= 1'b1;
            state <= PARSE_HEADER;
          end
          else begin
            FIFO_READ <= 1'b0;
            state <= IDLE;
          end
        end
        PARSE_HEADER:begin
          FIFO_READ <= 1'b0;
           if (FIFO_DATA [63:56] == 8'hAA && FIFO_DATA[47:40]==(8'hAA ^ {FIFO_DATA[55:54], FIFO_DATA[53:48]})) begin
             DEST_ID <= FIFO_DATA[55:54];
             PARSED_DATA <= FIFO_DATA[39:8];
             state <= CHECK_PAYLOAD;
           end
           else begin
             HEADER_ERR <= 1'b1;
             state <= IDLE;
           end
        end
      
        CHECK_PAYLOAD:begin
          if (FIFO_DATA[7:0]==(FIFO_DATA [39:32] ^ FIFO_DATA [31:24] ^ FIFO_DATA [23:16] ^ FIFO_DATA [15:8])) begin
            state <= ROUTE;
          end
          else begin
            DATA_ERR <= 1'b1;
            state <= IDLE;
          end
        end
      
        ROUTE:begin
          if (ROUTER_READY == 1'b1) begin
            PARSED_VALID <= 1'b1;
            state <= IDLE;
          end
          else begin
            state <= ROUTE;
          end
        end
    
      endcase
    end
  end
endmodule
