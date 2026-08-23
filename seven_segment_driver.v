module seven_segment_driver(
  input SYS_CLK,
  input RST_N,
  input [31:0] DATA_7SEG,
  input VALID_7SEG,
  output READY_7SEG,
  output [3:0] AN,
  output [6:0] SEG
  );
  
  reg [31:0] saved_data;
  reg [25:0] cnt;
  reg [3:0] current_nibble;
  reg [3:0] current_AN;
  reg [6:0] current_SEG;
  
  wire [15:0] active_16bit;
  
  always @(posedge SYS_CLK or negedge RST_N) begin
    if (!RST_N) begin
      saved_data <= 32'b0;
    end
    else begin
      if (VALID_7SEG == 1) begin
        saved_data <= DATA_7SEG;
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
  
  always @(*) begin
    case(cnt[16:15])
      2'b00: begin
        current_nibble = active_16bit [15:12];
        current_AN = 4'b0111;
      end
      2'b01: begin
        current_nibble = active_16bit [11:8];
        current_AN = 4'b1011;
      end
      2'b10: begin
        current_nibble = active_16bit [7:4];
        current_AN = 4'b1101;
      end
      2'b11: begin
        current_nibble = active_16bit [3:0];
        current_AN = 4'b1110;
      end  
      default: begin
        current_nibble = 4'b0000;
        current_AN = 4'b1111;
      end
    endcase
  end
  
  always @(*) begin
    case(current_nibble)
      4'h0: current_SEG = 7'b1000000;
      4'h1: current_SEG = 7'b1111001;
      4'h2: current_SEG = 7'b0100100;
      4'h3: current_SEG = 7'b0110000;
      4'h4: current_SEG = 7'b0011001;
      4'h5: current_SEG = 7'b0010010;
      4'h6: current_SEG = 7'b0000010;
      4'h7: current_SEG = 7'b1111000;
      4'h8: current_SEG = 7'b0000000;
      4'h9: current_SEG = 7'b0010000;
      4'hA: current_SEG = 7'b0001000;
      4'hB: current_SEG = 7'b0000011;
      4'hC: current_SEG = 7'b1000110;
      4'hD: current_SEG = 7'b0100001;
      4'hE: current_SEG = 7'b0000110;
      4'hF: current_SEG = 7'b0001110;
      default: current_SEG = 7'b1111111;
    endcase
  end
  
  assign READY_7SEG = 1'b1;
  assign active_16bit = (cnt[25] == 1'b0) ? saved_data[31:16] : saved_data[15:0];
  assign AN = current_AN;
  assign SEG = current_SEG;
endmodule
