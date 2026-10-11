module top_module(
  input RX_CLK,
  input RST_N,
  output H_SYNC,V_SYNC,
  output [3:0] VGA_R, VGA_G, VGA_B,
  output [6:0] SEG,
  output [3:0] AN,
  output [15:0] LEDS,
  output TX
  );
  
  wire [63:0] tg_data;
  wire tg_valid;
  wire fifo_full_flag;
  
  wire [63:0] fifo_data_out;
  wire fifo_empty_flag;
  wire parser_read_flag;
  
  wire [31:0] PARSED_DATA;
  wire PARSED_VALID;
  wire [1:0] DEST_ID;
  wire HEADER_ERR;
  wire DATA_ERR;
  
  wire READY_7SEG;
  wire READY_VGA;
  wire READY_UART;
  wire READY_LEDS;
  wire ROUTER_READY;
  wire [31:0] DATA_7SEG;
  wire VALID_7SEG;
  wire [31:0] DATA_VGA;
  wire VALID_VGA;
  wire [31:0] DATA_UART;
  wire VALID_UART;
  wire [31:0] DATA_LEDS;
  wire VALID_LEDS;
  
  wire SYS_CLK;
  
  clk_wiz_0 clk_inst(
  .resetn(RST_N),
  .RX_CLK(RX_CLK),
  .SYS_CLK(SYS_CLK)
  );

  
  traffic_gen tg_ints(
    .RX_CLK(RX_CLK),
    .RST_N(RST_N),
    .FIFO_FULL(fifo_full_flag),
    .RX_DATA(tg_data),
    .RX_VALID(tg_valid));
  
  async_fifo fifo(
    .RST_N(RST_N),
    .RX_CLK(RX_CLK),
    .RX_DATA(tg_data),
    .RX_VALID(tg_valid),
    .FIFO_FULL(fifo_full_flag),
    .FIFO_READ(parser_read_flag),
    .SYS_CLK(SYS_CLK),
    .FIFO_DATA(fifo_data_out),
    .FIFO_EMPTY(fifo_empty_flag));
    
  Packet_Parser Parser(
    .FIFO_DATA(fifo_data_out),
    .FIFO_EMPTY(fifo_empty_flag),
    .ROUTER_READY(ROUTER_READY),
    .SYS_CLK(SYS_CLK),
    .RST_N(RST_N),
    .FIFO_READ(parser_read_flag),
    .PARSED_DATA (PARSED_DATA),
    .PARSED_VALID(PARSED_VALID),
    .DEST_ID(DEST_ID),
    .HEADER_ERR(HEADER_ERR),
    .DATA_ERR(DATA_ERR));
  
  packet_router router(
    .PARSED_DATA(PARSED_DATA),
    .PARSED_VALID(PARSED_VALID),
    .DEST_ID(DEST_ID),
    .READY_7SEG(READY_7SEG),
    .READY_VGA(READY_VGA),
    .READY_UART(READY_UART),
    .READY_LEDS(READY_LEDS),
    .ROUTER_READY(ROUTER_READY),
    .DATA_7SEG(DATA_7SEG),
    .VALID_7SEG(VALID_7SEG),
    .DATA_VGA(DATA_VGA),
    .VALID_VGA(VALID_VGA),
    .DATA_UART(DATA_UART),
    .VALID_UART(VALID_UART),
    .DATA_LEDS(DATA_LEDS),
    .VALID_LEDS(VALID_LEDS));

  vga_driver vga_inst(
    .SYS_CLK(SYS_CLK),
    .RST_N(RST_N),
    .DATA_VGA(DATA_VGA),
    .VALID_VGA(VALID_VGA),
    .READY_VGA(READY_VGA),
    .H_SYNC(H_SYNC),
    .V_SYNC(V_SYNC),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B));
    
  seven_segment_driver seg_inst(
    .SYS_CLK(SYS_CLK),
    .RST_N(RST_N),
    .DATA_7SEG(DATA_7SEG),
    .VALID_7SEG(VALID_7SEG),
    .READY_7SEG(READY_7SEG),
    .AN(AN),
    .SEG(SEG));
    
  led_driver led_inst(
    .SYS_CLK(SYS_CLK),
    .RST_N(RST_N),
    .DATA_LEDS(DATA_LEDS),
    .VALID_LEDS(VALID_LEDS),
    .READY_LEDS(READY_LEDS),
    .LEDS(LEDS));
    
  UART_driver UART_driver(
    .SYS_CLK(SYS_CLK),
    .RST_N(RST_N),
    .DATA_UART(DATA_UART),
    .VALID_UART(VALID_UART),
    .READY_UART(READY_UART),
    .TX(TX)
  );

endmodule
