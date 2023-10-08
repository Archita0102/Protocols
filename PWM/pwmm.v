`timescale 1ns / 1ps
module pwmm(
    input clk,rst,
    output reg dout
    );
    
    parameter period=100;  //depending on user's requirement
    integer count=0;
    integer ton=0;
    reg ncyc=1'b0; //keeps track of next cycle
    
    always@(posedge clk)
    begin
        if(rst==1'b1) begin   ///default values
            count<=1'b0;
            ton<=1'b0;
            ncyc<=1'b0;
        end
        else begin
            if(count<=ton)
            begin
                count<=count+1;
                dout<=1'b1;
                ncyc<=1'b0;
            end
            else if(count<period) begin
                count<=count+1;
                dout<=1'b0;
                ncyc<=1'b0;
            end
            else begin
                ncyc<=1'b1;
                count<=0;
            end
        end
    end
    
    
    always@(posedge clk) begin
        if(rst==1'b0) begin
            if(ncyc==1'b1) begin
                if(ton<=period)
                    ton=ton+5;
                else
                    ton<=0;
            end
        end
    end
endmodule
