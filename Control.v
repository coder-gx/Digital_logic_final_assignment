module Control(
    input  CLK, reset, MISO,
    output reg MOSI, n_CS, roundDD,
    output reg [11:0] x_reg_temp, y_reg_temp, z_reg_temp,
    output clk_SPI
    );

    Divider #(20) divider_con(CLK,clk_SPI);
    
    parameter
              //寄存器地址
              CON_REG = 8'h2D,
              X_L_REG = 8'h0E,
              X_H_REG = 8'h0F,
              Y_L_REG = 8'h10,
              Y_H_REG = 8'h11,
              Z_L_REG = 8'h12,
              Z_H_REG = 8'h13,

              //寄存器的读写指令
              REGISTER_READ = 8'h0B,
              REGISTER_WRITE = 8'h0A,
              
              //状态定义
              START = 3'd0,
              INSTRUCTION = 3'd1,
              ADDRESS = 3'd2,
              DATA_READ = 3'd3,
              DATA_WRITE = 3'd4,
              DATA_PROCESS  = 3'd5,
              OVER = 3'd6,

              //读和写的数据位
              WRITE = 1'b1,
              READ = 1'b0;
              
        
    reg rw, roundDone;
    reg [7:0] address; //寄存器地址
    reg [7:0] data; //读取的数据信息
   reg [2:0] counter, state; //字节位计数和状态
    reg [7:0] instruction;
    
    
    always@(posedge clk_SPI) begin
        if(!reset) begin
            rw <= WRITE;
            x_reg_temp <= 0;
            y_reg_temp <= 0;
            z_reg_temp <= 0;
            n_CS <= 1;
            instruction <= REGISTER_WRITE;
            address <= CON_REG;
            roundDone <= 1;
            roundDD <= 1;
            state <= START;
            counter <= 7; //从7数到0

            data<= 8'b0000_0010;//mesurement模式
        end
        else begin
            roundDD <= roundDone;
        
            if(state == INSTRUCTION || state == ADDRESS || state == DATA_READ || state == DATA_WRITE) begin
           		if(counter == 0) begin //couter必须为0，即数据读完才能切换状态         
            		 counter <= 7;
            	    if(state == INSTRUCTION)
                       state <= ADDRESS;
            		else if(state == ADDRESS && rw) 
                         state <= DATA_WRITE; //进入写出数据的状态
            		else if(state == DATA_WRITE || state == DATA_READ) begin
            		    state <= OVER; //结束，将CS拉高
            		end
            		else begin//读数据
            		    roundDone <= 0; //新数据来了，一个数据接受轮结束
            			state <= DATA_READ; //转换到读数据阶段
            		end
            	end
            	else counter <= counter - 1;
            end  

        	 if(state == START) begin
        	   n_CS <= 0;
        	   state <= INSTRUCTION;
        	end
        	else if(state == DATA_PROCESS) begin//数据处理并进行地址转换
        	   state <= START;
        	   data <= 0;
        	   case(address) //地址字节转换，读取下一个字节
                   X_L_REG : begin
                       x_reg_temp[7:0] <= data;
                       address <=  X_H_REG;
                   end
                   X_H_REG : begin
                       x_reg_temp[11:8] <= data[3:0];
                       address <=  Y_L_REG;
                   end
                   Y_L_REG : begin
                       y_reg_temp[7:0] <= data;
                       address <=  Y_H_REG;
                   end
                   Y_H_REG : begin
                       y_reg_temp[11:8] <= data[3:0];
                       address <=  Z_L_REG;
                   end
                   Z_L_REG : begin
                       z_reg_temp[7:0] <= data;
                       address <=  Z_H_REG;
                   end
                   Z_H_REG : begin
                       z_reg_temp[11:8] <= data[3:0];
                       roundDone <= 1;
                       address <=  X_L_REG;
                   end
                   CON_REG : begin //控制寄存器，
                       address <= X_L_REG;
                       rw <= 0;
                       instruction <= REGISTER_READ;
                   end
               endcase
        	end
        	else if(state == DATA_READ) begin //spi时钟的上升沿从miso捕获数据（SPI MODE0）
        	   data[counter] <= MISO;
        	end
        	else if(state == OVER) begin 
        	   state <= DATA_PROCESS;
        	   n_CS <= 1;
        	end
        end
     end
     
     always@(negedge clk_SPI) begin //spi时钟的下降沿更新数据（SPI MODE0）
        if(!reset) begin
            MOSI <= 0;
        end
        else begin
        	if(state == INSTRUCTION)//写入指令字节
                MOSI <= instruction[counter];
        	else if(state == ADDRESS) //写入地址指令字节
                 MOSI <= address[counter];
        	else if(state == DATA_WRITE) //写入数据
                MOSI <= data[counter];
        end
        
     end
    
endmodule
