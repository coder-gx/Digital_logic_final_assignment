module FIFO(
        input CLK, roundDD, RST,
        input [11:0] x_reg_temp, y_reg_temp, z_reg_temp,
        output reg [11:0] x_reg, y_reg, z_reg,
        output reg reset1
    );
    
    reg en1, en2, en3;
    reg [6:0] rstHold;
    

    Divider #(1000)divider_fifo(CLK,clk);//100kHZ

    always@(posedge clk) begin
            if(!RST) begin
                x_reg <= 0;
                y_reg <= 0;
                z_reg <= 0;
                en1 <= 0;
                en2 <= 0;
                en3 <= 0;
                reset1 <= 0;
                rstHold <= 0;
            end
            else begin
                en1 <= roundDD;
                en2 <= en1;
                en3 <= en2;
                
                //延迟一段时间来使三轴工作
                if(rstHold == 63) 
                    reset1 <= 1;
                else if(!reset1)
                     rstHold <= rstHold + 1;
                else reset1 <= reset1;
                
                if(en3) begin //三轮结束，数据更新，避免数据的频繁访问
                   x_reg <=  x_reg_temp;
                   y_reg <=  y_reg_temp;
                   z_reg <=  z_reg_temp;
                end
            end
        end
endmodule