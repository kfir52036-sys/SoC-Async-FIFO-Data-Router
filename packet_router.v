module packet_router(
  input [31:0] PARSED_DATA ,
  input PARSED_VALID,
  input [1:0] DEST_ID,
  input READY_7SEG,
  input READY_VGA,
  input READY_UART,
  input READY_LEDS,
  output ROUTER_READY,
  output [31:0] DATA_7SEG,
  output VALID_7SEG,
  output [31:0] DATA_VGA,
  output VALID_VGA,
  output [31:0] DATA_UART,
  output VALID_UART,
  output [31:0] DATA_LEDS,
  output VALID_LEDS
  );
  
  assign DATA_7SEG = PARSED_DATA;
  assign DATA_VGA = PARSED_DATA;
  assign DATA_UART = PARSED_DATA;
  assign DATA_LEDS = PARSED_DATA;
  
  assign VALID_7SEG = PARSED_VALID && (DEST_ID == 2'b00);
  assign VALID_VGA = PARSED_VALID && (DEST_ID == 2'b01);
  assign VALID_UART = PARSED_VALID && (DEST_ID == 2'b10);
  assign VALID_LEDS = PARSED_VALID && (DEST_ID == 2'b11);
  
  assign ROUTER_READY = (DEST_ID == 2'b00) ? READY_7SEG :
                        (DEST_ID == 2'b01) ? READY_VGA :
                        (DEST_ID == 2'b10) ? READY_UART :
                        (DEST_ID == 2'b11) ? READY_LEDS : 
                        1'b0;
                      
endmodule
