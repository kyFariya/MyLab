module EPG_TX (DIN, CTRL, SEND, EN, CLK, RST, BUSY, OFULL, DFULL, OP_TX, INDICATOR);
  
  input [31:0] DIN; //inputs of signals data in 32 bit
  input [2:0]  CTRL;  //type of signal data
  input SEND, EN, CLK, RST;  //each 1 bit; 
  //send= begin transmission 
  //en= enables the devices
  //clk= system clk
  //RST= reset when high
  output reg BUSY, OFULL, DFULL, OP_TX;  
  //busy= device busy or sending data or transmission going on
  // ofull-option full (when   total 40 byte option used )
  // dfull= data full  (when total 64kbyte of transmission data full )
  output reg [31:0] INDICATOR;
  //INDICATOR= indicate the status of ootput

  reg [31:0] mem [0:16383];
  // 32 bit and 16384 unit transmission memory [as the data represents memory (size 0~65,536)] 
  // reg [31:0] temp;  
  
  reg [3:0] optc;  //counts the numb of 32 bit option  in 4 bit reg
  reg [13:0] memc;   //memory count
  
  
  reg [3:0]  iii;   //iii= random for print ...
  reg [15:0] ttt;   //ttt= random for mem dumb and transmission
  reg [4:0]  bitPointer;   //bitPointer= serial transmit bit
  reg [15:0] linepointer;  //linepointer= which line transmit
  
  reg [15:0] hBIT, lBIT, CSUM;     //hBIT=higher bits  , lBIT= lower bits , CSUM= checksum; each 16 bit
  
  
  always@(posedge CLK) begin
        
    if (RST) begin              //in this loop  optc, busy, bitpointer, linepointer are.... to reset all 0
      optc = 0;
      memc = 0;
      BUSY = 0;
      bitPointer = 0;
      linepointer = 0;
      OP_TX = 1;
      OFULL = 0;
      DFULL = 0;
      //all will be reset
    end
    
    else if (EN)  begin      //if the rst is ia 0, it enables...if enable then device work
      
      if (!BUSY)             //if not busy
        case (CTRL)         //in this case there are 7 state; each represent header and DIN is data

  //         0: begin // no operation
  //         end

          1: begin  //tos          
  //           mem [0] = mem[0] & 32'h_ffff_00f0; //clearing 8 to 15 index  ; ffff_00f0 here last one is lsb and 1st part msb each 4 bit(f_0 is 8 bit)
  //           temp= DIN & 32'h0000_00ff;  //clearing 8to 31th index          
  //           temp= {temp, 8'h04};  //left shift temp reg with vertion name
  //           mem[0] = mem [0] | temp;  //tos in the correct place of the mem           

            mem [0] = (mem[0] & 32'h_ffff_00f0) | {DIN & 32'h0000_00ff, 8'h04};
            //1st empty the TOS and Vertion-> DIN upper 24 bit cleared 
            // 8 bit left shift with vertion number
            //or the total
      optc = 0;
      memc = 0;
      BUSY = 0;
      bitPointer = 0;
      linepointer = 0;
      OP_TX = 1;
      OFULL = 0;
      DFULL = 0;
          end

          2: begin // ID
            mem[1] = DIN & 32'h0000_ffff;  //clear upper 16 bit of temp reg
            //mem[1]= temp;//id stored in lsb of 2nd mem index
          end

          3: begin // TTL
            mem [2] = (mem[2] & 32'hffff_0000) | (DIN & 32'h0000_00ff) | {32'h0000_7c00};
            //32'hffff_0000-> empty lower 16 bit of mem
            //Din & 32'h0000_00ff-> empty upper 24 bit
            //store 7c in 8 to 15 index  and total OR 
          end

          4: begin //Source add
            mem [3] = DIN;  //mem[3] and data in are both 32 bit
          end

          5: begin //dest addr
            mem [4] = DIN;  //mem[4] and data in are both 32 bit
          end

          6: begin //option
            if (optc <10)  begin   //max 40 byte= 320 bits = 32*10 bits
              mem[5+optc] = DIN;   // fix hed 5 = opt
              optc= optc+1;        // opt increment to increase ihl
              iii = optc + 5;  // IHL = 5line + option
              ttt = memc + optc + 5; // TL = 5line + option+dat
              mem [0] = (mem[0] & 32'h0000_ff00) | {ttt,8'h0,iii,4'h4};  //mem [0] 
              if (optc>9) OFULL = 1; else OFULL = 0;                
            end
          end

          7: begin //data
            if (memc < 16369)  begin   //max 40 byte= 320 bits = 32*10 bits
              mem[15+memc] = DIN;
              memc= memc+1;            //
              iii = optc + 5;  // IHL = 5line + option
              ttt = memc + optc + 5; // TL = 5line + option+dat
              mem [0] = (mem[0] & 32'h0000_ff00) | {ttt,8'h0,iii,4'h4};//memc= data count; 
              if (memc>16368) DFULL = 1; else DFULL = 0;
            end           
          end

          default: begin // NOP
            if (SEND) begin
              
              BUSY = 1;
              {hBIT, lBIT} = mem[0]; //32 bit dev into 2
              CSUM = hBIT + lBIT;  //csum inoitial 0
              {hBIT, lBIT} = mem[1];    //
              CSUM = CSUM + hBIT + lBIT;  
              {hBIT, lBIT} = mem[2]; 
              CSUM = CSUM + lBIT;
             
              
              mem[2] = (mem[2] & 32'h_0000_ffff) | {CSUM,16'h00};
              
              ////////////// JUST PRINT START //////////////
              $display("\nMemory DUMP TX"); 
              $display("%h", mem[0]); 
              $display("%h", mem[1]); 
              $display("%h", mem[2]); 
              $display("%h", mem[3]); 
              $display("%h", mem[4]); 

              if (optc>0) begin                 // iii = option count    till increment 1
                iii = 0;                        
                while (iii < optc) begin        
                  $display("%h", mem[5+iii]);   
                  iii = iii + 1;                
                end
              end

              if (memc>0) begin                  
                ttt = 0;                         
                while (ttt < memc) begin         
                  $display("%h", mem[15+ttt]);   
                  ttt = ttt + 1;                 
                end
              end

              $display("Memory DUMP TX COMPLETE\n"); 
              ////////////// JUST PRINT END //////////////
              
            end
          end    
        endcase
      
      
      else begin
        
        
        INDICATOR = mem [linepointer];         //  busy
        
        // OP_TX = INDICATOR [31 - bitPointer]; // MSB FIRST
        OP_TX = INDICATOR [bitPointer]; // LSB FIRST ;   index numb
        
        
        if (bitPointer<31)                   
          bitPointer = bitPointer + 1;
        else begin
          bitPointer = 0;
          linepointer = linepointer + 1;       
        end
        
        if (linepointer == (5+optc))          // 5th line  
          linepointer = 15;
        
        if (linepointer == (15+memc)) begin  //mem end ...reset
          BUSY = 0;
          bitPointer = 0;
          linepointer = 0;
        end 
      end
    end
  end
  
endmodule
