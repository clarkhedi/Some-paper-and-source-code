function [ pyramid_all ] = CompilePyramid(opts,pyramid_opts )
%�����ռ������
%
pyramid_flag=1;
fprintf('Building Spatial Pyramid\n');

%% parameters
texton_name=pyramid_opts.texton_name;%texton_ind
dictionarySize = pyramid_opts.dictionarySize;%300
pyramidLevels = pyramid_opts.pyramidLevels;%3

try
    pyramid_opts2=getfield(load([opts.globaldatapath,'/',pyramid_opts.name,'_settings']),'pyramid_opts');
    if(isequal(pyramid_opts,pyramid_opts2))
        pyramid_flag=0;
        display(' Pyramid has already been computed for this settings');
    else
        display('Overwriting  Pyramid with same name, but other  Pyramid settings !!!!!!!!!!');
    end
end
%�Թ�

if(pyramid_flag)
    binsHigh = 2^(pyramidLevels-1);%binsHigh=4
    pyramid_all = [];%�����СΪ�趨��Ϊ��������׼��
    nimages=opts.nimages;   % number of images in data set  360
    
    for f = 1:nimages
        
        
        %% load texton indices �����Ԫ����
        image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(f,8)); % location descriptor
        inFName = fullfile(image_dir, sprintf('%s', texton_name));
        load(inFName, 'texton_ind');
        
        %% get width and height of input image
        wid = texton_ind.wid;%200
        hgt = texton_ind.hgt;%200
        
        
       %% compute histogram at the finest level
        % ��Ӧ����level1(�ܹ���level1��level2��level3)��level2����ͼ��ֳ�4*4=16��������Ҫ��16��ֱ��ͼ��
        pyramid_cell = cell(pyramidLevels,1);%3*1 cell 3��1�� Ԫ������
        pyramid_cell{1} = zeros(binsHigh, binsHigh, dictionarySize);%4*4*300 
        %��1�е�1��Ϊ��4*4*300����Ԫ������
        for i=1:binsHigh %ѭ��16��  binsHigh=4
            for j=1:binsHigh
                
                % find the coordinates of the current bin
                x_lo = floor(wid/binsHigh * (i-1));%floor(200/4*(1-1))=0
                x_hi = floor(wid/binsHigh * i);%50
                y_lo = floor(hgt/binsHigh * (j-1));%0
                y_hi = floor(hgt/binsHigh * j);%50
                               %data:1*576 double      %x:576*1
                texton_patch = texton_ind.data( (texton_ind.x > x_lo) & (texton_ind.x <= x_hi) & ...
                    (texton_ind.y > y_lo) & (texton_ind.y <= y_hi));
                      %y:576*1    0<x<=50   0<y<=50  %texton_patch:1*36
                % make histogram of features in bin          length(texton_ind.data)=576
                pyramid_cell{1}(i,j,:) = hist(texton_patch, 1:dictionarySize)./length(texton_ind.data);%����ֱ��ͼ������16��ֱ��ͼ��
            end
        end
        
       %% compute histograms at the coarser levels  
        % ��Ӧ����level2��level3(�ܹ���level1��level2��level3)��
        %level2����ͼ��ֳ�2*2=4��������Ҫ��4��ֱ��ͼ��  
        %level3��������ͼ�񣬻���1��ֱ��ͼ
        num_bins = binsHigh/2;%2
        for l = 2:pyramidLevels%2��3
            pyramid_cell{l} = zeros(num_bins, num_bins, dictionarySize);%2*2*300����pyramid_cell{2}��pyramid_cell{3}
            for i=1:num_bins %2
                for j=1:num_bins
                    pyramid_cell{l}(i,j,:) = ...
                        pyramid_cell{l-1}(2*i-1,2*j-1,:) + pyramid_cell{l-1}(2*i,2*j-1,:) + ...
                        pyramid_cell{l-1}(2*i-1,2*j,:) + pyramid_cell{l-1}(2*i,2*j,:);
                end
            end %��һ�����������level2������2*2*300
            num_bins = num_bins/2; %�ⲽ���level3������1*1*300
        end
        
        %% stack all the histograms with appropriate weightsȨ��
        pyramid = [];
        for l = 1:pyramidLevels-1 %level1(16��������)��level2(4��������)��Ȩ�أ������Զ���֮һ
            pyramid = [pyramid pyramid_cell{l}(:)' .* 2^(-l)];
        end
        pyramid = [pyramid pyramid_cell{pyramidLevels}(:)' .* 2^(1-pyramidLevels)]; %�������ķ�֮һ   
        pyramid_all = [pyramid_all; pyramid];
        
        fprintf('Pyramid: the %d th images.\n',f);
    end % f
    
    pyramid_all=pyramid_all';%6300*360
    save ([opts.globaldatapath,'/',pyramid_opts.name],'pyramid_all');
    
    save ([opts.globaldatapath,'/',pyramid_opts.name,'_settings'],'pyramid_opts');
end

end
