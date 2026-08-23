module led_driver(
  input SYS_CLK,
  input RST_N,
  input [31:0] DATA_LEDS,
  input VALID_LEDS,
  output READY_LEDS,
  output [15:0] LEDS);
  
  reg [31:0] saved_data;
  reg [25:0] cnt;
  
  always @(posedge SYS_CLK or negedge RST_N) begin
    if (!RST_N) begin
      saved_data <= 32'b0;
    end
    else begin
      if (VALID_LEDS == 1'b1) begin
        saved_data <= DATA_LEDS;
      end
    end
  end
  
  always @(posedge SYS_CLK or negedge RST_N) begin
    if (!RST_N) begin
      cnt <= 26'b0;
    end
    else begin
      cnt <= cnt + 1;
    end
  end
  
  assign READY_LEDS = 1'b1;
  assign LEDS = (cnt[25] == 1'b0) ? saved_data[15:0] : saved_data[31:16];
endmodule
