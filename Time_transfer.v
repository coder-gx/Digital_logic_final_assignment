module Time_transfer
(
    CLK,
    RST,
    DO
);

    input CLK;//100MHz
    input RST;
    output [15:0]DO;

    Divider #(100)divider_transfer(CLK,clk);//分频到1MHz

    integer t=0,T=0;
    always @(negedge clk) begin
        if(RST)begin
            t<=0;
            T<=0;
        end
        else begin
            if(t<999999) begin
                t<=t+1;
            end
            else begin
                t<=0;
                T<=T+1;
            end
        end
    end
    assign DO[3:0]=T%10;
    assign DO[7:4]=(T/10)%6;
    assign DO[11:8]=(T/60)%10;
    assign DO[15:12]=T/600;

endmodule