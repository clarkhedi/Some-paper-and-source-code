function [ pyramid_all ] = CompilePyramid(opts,pyramid_opts )
%构建空间金字塔
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
%略过

if(pyramid_flag)
    binsHigh = 2^(pyramidLevels-1);%binsHigh=4
    pyramid_all = [];%矩阵大小为设定，为存数据作准备
    nimages=opts.nimages;   % number of images in data set  360
    
    for f = 1:nimages
        
        
        %% load texton indices 纹理基元索引
        image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(f,8)); % location descriptor
        inFName = fullfile(image_dir, sprintf('%s', texton_name));
        load(inFName, 'texton_ind');
        
        %% get width and height of input image
        wid = texton_ind.wid;%200
        hgt = texton_ind.hgt;%200
        
        
       %% compute histogram at the finest level
        % 对应的是level1(总共是level1，level2和level3)，level2：把图像分成4*4=16个子区域，要作16个直方图。
        pyramid_cell = cell(pyramidLevels,1);%3*1 cell 3行1列 元胞数组
        pyramid_cell{1} = zeros(binsHigh, binsHigh, dictionarySize);%4*4*300 
        %第1行第1列为：4*4*300的零元素数组
        for i=1:binsHigh %循环16次  binsHigh=4
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
                pyramid_cell{1}(i,j,:) = hist(texton_patch, 1:dictionarySize)./length(texton_ind.data);%绘制直方图，绘制16个直方图。
            end
        end
        
       %% compute histograms at the coarser levels  
        % 对应的是level2和level3(总共是level1，level2和level3)，
        %level2：把图像分成2*2=4个子区域，要作4个直方图。  
        %level3：不划分图像，绘制1个直方图
        num_bins = binsHigh/2;%2
        for l = 2:pyramidLevels%2：3
            pyramid_cell{l} = zeros(num_bins, num_bins, dictionarySize);%2*2*300，有pyramid_cell{2}和pyramid_cell{3}
            for i=1:num_bins %2
                for j=1:num_bins
                    pyramid_cell{l}(i,j,:) = ...
                        pyramid_cell{l-1}(2*i-1,2*j-1,:) + pyramid_cell{l-1}(2*i,2*j-1,:) + ...
                        pyramid_cell{l-1}(2*i-1,2*j,:) + pyramid_cell{l-1}(2*i,2*j,:);
                end
            end %这一步结束后，完成level2，产生2*2*300
            num_bins = num_bins/2; %这步完成level3，产生1*1*300
        end
        
        %% stack all the histograms with appropriate weights权重
        pyramid = [];
        for l = 1:pyramidLevels-1 %level1(16个子区域)和level2(4个子区域)加权重，都乘以二分之一
            pyramid = [pyramid pyramid_cell{l}(:)' .* 2^(-l)];
        end
        pyramid = [pyramid pyramid_cell{pyramidLevels}(:)' .* 2^(1-pyramidLevels)]; %都乘以四分之一   
        pyramid_all = [pyramid_all; pyramid];
        
        fprintf('Pyramid: the %d th images.\n',f);
    end % f
    
    pyramid_all=pyramid_all';%6300*360
    save ([opts.globaldatapath,'/',pyramid_opts.name],'pyramid_all');
    
    save ([opts.globaldatapath,'/',pyramid_opts.name,'_settings'],'pyramid_opts');
end

end
