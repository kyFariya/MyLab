`timescale 100ps/1ps 

module tb_EPG();
   
  
  reg [31:0] DIN=0;
  reg [2:0]  CTRL=0;  
  reg SEND=0, EN=0, CLK=1, RST=0;
  wire BUSY_TX, BUSY_RX, OFULL, DFULL, OP_TX;
  wire [31:0] INDICATOR;
  
  
  
  reg [2:0] DSZ, OSZ, CNT;
  int C = 0;
    
  always #5 CLK=!CLK;

  EPG_TX DUT0 (
    .DIN(DIN),
    .CTRL(CTRL), 
    .SEND(SEND), 
    .EN(EN),
    .CLK(CLK), 
    .RST(RST), 
    .BUSY(BUSY_TX),
    .OFULL(OFULL), 
    .DFULL(DFULL),
    .OP_TX(OP_TX), 
    .INDICATOR(INDICATOR)
  );
  
  EPG_RX DUT1 (
    .EN(EN), 
    .CLK(CLK), 
    .RST(RST), 
    .BUSY(BUSY_RX), 
    .OP_RX(OP_TX)
  );
  
  initial begin 
    $dumpfile("test.vcd");
    $dumpvars(5, DIN, CTRL, SEND, EN, CLK, RST, BUSY_TX, BUSY_RX, OFULL, DFULL, OP_TX, INDICATOR);
    
    
    
    for (C=0; C <3; C++) begin
      
      wait (!CLK); wait (CLK);
      RST=1;
      wait (!CLK); wait (CLK);
      RST=0; EN = 1;
      
      wait (!CLK); wait (CLK); CTRL= 1; DIN= $random; $display("TOS=%h", DIN & 32'h0000_00FF); // TOS 8
      wait (!CLK); wait (CLK); CTRL= 2; DIN= $random; $display("ID =%h", DIN & 32'h0000_FFFF); // ID 16
      wait (!CLK); wait (CLK); CTRL= 3; DIN= $random; $display("TTL=%h", DIN & 32'h0000_00FF); // TTL 8
      
      wait (!CLK); wait (CLK); CTRL= 4; DIN= $random; $display("SA =%h", DIN); // SA 32
      wait (!CLK); wait (CLK); CTRL= 5; DIN= $random; $display("DA =%h", DIN); // DA 32
      
      {DSZ, OSZ} = $random;
      
      CNT = 0;
      while (CNT<OSZ) begin
    	wait (!CLK); wait (CLK); CTRL= 6; DIN= $random; $display("OPT=%h", DIN); // OP1 32
        CNT = CNT + 1;
      end
      
      CNT = 0;
      while (CNT<DSZ) begin
    	wait (!CLK); wait (CLK); CTRL= 7; DIN= $random; $display("DTA=%h", DIN); // DT1 32
        CNT = CNT + 1;
      end
      
    wait (!CLK); wait (CLK); CTRL= 0;
    
    SEND = 1;  
    wait (!CLK); wait (CLK);
    SEND = 0;  
   
    wait (!BUSY_TX);
    wait (!BUSY_RX);
    
    #50;
      
    end
    
        
    $finish;
  end
  
endmodule
