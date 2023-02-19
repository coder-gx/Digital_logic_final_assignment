module Game(
    input   CLK,        
    input   RST,
    input  EN,//有效信号
    input FINISH,
    input [11:0] ANG,//角度
    input  [11:0] HC,
    input [11:0] VC,
    input BUTTON,
    output [7:0] SCORE,      //得分
    output reg [11:0] RGB,
    input[31:0] MUSIC_DATA,
    input[3:0] CHOICE,
    input MODE
    );

   //画面坐标数据和颜色参数
    parameter center_x=512,
              center_y=384;
    parameter cycle_r=450;
    parameter angle1=12'b0001_1000_0000,
              angle2=12'b0010_1000_0000;
    parameter red=12'hf_0_0,
              orange=12'hf_a_0,
              cyan=12'h0_f_f,
              green=12'h0_f_0,
              yellow=12'hf_f_0,
              blue=12'h0_0_f,
              purple=12'ha_2_f,
              black=12'h0_0_0,
              white=12'hf_f_f,
              cray=12'hb_b_b;
wire clk;
wire locked;
clk_wiz_0 clk_65hz(
        .reset(~RST),
        .locked(locked),
        .clk_in1(CLK),
        .clk_out1(clk)
    );

    reg  [18:0]  addra   = 0;       //背景图片存储ROM地址
    wire [11:0]  douta;             //ROM输出
    integer hc;
    integer vc;

    background image(.clka(clk),.addra(addra),.douta(douta));


    reg[9:0] px_ball,py_ball;//小球位置
    reg[9:0] r_ball;//小球半径
    reg[11:0] c_ball;//小球颜色
    reg[2:0] final_path;

    //画图和画圆
   always@(posedge clk or negedge RST or posedge FINISH)
    if(~RST || FINISH ) begin
        RGB<=black;
    end
    else begin
        if(EN) begin
             hc<=HC;
             vc<=VC;
            if((hc-px_ball)*(hc-px_ball)+(vc-py_ball)*(vc-py_ball)<r_ball*r_ball
               || (hc+px_ball-2*center_x)*(hc+px_ball-2*center_x)+(vc+py_ball-2*center_y)*(vc+py_ball-2*center_y)<r_ball*r_ball)begin  //一对小球
                RGB<=c_ball;
            end
            else if((hc-center_x)*(hc-center_x)+(vc-center_y)*(vc-center_y)<=cycle_r*cycle_r+3600 &&
                       (hc-center_x)*(hc-center_x)+(vc-center_y)*(vc-center_y)>=cycle_r*cycle_r-3600) begin//识别区
                         if(MODE==1'b0)begin
                            if(ANG[11]==1 && ~ANG>angle2) begin
                                 if (vc>=center_y+325 && hc>center_x ||vc<=center_y-325 && hc<center_x )
                                    RGB<=red;
                                 else
                                   RGB<=white;
                                final_path<=1;
                            end
                            else if(ANG[11]==1 && ~ANG>angle1 && ~ANG<=angle2)begin
                                if( (vc<=center_y+325 && vc>=center_y+125 && hc>center_x || vc>=center_y-325 && vc<=center_y-125 && hc<center_x ))
                                    RGB<=red;
                                else
                                    RGB<=white;
                                final_path<=2;
                            end
                            else if(ANG[11]==0 && ANG>angle2) begin
                                 if (vc>=center_y+325 && hc<center_x ||vc<=center_y-325 && hc>center_x )
                                    RGB<=red;
                                 else
                                   RGB<=white;
                                final_path<=5;
                            end
                            else if(ANG[11]==0 && ANG>angle1 && ANG<=angle2)begin
                                if( (vc<=center_y+325 && vc>=center_y+125 && hc<center_x || vc>=center_y-325 && vc<=center_y-125 && hc>center_x ))
                                    RGB<=red;
                                else
                                    RGB<=white;
                                final_path<=4;
                            end
                            else begin
                                if(vc>=center_y-100 && vc<=center_y+100)
                                    RGB<=red;
                                else  
                                   RGB<=white;
                                final_path<=3;
                            end
                         end
                         else begin     
                         if(vc>=center_y-100 && vc<=center_y+100)
                             RGB<=red;
                         else     
                             RGB<=white;
                         end
                       end
            else if(hc<832 && hc>=192 && vc>=144 && vc<624) begin  //背景
                    addra<=(vc-144)*640+hc-192;
                    RGB<={douta[11:8],douta[7:4],douta[3:0]};
                end
            else begin
                RGB<=black;
            end
        end
        else begin
            RGB<=black;
        end
    end

    wire clk_ball;
    Divider #(100)divider_ball(CLK,clk_ball); //1MHz


 parameter   beat0=1000_000,   //由于是120bpm，1秒两拍
              beat1=1200_000,   //100bpm
              beat2=750_000;   //160bpm
//状态
 parameter  SET=0,
            PATH1=1,
            PATH2=2,
            PATH3=3,
            PATH4=4,
            PATH5=5,
            GET_SCORE=6,
            OVER=7;
parameter angle3=12'b0010_0000_0000,
          angle4=12'b0011_1000_0000; 
  
  reg[31:0] rand;
  integer cnt=0;
  integer beat;
  reg[3:0]change=0;

  reg[1:0] path;
  reg[2:0]  state;
  integer sco; 

  //使小球以及转动
  always @(posedge clk_ball or negedge RST or posedge FINISH) begin
    if(~RST || FINISH)begin
        cnt<=0;
        state<=SET;
        sco<=0;
    end
    else begin
    case(state)
        SET:begin
            change<=0;
            cnt<=0;
        case(CHOICE)
        2'b01:
           beat<=beat0; 
        2'b10:
           beat<=beat1;
        2'b11:
           beat<=beat2;
        default:
           beat<=beat0;
        endcase

        rand<=MUSIC_DATA%60;//由音乐数据产生随机轨道和颜色
        if(rand<10)begin                 //颜色,轨道
            c_ball<=red;
            state<=PATH1;
        end
        else if(rand>10&& rand<20) begin
            c_ball<=orange;
             state<=PATH2;
        end
        else if(rand>=20&&rand <30)begin
            c_ball<=yellow;
             state<=PATH3;
        end
        else if(rand>=30&&rand <40)begin
            c_ball<=green;
             state<=PATH3;
        end
        else if(rand>=40&&rand <50)begin
            c_ball<=blue;
             state<=PATH4;
        end
        else begin
            c_ball<=purple;
             state<=PATH5;
        end
        end
        PATH1: begin
       if((change==0 && cnt>=beat/6) || (change==1 && cnt>=2*beat/6) ||(change==2 && cnt>=3*beat/6)||(change==3 && cnt>=4*beat/6))begin
       if(MODE==1 && ANG[11]==1 && ~ANG>angle3 && ~ANG<=angle4 )begin
            change<=change+1;
            state<=PATH2;
        end
        else if(MODE==1 && ANG[11]==1 && ~ANG>angle4)begin
            change<=change+1;
            state<=PATH3;
        end
       end
        if(cnt<beat/6)begin
            px_ball<=center_x;
            py_ball<=center_y;
            r_ball<=10;
        end
        else if(cnt>=beat/6&& cnt<2*beat/6)begin
            px_ball<=center_x+45;
            py_ball<=center_y+77;
            r_ball<=20;
        end
        else if(cnt>=2*beat/6&& cnt<3*beat/6)begin
            px_ball<=center_x+90;
            py_ball<=center_y+154;
            r_ball<=30;
        end
        else if(cnt>=3*beat/6&& cnt<4*beat/6)begin
            px_ball<=center_x+135;
            py_ball<=center_y+231;
            r_ball<=45;
        end
        else if(cnt>=4*beat/6&& cnt<5*beat/6)begin
            px_ball<=center_x+180;
            py_ball<=center_y+308;
            r_ball<=60;
        end
        else begin
             px_ball<=center_x+225;
            py_ball<=center_y+385;
            r_ball<=75;
            if(MODE==0&&final_path==1)
                state<=GET_SCORE;
           else
               state<=OVER;
        end
        cnt<=cnt+1;
       end
        PATH2: begin
             if((change==0 && cnt>=beat/6) || (change==1 && cnt>=2*beat/6) ||(change==2 && cnt>=3*beat/6)||(change==3 && cnt>=4*beat/6))begin
       if(MODE==1 && ANG[11]==1 && ~ANG>angle3 && ~ANG<=angle4)begin
             change<=change+1;
            state<=PATH3;
        end
         else if(MODE==1 && ANG[11]==0 && ANG>angle3 )begin
            change<=change+1;
            state<=PATH1;
        end
        else if(MODE==1 && ANG[11]==1 && ~ANG>angle4)begin
           change<=change+1;
            state<=PATH4;
        end
             end
        if(cnt<beat/6)begin
            px_ball<=center_x;
            py_ball<=center_y;
            r_ball<=10;
        end
        else if(cnt>=beat/6&& cnt<2*beat/6)begin
            px_ball<=center_x+77;
            py_ball<=center_y+45;
            r_ball<=20;
        end
        else if(cnt>=2*beat/6&& cnt<3*beat/6)begin
            px_ball<=center_x+154;
            py_ball<=center_y+90;
            r_ball<=30;
        end
        else if(cnt>=3*beat/6&& cnt<4*beat/6)begin
            px_ball<=center_x+231;
            py_ball<=center_y+135;
            r_ball<=45;
        end
        else if(cnt>=4*beat/6&& cnt<5*beat/6)begin
            px_ball<=center_x+308;
            py_ball<=center_y+180;
            r_ball<=60;
        end
        else  begin
            px_ball<=center_x+385;
            py_ball<=center_y+225;
            r_ball<=75;
            if(MODE==0&&final_path==2)
                state<=GET_SCORE;
           else
               state<=OVER;
        end
        cnt<=cnt+1;
       end
        PATH3: begin
            
        if(cnt<beat/6)begin
            px_ball<=center_x;
            py_ball<=center_y;
            r_ball<=10;
        end
        else if(cnt>=beat/6&& cnt<2*beat/6)begin
            px_ball<=center_x+90;
            py_ball<=center_y;
            r_ball<=20;
        end
        else if(cnt>=2*beat/6&& cnt<3*beat/6)begin
            px_ball<=center_x+180;
           py_ball<=center_y;
            r_ball<=30;
        end
        else if(cnt>=3*beat/6&& cnt<4*beat/6)begin
            px_ball<=center_x+270;
             py_ball<=center_y;
            r_ball<=45;
        end
        else if(cnt>=4*beat/6&& cnt<5*beat/6)begin
            px_ball<=center_x+360;
            py_ball<=center_y;
            r_ball<=60;
        end
        else  begin
             px_ball<=center_x+450;
           py_ball<=center_y;
            r_ball<=75;
            if((MODE==0&&final_path==3) || MODE==1)
                state<=GET_SCORE;
           else
               state<=OVER;
        end
        cnt<=cnt+1;
       end
       PATH4: begin
         if((change==0 && cnt>=beat/6) || (change==1 && cnt>=2*beat/6) ||(change==2 && cnt>=3*beat/6)||(change==3 && cnt>=4*beat/6))begin
        if(MODE==1 && ANG[11]==1 && ~ANG>angle3)begin
           change<=change+1;
            state<=PATH5;
        end
        else if(MODE==1 && ANG[11]==0 && ANG>angle4 )begin
           change<=change+1;
            state<=PATH2;
        end
         else if(MODE==1 && ANG[11]==0 && ANG>angle3 && ANG<=angle4)begin
            change<=change+1;
            state<=PATH3;
        end
         end
        
        if(cnt<beat/6)begin
            px_ball<=center_x;
            py_ball<=center_y;
            r_ball<=10;
        end
        else if(cnt>=beat/6&& cnt<2*beat/6)begin
            px_ball<=center_x+77;
            py_ball<=center_y-45;
            r_ball<=20;
        end
        else if(cnt>=2*beat/6&& cnt<3*beat/6)begin
            px_ball<=center_x+154;
            py_ball<=center_y-90;
            r_ball<=30;
        end
        else if(cnt>=3*beat/6&& cnt<4*beat/6)begin
            px_ball<=center_x+231;
            py_ball<=center_y-135;
            r_ball<=45;
        end
        else if(cnt>=4*beat/6&& cnt<5*beat/6)begin
            px_ball<=center_x+308;
            py_ball<=center_y-180;
            r_ball<=60;
        end
        else begin
             px_ball<=center_x+385;
            py_ball<=center_y-225;
            r_ball<=75;
             if(MODE==0&&final_path==4)
                state<=GET_SCORE;
           else
               state<=OVER;
        end
        cnt<=cnt+1;
       end
       PATH5: begin
         if((change==0 && cnt>=beat/6) || (change==1 && cnt>=2*beat/6) ||(change==2 && cnt>=3*beat/6)||(change==3 && cnt>=4*beat/6))begin
       if(MODE==1 && ANG[11]==0 && ANG>angle3 && ANG<=angle4)begin
           change<=change+1;
            state<=PATH4;
        end
        else if(MODE==1 && ANG[11]==0 && ANG>angle4)begin
            change<=change+1;
            state<=PATH3;
        end
         end
        if(cnt<beat/6)begin
            px_ball<=center_x;
            py_ball<=center_y;
            r_ball<=10;
        end
        else if(cnt>=beat/6&& cnt<2*beat/6)begin
            px_ball<=center_x+45;
            py_ball<=center_y-77;
            r_ball<=20;
        end
        else if(cnt>=2*beat/6&& cnt<3*beat/6)begin
            px_ball<=center_x+90;
            py_ball<=center_y-154;
            r_ball<=30;
        end
        else if(cnt>=3*beat/6&& cnt<4*beat/6)begin
            px_ball<=center_x+135;
            py_ball<=center_y-231;
            r_ball<=45;
        end
        else if(cnt>=4*beat/6&& cnt<5*beat/6)begin
            px_ball<=center_x+180;
            py_ball<=center_y-308;
            r_ball<=60;
        end
        else begin
             px_ball<=center_x+225;
            py_ball<=center_y-384;
            r_ball<=75;
             if(MODE==0&&final_path==5)
                state<=GET_SCORE;
           else
               state<=OVER;
        end
        cnt<=cnt+1;
       end
       //计分
       GET_SCORE: begin
        if((MODE==0&&BUTTON) || MODE==1) begin
            sco<=sco+1;
            r_ball<=150;
            c_ball<=white;
          end
          state<=OVER;
       end
       OVER:begin//结束缓冲
          if(cnt<beat)
             cnt<=cnt+1;
          else
             state<=SET;
       end  
    endcase    
             
        
    end
  end
//赋分
  assign SCORE[3:0]=sco%10;
  assign SCORE[7:4]=sco/10;
endmodule
