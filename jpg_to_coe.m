clear               %清理命令行窗口
clc                 %清理工作区

% 使用imread函数读取图片,并转化为三维矩阵
image_array = imread('C:\Users\lenovo\Desktop\demo.jpg');

% 使用size函数计算图片矩阵三个维度的大小
% 第一维为图片的高度，第二维为图片的宽度，第三维为图片维度
[height,width,z]=size(image_array);   % 100*100*3
red   = image_array(:,:,1); % 提取红色分量，数据类型为uint8，图层为第1图层
green = image_array(:,:,2); % 提取绿色分量，数据类型为uint8，图层为第2图层
blue  = image_array(:,:,3); % 提取蓝色分量，数据类型为uint8，图层为第3图层
% 这样导出的rgb分量都是8bit

% 使用reshape函数将各个分量重组成一个一维矩阵
%为了避免溢出,将uint8类型的数据扩大为uint32类型
% 100x100是10000个像素点
r = uint32(reshape(red'   , 1 ,height*width));	%1维 10000个数据 	8bit
g = uint32(reshape(green' , 1 ,height*width));
b = uint32(reshape(blue'  , 1 ,height*width));

% 初始化要写入.COE文件中的RGB颜色矩阵
rgb=zeros(1,height*width);	% 1维 数据有10000个		?? 数据大小


% 显示模式的转换

% 将RGB888转换为RGB444
% 红色分量右移4位取出高4位,左移8位作为ROM中RGB数据的第11bit到第8bit
% 绿色分量右移4位取出高4位,左移4位作为ROM中RGB数据的第7bit到第4bit
% 蓝色分量右移4位取出高4位,左移0位作为ROM中RGB数据的第3bit到第0bit
 for i = 1:height*width
 	rgb(i) = bitshift(bitshift(r(i),-4),8)+ bitshift(bitshift(g(i),-4),4)+ bitshift(bitshift(b(i),-4),0);
 end


fid = fopen( 'E:\pythonfiles\wav_to_coe\image.coe', 'w+' );		

% .mif文件字符串打印
fprintf( fid, 'MEMORY_INITIALIZATION_RADIX=16;\n');
fprintf( fid, 'MEMORY_INITIALIZATION_VECTOR=\n',height*width);

% 写入图片数据
for i = 1:height*width
    if i == height*width
        fprintf(fid,'%03x;\n',rgb(i)); %最后一个数据后面加分号
    else
        fprintf(fid,'%03x,\n',rgb(i));
    end
end

fclose( fid ); % 关闭文件指针
