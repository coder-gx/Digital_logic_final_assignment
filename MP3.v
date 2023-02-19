module MP3
(
    CLK,
    RST,

    MP3_RSET,
    MP3_CS,//命令
    MP3_DCS,//数据
    MP3_MOSI,
    MP3_MISO,
    MP3_SCLK,
    MP3_DREQ,

    VOL_SHIFT,
    MUSIC_SHIFT,

    FINISH,

    MUSIC_DATA

);
    input CLK;
    input RST;

    output reg MP3_RSET=1;
    output reg MP3_CS=1;
    output reg MP3_DCS=1;
    output reg MP3_MOSI=0;
    input MP3_MISO;
    output reg MP3_SCLK=0;
    input MP3_DREQ;

    input [2:0] VOL_SHIFT;
    input [1:0] MUSIC_SHIFT;
    output reg FINISH=0;
    output [31:0]MUSIC_DATA;

    wire mp3_clk;
    Divider #(100)divider_mp3(CLK,mp3_clk);//分频到1MHz
    
    //设置命令
    integer cnt=0;
    integer cmd_cnt=0;
    parameter cmd_cnt_max=4;
    reg [31:0] next_cmd;

    reg [127:0] cmd_init={32'h02000804,32'h02020055,32'h02039800,32'h020B7070};
    reg [127:0] cmd={32'h02000804,32'h02020055,32'h02039800,32'h020B7070};
    
    
    //读取音乐
    wire [31:0] data0;
    wire [31:0] data1;
    wire [31:0] data2;
    reg [31:0] data;
    reg [17:0] pos=0;
    blk_mem_gen_0 music_0(.clka(CLK),.dina(0),.wea(0),.addra(pos[17:0]),.douta(data0));
    blk_mem_gen_1 music_1(.clka(CLK),.dina(0),.wea(0),.addra(pos[17:0]),.douta(data1));
    blk_mem_gen_2 music_2(.clka(CLK),.dina(0),.wea(0),.addra(pos[17:0]),.douta(data2));

    //音乐切换
    reg  [1:0] pre_music=0;
    reg  [1:0] now_music=0;
    integer delay=0;//设置延迟，延迟0.5s来保证此阶段命令完成发送
    always @(negedge mp3_clk ) begin
        if(delay==0) begin
           if(pre_music!=now_music)
               delay<=50_0000;
           case(MUSIC_SHIFT)
           2'b00:
            now_music<=0;
           2'b10:
             now_music<=1;
           2'b01:
             now_music<=2;
           default:
             now_music<=0;
           endcase
        end
        else
            delay<=delay-1;
    end
    
    //音量控制
    reg [15:0]pre_vol=16'h7070;
    reg [15:0]now_vol=16'h7070;
    integer vol_delay=0;
    always @(negedge mp3_clk) begin
        if(vol_delay==0) begin
            if(pre_vol!=now_vol)
                 vol_delay<=50_0000;
            now_vol<=16'h3030-(VOL_SHIFT/2)*16'h1010;
        end
        else
            vol_delay<=vol_delay-1;
    end

  //MP3状态
    parameter INIT = 3'd0;
    parameter CMD_WRITE = 3'd1;
    parameter VOL_CHANGE = 3'd2;
    parameter DATA_WRITE = 3'd3;
    parameter RSET_OVER = 3'd4;
    parameter VOL_SET_PRE = 3'd5;
    parameter VOL_SET = 3'd6;
    
    parameter len0=8'd125;
    parameter len1=8'd100;
    parameter len2=13'd90;


    reg[2:0] state=0;
    reg[7:0] len;
    integer len_cnt=0;
   
    
    always @(posedge mp3_clk or negedge RST) begin//接收到复位信号，切换音乐，或者一首音乐放完，则复位
        if( ~RST|| pre_music!=now_music || (MUSIC_SHIFT==2'b10 ? (len>len1):(MUSIC_SHIFT==2'b01 ? (len>len2):(len>len0) ))) begin
            pos<=0;
            pre_music<=now_music;
            cnt<=0;
            MP3_RSET<=0;
            cmd_cnt<=0;
            state<=RSET_OVER;
            cmd<=cmd_init;
            MP3_SCLK<=0;
            MP3_CS<=1;
            MP3_DCS<=1;
            len<=0;
            len_cnt<=0;
            FINISH<=1&RST;
        end
        else begin
            if(len_cnt<1000_000)//计算大致播放时长
                  len_cnt<=len_cnt+1;
            else begin
                len_cnt<=0;
                len<=len+1;
            end
            case(state)
            INIT:begin//由于是SPI MODE0模式，在第一个时钟上升沿之前要准备好数据
                MP3_SCLK<=0;
                if(cmd_cnt>=cmd_cnt_max) begin
                    state<=VOL_CHANGE;
                end
                else if(MP3_DREQ) begin
                    MP3_CS<=0;
                    cnt<=1;
                    state<=CMD_WRITE;
                    MP3_MOSI<=cmd[127];
                    cmd<={cmd[126:0],cmd[127]};
                end
            end
            CMD_WRITE:begin//写入控制寄存器
                if(MP3_DREQ) begin
                    if(MP3_SCLK) begin
                        if(cnt<32)begin
                            cnt<=cnt+1;
                            MP3_MOSI<=cmd[127];
                            cmd<={cmd[126:0],cmd[127]};
                        end
                        else begin
                            MP3_CS<=1;
                            cnt<=0;
                            cmd_cnt<=cmd_cnt+1;
                            state<=INIT;
                        end
                    end
                    MP3_SCLK<=~MP3_SCLK;
                end
            end
            VOL_CHANGE:begin //判断音量是否变化
                if(now_vol[15:0]!=cmd_init[15:0]) begin
                    state<=VOL_SET_PRE;
                    next_cmd<={16'h020B,now_vol[15:0]};
                end
                else if(MP3_DREQ) begin
                    MP3_DCS<=0;
                    MP3_SCLK<=0;
                    state<=DATA_WRITE;
                    case (now_music)
                        3'd0:begin
                            data<={data0[30:0],data0[31]};
                            MP3_MOSI<=data0[31];
                        end
                        3'd1:begin
                            data<={data1[30:0],data1[31]};
                            MP3_MOSI<=data1[31];
                        end
                        3'd2:begin
                            data<={data2[30:0],data2[31]};
                            MP3_MOSI<=data2[31];
                        end
                    endcase
                    cnt<=1;
                end
                cmd_init[15:0]<=now_vol;
            end
            DATA_WRITE:begin //向MP3写入数据
                if(MP3_SCLK)begin
                    if(cnt<32)begin
                        cnt<=cnt+1;
                        MP3_MOSI<=data[31];
                        data<={data[30:0],data[31]};
                    end
                    else begin
                        MP3_DCS<=1;
                        pos<=pos+1;
                        state<=VOL_CHANGE;
                    end
                end
                MP3_SCLK<=~MP3_SCLK;
            end
            RSET_OVER:begin  //复位结束等待一点时间
                if(cnt<1000000) begin
                    cnt<=cnt+1;
                end
                else begin
                    cnt<=0;
                    state<=INIT;
                    MP3_RSET<=1;
                    FINISH<=0;
                end
            end
            VOL_SET_PRE:begin  //SPI MODE0模式在CS拉低后第一个上升沿之前准备好数据
                if(MP3_DREQ) begin
                    MP3_CS<=0;
                    cnt<=1;
                    state<=VOL_SET;
                    MP3_MOSI<=next_cmd[31];
                    next_cmd<={next_cmd[30:0],next_cmd[31]};
                end
            end
            VOL_SET:begin//设置音量
                if(MP3_DREQ) begin
                    if(MP3_SCLK) begin
                        if(cnt<32)begin
                            cnt<=cnt+1;
                            MP3_MOSI<=next_cmd[31];
                            next_cmd<={next_cmd[30:0],next_cmd[31]};
                        end
                        else begin
                            MP3_CS<=1;
                            cnt<=0;
                            state<=VOL_CHANGE;
                        end
                    end
                    MP3_SCLK<=~MP3_SCLK;
                end
            end
            default:begin
                ;
            end
            endcase
        end
    end

    assign MUSIC_DATA=data;

endmodule