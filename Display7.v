module Display7
(
    CLK,
    DI,
    DO,
    AN,
    DP
);
    input CLK;
    input [31:0] DI;//4*8
    output reg [6:0] DO;
    output reg [7:0] AN=8'b01111111;//控制第一个阳极为低电平
    output reg DP;

    reg [5:0] p=0;//最大值31
    
    wire clk_t;
   Divider #(200000)divider_display(CLK,clk_t);//分频到2ms的周期
    always @(posedge clk_t) begin
        AN<={AN[6:0],AN[7]};//先驱动阴极，再拉低阳极信号来显示
        p<=p+4;//向前一位数字
        if(AN[1]==0) begin
            DP<=0;
        end
        else begin
            DP<=1;
        end
        case({DI[p+3],DI[p+2],DI[p+1],DI[p]})
            4'b0000: begin
                DO<=7'b1000000;
            end
            4'b0001: begin
                DO<=7'b1111001;
            end
            4'b0010: begin
                DO<=7'b0100100;
            end
            4'b0011: begin
                DO<=7'b0110000;
            end
            4'b0100: begin
                DO<=7'b0011001;
            end
            4'b0101: begin
                DO<=7'b0010010;
            end
            4'b0110: begin
                DO<=7'b0000010;
            end
            4'b0111: begin
                DO<=7'b1111000;
            end
            4'b1000: begin
                DO<=7'b0000000;
            end
            4'b1001: begin
                DO<=7'b0010000;
            end
            default: begin
                DO<=7'b1111111;
            end
        endcase
    end
    
endmodule