module hex_font_rom (
  input [3:0] char_idx, 
  input [3:0] row_idx,  
  input [2:0] col_idx, 
  output pixel_on       
);

  reg [127:0] char_bitmap;


  always @(*) begin
    case (char_idx)
      4'h0: char_bitmap = 128'h0000_003C_6666_6666_6666_6666_3C00_0000;
      4'h1: char_bitmap = 128'h0000_0018_3818_1818_1818_1818_7E00_0000;
      4'h2: char_bitmap = 128'h0000_003C_6606_060C_1830_6066_7E00_0000;
      4'h3: char_bitmap = 128'h0000_003C_6606_061C_0606_6666_3C00_0000;
      4'h4: char_bitmap = 128'h0000_000C_1C3C_6C6C_7E0C_0C0C_1E00_0000;
      4'h5: char_bitmap = 128'h0000_007E_6060_7C06_0606_6666_3C00_0000;
      4'h6: char_bitmap = 128'h0000_003C_6660_607C_6666_6666_3C00_0000;
      4'h7: char_bitmap = 128'h0000_007E_6606_060C_0C18_1818_1800_0000;
      4'h8: char_bitmap = 128'h0000_003C_6666_663C_6666_6666_3C00_0000;
      4'h9: char_bitmap = 128'h0000_003C_6666_6666_3E06_0666_3C00_0000;
      4'hA: char_bitmap = 128'h0000_0018_3C66_6666_7E66_6666_6600_0000;
      4'hB: char_bitmap = 128'h0000_007C_6666_667C_6666_6666_7C00_0000;
      4'hC: char_bitmap = 128'h0000_003C_6666_6060_6060_6666_3C00_0000;
      4'hD: char_bitmap = 128'h0000_0078_6C66_6666_6666_666C_7800_0000;
      4'hE: char_bitmap = 128'h0000_007E_6660_607C_6060_6066_7E00_0000;
      4'hF: char_bitmap = 128'h0000_007E_6660_607C_6060_6060_6000_0000;
      default: char_bitmap = 128'h0;
    endcase
  end


  wire [6:0] bit_idx = { ~row_idx, ~col_idx };
  
  assign pixel_on = char_bitmap[bit_idx];

endmodule