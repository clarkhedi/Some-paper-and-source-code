function string_out=num2string(num_in,string_length)
%���ܣ�����00000001-00000360 % image_dir�� E:\\���\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/
if(num_in~=0)%num_in=1
    eenheid = floor(log10(num_in))+1;%eenheid=1
else
    eenheid = 1;
end

string_out='';
nul_string='0';
for ii=eenheid+1:string_length%2:8 ѭ��7��
    string_out=sprintf('%s%s',string_out,nul_string);%������7��0��'0000000'
end
string_out=sprintf('%s%s',string_out,num2str(num_in));%00000001
%num2str(num_in)��ֵת�ַ���
