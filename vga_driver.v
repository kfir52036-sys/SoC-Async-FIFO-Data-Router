module vga_driver(
  input SYS_CLK,
  input RST_N,
  input [31:0] DATA_VGA,
  input VALID_VGA,
  output READY_VGA,
  output H_SYNC,
  output V_SYNC,
  output [3:0] VGA_R,
  output [3:0] VGA_G,
  output [3:0] VGA_B 
  );
  
  reg [9:0] h_cnt = 10'b0;
  reg [9:0] v_cnt = 10'b0;
  reg [31:0] saved_data;
  reg [3:0] current_nibble;
  
  wire active_video;
  wire pixel_out;
  wire text_area = (h_cnt < 64) && (v_cnt < 16);

  always @(posedge SYS_CLK or negedge RST_N) begin
    if (!RST_N) begin
      h_cnt <= 10'b0;
      v_cnt <= 10'b0;
    end
    else begin
      if (h_cnt == 799) begin
        h_cnt <= 10'b0;
        if(v_cnt == 524) begin
          v_cnt <= 10'b0;
        end
        else begin
          v_cnt <= v_cnt + 1;
        end
      end
      else begin
        h_cnt <= h_cnt + 1;
      end
    end
  end
  
  always @(posedge SYS_CLK or negedge RST_N) begin
    if (!RST_N) begin
      saved_data <= 32'b0;
    end
    else begin
      if (VALID_VGA == 1'b1) begin
        saved_data <= DATA_VGA;
      end
    end
  end
  
  assign H_SYNC = ((h_cnt >= 656) && (h_cnt <= 751)) ? 1'b0 : 1'b1; 
  assign V_SYNC = ((v_cnt >= 490) && (v_cnt <= 491)) ? 1'b0 : 1'b1; 
  assign active_video = ((v_cnt < 480) && (h_cnt < 640)) ? 1'b1 : 1'b0;
  
  always @(*) begin
    case(h_cnt[5:3]) 
      3'b000: current_nibble = saved_data[31:28];
      3'b001: current_nibble = saved_data[27:24];
      3'b010: current_nibble = saved_data[23:20];
      3'b011: current_nibble = saved_data[19:16];
      3'b100: current_nibble = saved_data[15:12];
      3'b101: current_nibble = saved_data[11:8];
      3'b110: current_nibble = saved_data[7:4];
      3'b111: current_nibble = saved_data[3:0];
      default : current_nibble = 4'b0000;
    endcase
  end
  
  
 hex_font_rom my_font_rom(
  .char_idx(current_nibble), 
  .row_idx(v_cnt[3:0]),  
  .col_idx(h_cnt[2:0]),  
  .pixel_on(pixel_out)
  );
  
  assign VGA_R = 4'b0000;
  assign VGA_G = (active_video && text_area && pixel_out) ? 4'b1111 : 4'b0000;
  assign VGA_B = 4'b0000;
  
  assign READY_VGA = 1'b1;
endmodule
