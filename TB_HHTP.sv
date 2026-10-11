`timescale 1ns / 1ps

interface fifo_if;
  logic rst_n;

  //WRITE 100MHz
  logic rx_clk;
  logic [63:0] rx_data;
  logic rx_valid;
  logic fifo_full;

  //READ 25MHz
  logic fifo_read;
  logic sys_clk;
  logic [63:0] fifo_data;
  logic fifo_empty;
endinterface

class transaction;
  rand bit wr;
  rand bit rd;
  rand bit [63:0] data_in;

  bit [63:0] data_out;
  bit empty;
  bit full;

  int cntrl_wr = 70;
  int cntrl_rd = 50;

  constraint c_wr {
    wr dist {1 := cntrl_wr , 0 := 100-cntrl_wr};
  }

  constraint c_rd {
    rd dist {1 := cntrl_rd , 0 := 100-cntrl_rd};
  }

  function transaction copy();
    copy = new();
    copy.wr = this.wr;
    copy.rd = this.rd;
    copy.data_in = this.data_in;
    copy.data_out = this.data_out;
    copy.empty = this.empty;
    copy.full = this.full;
    copy.cntrl_wr = this.cntrl_wr;
    copy.cntrl_rd = this.cntrl_rd;
  endfunction

  function void display(input string tag);
        $display("[%0s] : wr:%0b rd:%0b data_in:%016h full:%0b empty:%0b @ %0t",
             tag, wr, rd, data_in, full, empty, $time);
  endfunction
endclass

class generator;

  transaction tr;
  mailbox #(transaction) mbx;

  event next;
  event done;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();
  endfunction

  task send();
    for (int i = 0 ; i < 200 ; i++) begin
      if (!tr.randomize()) begin
        $error("mix: randomize failed");
      end
      else begin
        mbx.put(tr.copy());
        tr.display("MIX");
        @(next);
      end
    end

    tr.cntrl_wr = 100;
    tr.cntrl_rd = 0;
    for (int i = 0 ; i < 700 ; i++ ) begin
      if (!tr.randomize()) begin
        $error("mix: randomize failed");
      end
      else begin
        mbx.put(tr.copy());
        tr.display("MIX");
        @(next);
      end
    end

    tr.cntrl_wr = 0;
    tr.cntrl_rd = 100;
    for (int i = 0 ; i < 700 ; i++ ) begin
      if (!tr.randomize()) begin
        $error("mix: randomize failed");
      end
      else begin
        mbx.put(tr.copy());
        tr.display("MIX");
        @(next);
      end
    end
    tr.wr = 1'b0;
    tr.rd = 1'b0;
    mbx.put(tr.copy());
    @(next);
    -> done;
  endtask
endclass

class driver;
  virtual fifo_if fif;
  mailbox #(transaction) wr_mbx;
  mailbox #(transaction) rd_mbx;

  transaction tr_wr;
  transaction tr_rd;

  event next_wr;
  event next_rd;

  function new(mailbox #(transaction) wr_mbx,mailbox #(transaction) rd_mbx);
    this.wr_mbx = wr_mbx;
    this.rd_mbx = rd_mbx;
  endfunction



  task reset();
    fif.rst_n <= 1'b0;
    fif.rx_valid <= 1'b0;
    fif.rx_data <= 0;
    fif.fifo_read <= 1'b0;
    repeat(5) @(posedge fif.sys_clk);
    fif.rst_n <= 1'b1;
    repeat(5) @(posedge fif.sys_clk);
    $display("[DRV] : DUT reset done %0t" , $time);
  endtask

  task write_loop();
    forever begin
      wr_mbx.get(tr_wr);
      @(posedge fif.rx_clk);
      fif.rx_valid <= tr_wr.wr;
      fif.rx_data <= tr_wr.data_in;
      -> next_wr;
    end
  endtask

  task read_loop();
    forever begin
      rd_mbx.get(tr_rd);
      @(posedge fif.sys_clk);
      fif.fifo_read <= tr_rd.rd;
      -> next_rd;
    end
  endtask

  task run();
    fork
      write_loop();
      read_loop();
    join
  endtask
endclass

class monitor;
  virtual fifo_if fif;
  mailbox #(transaction) mbx;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task watch_write();
    transaction tr;
    forever begin
      @(posedge fif.rx_clk);
      if (fif.rx_valid) begin
        tr = new();
        tr.wr = 1'b1;
        tr.data_in = fif.rx_data;
        tr.full = fif.fifo_full;
        mbx.put(tr);
      end
    end
  endtask

  task watch_read();
    transaction tr;
    forever begin
      @(posedge fif.sys_clk);
      if (fif.fifo_read) begin
        tr = new();
        tr.rd = 1'b1;
        tr.data_out = fif.fifo_data;
        tr.empty = fif.fifo_empty;
        $display("[MON] : data_out = %016h empty = %0b" , fif.fifo_data , tr.empty);
        mbx.put(tr);
      end
    end
  endtask

  task run();
    fork
      watch_write();
      watch_read();
    join
  endtask

endclass

class scoreboard;
  mailbox #(transaction) mbx;
  transaction tr;

  bit [63:0] model_q[$];
  localparam int DEPTH = 512;
  localparam int SLACK = 16;

  int writes_ok, writes_dropped;
  int reads_ok , reads_blocked;
  int max_level;
  int err;

  function new(mailbox#(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    bit [63:0] expected;
    forever begin
      mbx.get(tr);

      //Write
      if (tr.wr) begin
        if (!tr.full) begin
          model_q.push_back(tr.data_in);
          writes_ok++;
          if (model_q.size() > max_level) begin
            max_level = model_q.size();
          end
          if (model_q.size() > DEPTH) begin
            $error("[SCO] : OVERFLOW - FIFO accepted write #%0d while holding %0d words",writes_ok, DEPTH);
            err++;
          end
        end
        else begin
          writes_dropped++;
          if (model_q.size() < DEPTH - SLACK) begin
            $error("[SCO] : FALSE FULL - FULL=1 but FIFO holds only %0d words @ %0t",model_q.size(), $time);
            err++;
          end
        end
      end

      //Read
      if (tr.rd) begin
        if (!tr.empty) begin
          if (model_q.size() == 0) begin
            $error("[SCO] : UNDERFLOW - EMPTY=0 but nothing was written @ %0t", $time);
            err++;
          end
          else begin
            expected = model_q.pop_front();
            reads_ok++;
            if(expected !== tr.data_out) begin
              $error("[SCO] : DATA MISMATCH read #%0d exp:%016h got:%016h @ %0t",reads_ok, expected, tr.data_out, $time);
              err++;
            end
          end
        end
        else begin
          reads_blocked++;
          if (model_q.size() > SLACK) begin
            $error("[SCO] : FALSE EMPTY - EMPTY=1 but FIFO holds %0d words @ %0t",model_q.size(), $time);
            err++;
          end
        end
      end
    end
  endtask

  function void report();
    $display("--------------------------------------------------");
    $display("[SCO] : writes accepted      : %0d", writes_ok);
    $display("[SCO] : writes dropped (FULL): %0d", writes_dropped);
    $display("[SCO] : reads accepted       : %0d", reads_ok);
    $display("[SCO] : reads blocked (EMPTY): %0d", reads_blocked);
    $display("[SCO] : max FIFO level seen  : %0d / %0d", max_level, DEPTH);
    $display("[SCO] : words left in model  : %0d", model_q.size());

    if (writes_dropped == 0) begin
      $error("[SCO] : FULL was never reached - test is incomplete");
      err++;
    end

    if (reads_blocked == 0) begin
      $error("[SCO] : EMPTY was never reached - test is incomplete");
      err++;
    end

    if (model_q.size() != 0) begin
      $error("[SCO] : %0d words were written but never read back", model_q.size());
      err++;
    end

    if (err == 0) begin
      $display("[SCO] : *** TEST PASSED ***");
    end
    else begin
      $display("[SCO] :  *** TEST FAILED *** ");
      $display("Number of Errors = %0d " , err);
    end

    $display("--------------------------------------------------");
  endfunction
endclass

class environment;

  generator gen_wr;
  generator gen_rd;
  driver drv;
  monitor mon;
  scoreboard sco;

  mailbox #(transaction) gdWmbx;
  mailbox #(transaction) gdRmbx;
  mailbox #(transaction) msmbx;

  event nextgdW;
  event nextgdR;

  virtual fifo_if fif;

  function new(virtual fifo_if fif);

    gdWmbx = new();
    gdRmbx = new();
    msmbx = new();

    gen_wr = new(gdWmbx);
    gen_rd = new(gdRmbx);
    drv = new(gdWmbx,gdRmbx);
    mon = new(msmbx);
    sco = new(msmbx);

    this.fif = fif;
    drv.fif = this.fif;
    mon.fif = this.fif;

    gen_wr.next = nextgdW;
    gen_rd.next = nextgdR;
    drv.next_wr = nextgdW;
    drv.next_rd = nextgdR;
  endfunction

  task pre_test();
    drv.reset();
  endtask

  task test();
    fork
      gen_wr.send();
      gen_rd.send();
      drv.run();
      mon.run();
      sco.run();
    join_any
  endtask

  task post_test();
    wait (gen_rd.done.triggered);
    repeat (10) @(posedge fif.sys_clk);
    sco.report();
    $finish();
  endtask

  task run();
    pre_test();
    test();
    post_test();
  endtask

endclass

module TB_HHTP();
  fifo_if fif();

  async_fifo dut(
    .RST_N(fif.rst_n),
    .RX_CLK(fif.rx_clk),
    .RX_DATA(fif.rx_data),
    .RX_VALID(fif.rx_valid),
    .FIFO_FULL(fif.fifo_full),
    .FIFO_READ(fif.fifo_read),
    .SYS_CLK(fif.sys_clk),
    .FIFO_DATA(fif.fifo_data),
    .FIFO_EMPTY(fif.fifo_empty)
  );

  initial begin
    fif.rx_clk = 1'b0;
    #3.3;
    fif.sys_clk = 1'b1;
  end

  always #5 fif.rx_clk =~ fif.rx_clk;
  always #18.5 fif.sys_clk =~ fif.sys_clk;

  environment env;

  initial begin
    env = new(fif);
    env.run();
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
