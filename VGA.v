module VGA(
    CLK,
    RST,
    VGA_HS,
    VGA_VS,
    HC,
    VC,
    EN
    );
input CLK;
input RST;
output VGA_HS; 
output VGA_VS; 
output [11:0]HC ;
output[11:0] VC;
output EN;

parameter hsync_end = 12'd135,//0-136-160<--1024-->24 
          hdat_begin = 12'd295,
          hdat_end = 12'd1319,
          hpixel_end = 12'd1343,
          
          vsync_end = 10'd5,//0-6-29<--768-->3
          vdat_begin = 10'd34,
          vdat_end = 10'd802,
          vline_end = 10'd805;

wire vga_clk;
wire locked;
//ip核产生1024X768的65Hz时钟
clk_wiz_0 clk_65hz(
        .reset(~RST),
        .locked(locked),
        .clk_in1(CLK),
        .clk_out1(vga_clk)
    );


reg [12:0] hcount=0; //行扫描计数
reg [12:0] vcount=0; //场扫描计数

//行扫描
always @(posedge vga_clk or negedge locked)begin
if(!locked)
       hcount<=0;
else if (hcount==hpixel_end) 
    hcount <= 0;
else
    hcount <= hcount + 1;
end

assign VGA_HS=(hcount<hsync_end+1) ? 1'b0:1'b1;
//场扫描
always @(posedge vga_clk or negedge locked)//场
begin
if(!locked)
       vcount<=0;
else if(vcount==vline_end)
    vcount<=1'b0;
else if(hcount==hpixel_end)
    vcount<=vcount+1;
else 
     vcount<=vcount;
end

assign VGA_VS=(vcount<vsync_end+1)? 1'b0:1'b1;

assign EN = ((hcount >= hdat_begin) && (hcount < hdat_end))&& ((vcount >= vdat_begin) && (vcount < vdat_end));

assign HC=hcount-hdat_begin;
assign VC=vcount-vdat_begin;

endmodule
