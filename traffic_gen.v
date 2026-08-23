module traffic_gen(
  input RX_CLK,
  input RST_N,
  input FIFO_FULL,
  output [63:0] RX_DATA,
  output RX_VALID);
  
  reg [3:0] cnt = 0;
  reg [63:0] DATA = 64'b0;
  reg VALID = 1'b0;
  reg [31:0] random_val = 32'hACE1_5555;
  
  wire [1:0] Dest_ID = random_val[5:4];
  wire [5:0] Length = random_val[15:10];
  wire [7:0] data_cs = {random_val[31:24] ^ random_val[23:16] ^ random_val[15:8] ^ random_val[7:0]};
  wire [7:0] header_cs = {8'hAA ^ {Dest_ID, Length}};
  
  always @(posedge RX_CLK or negedge RST_N) begin
   if (!RST_N) begin
     cnt <= 4'b0;
     DATA <= 64'b0;
     VALID <= 1'b0;
     random_val <= 32'hACE1_5555;
   end
   else begin
     random_val <= {random_val[30:0], random_val[31] ^ random_val[21] ^ random_val[1] ^ random_val[0]};
     if (cnt==4'b1010 && FIFO_FULL == 0) begin
       cnt <= 4'b0;
       VALID <= 1'b1;
       DATA <= {8'hAA, Dest_ID, Length, header_cs, random_val, data_cs};
     end
     else begin
       cnt <= cnt + 1;
       VALID <= 1'b0;
     end
   end
  end
  
  assign RX_DATA = DATA;
  assign RX_VALID = VALID;
endmodule
