module async_fifo(
    input RST_N,

    input RX_CLK,
    input [63:0] RX_DATA,
    input RX_VALID,
    output FIFO_FULL,
    
    input FIFO_READ,
    input SYS_CLK,
    output [63:0] FIFO_DATA,
    output FIFO_EMPTY
);
  
    reg [9:0] wptr_bin;
    reg [9:0] rptr_bin;
    
    (* ASYNC_REG = "TRUE" *) reg [9:0] rptr_gray_sync1;
    (* ASYNC_REG = "TRUE" *) reg [9:0] rptr_gray_sync2;
    (* ASYNC_REG = "TRUE" *) reg [9:0] wptr_gray_sync1;
    (* ASYNC_REG = "TRUE" *) reg [9:0] wptr_gray_sync2;

    (* ASYNC_REG = "TRUE" *) reg [1:0] rx_rst_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] sys_rst_sync;

    wire [9:0] wptr_gray;
    wire [9:0] rptr_gray;
  
    wire [8:0] next_rptr_bin = (FIFO_READ && !FIFO_EMPTY) ? (rptr_bin[8:0] + 1'b1) : rptr_bin[8:0];
    
    fifo_bram FIFO_BRAM1(
        .clka  (RX_CLK),
        .wea   ({RX_VALID && !FIFO_FULL}),
        .addra (wptr_bin[8:0]),
        .dina  (RX_DATA),
        .douta (),                  
        
        .clkb  (SYS_CLK),
        .enb   (1'b1),
        .web   ({1'b0}),
        .addrb (next_rptr_bin),
        .dinb  (64'b0),
        .doutb (FIFO_DATA)
    );

    bin_to_gray write_ptr_converter(
        .bin_in  (wptr_bin),
        .gray_out(wptr_gray)
    );

    bin_to_gray read_ptr_converter(
        .bin_in  (rptr_bin),
        .gray_out(rptr_gray)
    );
  
    always @(posedge RX_CLK or negedge RST_N) begin
        if(!RST_N) rx_rst_sync <= 2'b00;
        else       rx_rst_sync <= {rx_rst_sync[0], 1'b1};
    end
    wire rx_rst_n = rx_rst_sync[1];
  
    always @(posedge SYS_CLK or negedge RST_N) begin
        if(!RST_N) sys_rst_sync <= 2'b00;
        else       sys_rst_sync <= {sys_rst_sync[0], 1'b1};
    end
    wire sys_rst_n = sys_rst_sync[1];
  
    assign FIFO_FULL = ((wptr_gray[9:8] == ~rptr_gray_sync2[9:8]) && (wptr_gray[7:0] == rptr_gray_sync2[7:0])); 
    
    always @(posedge RX_CLK or negedge rx_rst_n) begin
        if (!rx_rst_n) begin
            wptr_bin <= 10'b0;
        end
        else begin
            if (RX_VALID == 1 && FIFO_FULL == 0) begin
                wptr_bin <= wptr_bin + 1;
            end 
        end
    end

    assign FIFO_EMPTY = (rptr_gray == wptr_gray_sync2);
    
    always @(posedge SYS_CLK or negedge sys_rst_n) begin
        if(!sys_rst_n) begin
            rptr_bin <= 10'b0;
        end
        else begin
            if(FIFO_READ == 1 && FIFO_EMPTY == 0) begin
                rptr_bin <= rptr_bin + 1;
            end
        end
    end 

    always @(posedge RX_CLK or negedge rx_rst_n) begin
        if(!rx_rst_n) begin
            rptr_gray_sync1 <= 10'b0;
            rptr_gray_sync2 <= 10'b0;
        end
        else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    always @(posedge SYS_CLK or negedge sys_rst_n) begin
        if(!sys_rst_n) begin
            wptr_gray_sync1 <= 10'b0;
            wptr_gray_sync2 <= 10'b0;
        end
        else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end
        
endmodule