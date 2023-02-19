module top(
    input CLK,//时钟信号
    input RST,//复位信号
    input BUTTON,//按钮信号

    output  MP3_RSET,//MP3复位信号
    output  MP3_CS,//MP3，spi通信的命令传输有效信号，低电平有效
    output MP3_DCS,//MP3，spi通信的数据传输有效信号，低电平有效
    output MP3_MOSI,//MP3，spi通信的master输出端
    input MP3_MISO,//MP3，spi通信的master输入端
    output MP3_SCLK,//MP3，spi通信的时钟
    input MP3_DREQ,//数据发送有效信号

    output [3:0]VGA_R,//vga的r颜色分量，下同理
    output [3:0]VGA_G,
    output [3:0]VGA_B,
    output VGA_HS,//行扫描有效信号
    output VGA_VS,//场扫描有效信号


    input  MISO,//加速度传感器的spi通信的master输入端，以下同MP3
    output  MOSI, 
    output n_CS,
    output SCLK,



    output DISPLAY_DP,//数码管点
    output [7:0] DISPLAY_AN,//数码管位选
    output [6:0] DISPLAY_C,//七段数码管


    input [2:0] VOL_SHIFT,//音量控制对应的拨码开关
    input [1:0] MUSIC_SHIFT,//音乐切换对应的拨码开关
    input MODE,//游戏模式选择对应的拨码开关

    output[15:0] LED//led灯
    );


    wire FINISH;//一首音乐是否播放完毕
    wire [3:0] choice;//音乐选择
    wire [11:0] HC,VC;//行计数和场计数
    wire EN;//vga扫描是否在有效范围内
    wire[31:0] MUSIC_DATA;//根据向MP3传送数据，来产生伪随机数
    wire [7:0] SCORE;//积分
    wire roundDD;//加速度传感器是否已经接收到了一轮数据
    wire [11:0] x_reg_temp, y_reg_temp, z_reg_temp;//加速度传感器下，x,y,z方向的临时数据
    wire reset1;//fifo模块的延时，加速度传感器的复位信号
    wire [11:0]y_reg;//只需要y方向上的数据
    wire [15:0] ANG;//加速度衍生的角度相关值

    assign choice =( MUSIC_SHIFT==2'b10 ? 4'h2 :(MUSIC_SHIFT==2'b01 ? 4'h3 : 4'h1));
    
    assign LED[15:0]={VOL_SHIFT[2:0],1'b0,y_reg[11:0]};
    


    MP3 mp3(CLK,RST,MP3_RSET,MP3_CS,MP3_DCS,MP3_MOSI,MP3_MISO,MP3_SCLK,MP3_DREQ,VOL_SHIFT,MUSIC_SHIFT,FINISH,MUSIC_DATA);
   // Gyro gyro( CLK, RST,GYRO_SPC,GYRO_SDI,GYRO_SDO,GYRO_CS,ANG);
    VGA vga(CLK,RST,VGA_HS,VGA_VS,HC,VC,EN);//模拟vga扫描信号
    //游戏控制总体模块
    Game game(CLK,RST,EN,FINISH,y_reg,HC,VC,BUTTON,SCORE,{VGA_R[3:0],VGA_G[3:0],VGA_B[3:0]},MUSIC_DATA,choice,MODE);
    //加速度传感器模拟队列
    FIFO fifo(CLK, roundDD, RST,x_reg_temp, y_reg_temp, z_reg_temp,x_reg, y_reg, z_reg,reset1);
    //加速度传感器
    Control control( CLK,reset1, MISO,MOSI, n_CS, roundDD,x_reg_temp, y_reg_temp, z_reg_temp,SCLK);
    //数码管显示
    wire [15:0] time_cnt;
    //时间转换和七段数码管
    Time_transfer time_transfer(CLK,FINISH | (~RST),time_cnt);
    Display7 display7(CLK,{choice[3:0],4'b1111,SCORE[7:0],time_cnt[15:0]},DISPLAY_C,DISPLAY_AN,DISPLAY_DP);


endmodule
