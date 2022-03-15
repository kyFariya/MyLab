module EPG_RX (EN, CLK, RST, BUSY, OP_RX);

  input EN, CLK, RST, OP_RX;  
  output reg BUSY;
  
  reg [31:0] mem [0:16383];
  reg [31:0] tmp;
    
  reg [3:0]  iii;   
  reg [15:0] ttt;  
  reg [4:0]  bitPointer;   
  reg [15:0] linepointer;  
  
  reg [15:0] hBIT, lBIT, CSUM;     
  
  reg [2:0] SSTT = 0;
  
  always @ (negedge CLK) begin
    
    if (RST) begin
      BUSY = 0;
      bitPointer = 0;
      linepointer = 0;
    end
    
    else if (EN) begin
            
      if (!BUSY) begin 
        
        case (SSTT)
          
          3:  begin   
            if (!OP_RX) begin 
              SSTT = 0;
              BUSY = 1; 
              tmp = 32'h_0000_0004;
              bitPointer = 4;
              linepointer = 0;
            end       
            else 
              SSTT = 0;
          end
          
          2:  begin
            if (OP_RX) begin 
              SSTT = 3; 
            end 
            else 
            SSTT = 0;
          end
          
          1: begin
            if (!OP_RX) begin 
              SSTT = 2; 
            end  
            else 
            SSTT = 0;
          end
          
          default: begin
            if (!OP_RX) begin 
              SSTT = 1; 
            end  
            else 
              SSTT = 0;
          end
          
        endcase
        
      end
      
      else begin 
        
        tmp [bitPointer] = OP_RX;; // LSB FIRST ;   index numb
        
        
        if (bitPointer<31)                  
          bitPointer = bitPointer + 1;
        else begin
          bitPointer = 0;
          mem[linepointer] = tmp;
          if (linepointer==0)
            {hBIT,lBIT} = mem[0];
          linepointer = linepointer + 1;       
        end
                
        if (linepointer == hBIT)  begin//mem end ...reset
          BUSY = 0;
          bitPointer = 0;
          linepointer = 0;
                      
          ////////////// JUST PRINT START //////////////
          $display("\nMemory DUMP RX"); 
          ttt = 0;
          while (ttt < hBIT) begin         
            $display("%h", mem[ttt]);   
            ttt = ttt + 1;                 
          end
          $display("Memory DUMP RX COMPLETE\n"); 
          ////////////// JUST PRINT END //////////////
      
        end

      end 

    end

  end
  
endmodule
