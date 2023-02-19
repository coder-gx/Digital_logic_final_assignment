clear               %���������д���
clc                 %��������

% ʹ��imread������ȡͼƬ,��ת��Ϊ��ά����
image_array = imread('C:\Users\lenovo\Desktop\demo.jpg');

% ʹ��size��������ͼƬ��������ά�ȵĴ�С
% ��һάΪͼƬ�ĸ߶ȣ��ڶ�άΪͼƬ�Ŀ�ȣ�����άΪͼƬά��
[height,width,z]=size(image_array);   % 100*100*3
red   = image_array(:,:,1); % ��ȡ��ɫ��������������Ϊuint8��ͼ��Ϊ��1ͼ��
green = image_array(:,:,2); % ��ȡ��ɫ��������������Ϊuint8��ͼ��Ϊ��2ͼ��
blue  = image_array(:,:,3); % ��ȡ��ɫ��������������Ϊuint8��ͼ��Ϊ��3ͼ��
% ����������rgb��������8bit

% ʹ��reshape�������������������һ��һά����
%Ϊ�˱������,��uint8���͵���������Ϊuint32����
% 100x100��10000�����ص�
r = uint32(reshape(red'   , 1 ,height*width));	%1ά 10000������ 	8bit
g = uint32(reshape(green' , 1 ,height*width));
b = uint32(reshape(blue'  , 1 ,height*width));

% ��ʼ��Ҫд��.COE�ļ��е�RGB��ɫ����
rgb=zeros(1,height*width);	% 1ά ������10000��		?? ���ݴ�С


% ��ʾģʽ��ת��

% ��RGB888ת��ΪRGB444
% ��ɫ��������4λȡ����4λ,����8λ��ΪROM��RGB���ݵĵ�11bit����8bit
% ��ɫ��������4λȡ����4λ,����4λ��ΪROM��RGB���ݵĵ�7bit����4bit
% ��ɫ��������4λȡ����4λ,����0λ��ΪROM��RGB���ݵĵ�3bit����0bit
 for i = 1:height*width
 	rgb(i) = bitshift(bitshift(r(i),-4),8)+ bitshift(bitshift(g(i),-4),4)+ bitshift(bitshift(b(i),-4),0);
 end


fid = fopen( 'E:\pythonfiles\wav_to_coe\image.coe', 'w+' );		

% .mif�ļ��ַ�����ӡ
fprintf( fid, 'MEMORY_INITIALIZATION_RADIX=16;\n');
fprintf( fid, 'MEMORY_INITIALIZATION_VECTOR=\n',height*width);

% д��ͼƬ����
for i = 1:height*width
    if i == height*width
        fprintf(fid,'%03x;\n',rgb(i)); %���һ�����ݺ���ӷֺ�
    else
        fprintf(fid,'%03x,\n',rgb(i));
    end
end

fclose( fid ); % �ر��ļ�ָ��
