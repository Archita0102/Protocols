module tb();
  reg signed [7:0]a,b;
  wire signed [15:0] m1,m2,m3,m4,m5,m6,m7,m8;
  wire signed [15:0]s1,s2,s3,s4,s5,s6;
  wire signed [15:0]s; 
  

  mulsignd ff(a,b,s);
 initial begin
 $monitor ("time = %3d, A = %d, B = %d,S=%d",$time, a,b,s);
 $dumpfile("signed delay mul waveforms.vcd");
 $dumpvars(0,a,b,s);
 a=8'b00000001; b=8'b11111111;	
 //#10 a=8'b01001000;b=8'b10000111;
  end
endmodule`timescale 1ns / 1ps

module uarttra( 
    input clk,
    input start, // to start operation of transmission
    input [7:0] txin, // data to be send to other device
    output reg tx, //pin where we will transmitting data to other device
    input rx, //to receive data at other device
    output [7:0] rxout, //data out
    output rxdone,txdone  //completion 
    
    );
    
    parameter clk_value=100_000;
    parameter baud = 9600;
    
    parameter wait_count = clk_value/baud;
    
    reg bit_done = 0;  //trigger signal . Once we reach the waitcount it will give 1
    integer count =0; // number of clock tips elapsed so far till wait count
    parameter idle =0 , send =1 , check =2;
    reg [1:0] state = idle;
    
    always@(posedge clk)
    begin
        if(state==idle)
            begin
                count<=0;
            end
        else begin
            if (count == wait_count)
            begin
                bit_done <= 1'b1;
                count <= 0;
            end
            else
            begin
                count <= count+1; //count number of clock pulses
                bit_done <= 1'b0;
            end
        end
    end
    
    
    
    /// Transmitter logic
    
    reg [9:0] txdata; // stop bit + 8 bit data + start bit = total 10 bits
    integer bitindex = 0;  // track of data bits sent so far
    reg [9:0] shifttx = 0; // comparing data received in receiver and sent by transmitter
    
    
    always@(posedge clk)
    begin
        case(state)
            idle : begin
                tx <= 1'b1; 
                txdata <= 1'b0;
                bitindex <= 0;
                shifttx <=0;
                
                if (start == 1'b1)
                begin
                    txdata <= {1'b1,txin,1'b0}; // data to be transmitted to the other device
                    state <= send;
                end
                else
                begin
                    state <= idle;
                end
            end
            
            
            send : begin
                tx <= txdata[bitindex];  //output of transmitter
                state <= check;
                shifttx <= {txdata[bitindex],shifttx[9:1]};
            end
            
            check : begin   //to check all bits are tranferred
                if (bitindex <= 9)  //0-9 =10
                    begin
                        if (bit_done == 1'b1)
                            begin
                                state <= send;
                                bitindex <= bitindex + 1;  
                            end
                            
                end
                else
                    begin
                            state <= idle;
                            bitindex <= 0;
                           
                    end
                   
                    
            end
            
            default : state <= idle;
            
            
        endcase
    end
    
    
    assign txdone = (bitindex == 9 && bit_done == 1'b1) ? 1'b1 : 1'b0;
    
    
    /// receiver logic
    
    integer rcount = 0; //no of clock ticks elapsed and once we reach the middle we will sample the data
    integer rindex =0;  // no of bits received so far
    parameter ridle =0,rwait =1 , recv=2 ,rcheck =3;
    reg [1:0] rstate ;
    reg [9:0] rxdata; // stores 10 bit received from transmitter
    
    always@ (posedge clk)
    begin
        case(rstate)
            ridle : begin
                        rxdata <= 0;
                        rindex <=0;
                        rcount <= 0;
                        
                        if (rx == 1'b0)  //when we receive start on tx line
                        begin
                            rstate <= rwait;
                        end
                        else
                        begin
                            rstate <= ridle;
                        end
                    end
                    
              rwait :begin
                    if (rcount < wait_count/2)  //middle of wait count
                    begin
                        rcount <= rcount+1;
                        rstate <= rwait;
                    end
                    
                    else begin
                        rcount <= 0;
                        rstate <= recv;
                        rxdata = {rx,rxdata[9:1]};
                    end
              end
              
              recv : begin
                    if (rindex <= 9)
                    begin
                        if (bit_done == 1'b1)  // wait till end of bit duration
                            begin
                                rindex <= rindex+1;
                                rstate <= rwait;
                            end
                     end
                    else begin
                            rstate <= ridle;
                            rindex <= 0;
                     end
                    
              end
              
              default : rstate <= ridle;
              
              
        endcase
    end
    
    
    assign rxout = rxdata [8:1];
    assign rxdone = (rindex == 9 && bit_done == 1'b1) ? 1'b1 : 1'b0;
    
    
endmodule

 
 
 