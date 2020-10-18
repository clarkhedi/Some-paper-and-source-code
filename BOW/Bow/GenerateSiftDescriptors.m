function [] = GenerateSiftDescriptors(opts,descriptor_opts)
%提取sift特征向量
%descriptor_opts[](结构体)存放数据
fprintf('Building Sift Descriptors\n\n');

%% parameters
descriptor_flag=1;
maxImageSize = descriptor_opts.maxImageSize; %1000
gridSpacing = descriptor_opts.gridSpacing; %8
patchSize = descriptor_opts.patchSize;%16

try %getfield()得到结构域内容 如F=getfield(s,'field')相当于F=s.field
    descriptor_opts2=getfield(load([opts.globaldatapath,'/',descriptor_opts.name,'_settings']),'descriptor_opts');
    if(isequal(descriptor_opts,descriptor_opts2))
        descriptor_flag=0;
        display('descriptor has already been computed for this settings');
    else
        display('Overwriting descriptor with same name, but other descriptor settings !!!!!!!!!!');
    end
end
%把data文件删除，再执行程序，略过这一步

if(descriptor_flag)
    
    %% load image
    load(opts.image_names);     % load image in data set  读取labels文件夹下的image_names.mat文件
    nimages=opts.nimages;    % number of images in data set 360张
    
    for f = 1:nimages
        
        I=load_image([opts.imgpath,'/', image_names{f}]);
        
        [hgt wid] = size(I); %获取图像的高hgt和宽wid
        if min(hgt,wid) > maxImageSize %hgt，wid中的最小值与maxImageSize=1000比较
            I = imresize(I, maxImageSize/min(hgt,wid), 'bicubic'); %返回的图像I的长宽是图像A的长宽的maxImageSize/min(hgt,wid)倍，
                        %例如1000/2000<1,即为缩放图像，最后大小都调整到1000
                        %bicubic：
            fprintf('Loaded %s: original size %d x %d, resizing to %d x %d\n', ...
                image_names{f}, wid, hgt, size(I,2), size(I,1));
            [hgt wid] = size(I); %调整后的大小
        end  %无需调整大小，第一组图像都是200*200，其他组的也没有超过1000，略过执行
        
        %% make grid (coordinates of upper left patch corners)patch的左上角坐标
        %patch自左向右、从上到下移动
        remX = mod(wid-patchSize,gridSpacing);% the right edge gridSpacing=8，patchSize=16 (200-16)/8=23 mod()取余
        offsetX = floor(remX/2)+1; %patch的左上角坐标的x坐标 floor()从负无穷方向取整
        remY = mod(hgt-patchSize,gridSpacing);
        offsetY = floor(remY/2)+1;%patch的左上角坐标的y坐标 (1,1)
        
        [gridX,gridY] = meshgrid(offsetX:gridSpacing:wid-patchSize+1, offsetY:gridSpacing:hgt-patchSize+1);
        %制成网格grid，gridX <24*24>,gridY <24*24> meshgrid(1:8:185,1:8:185)
        fprintf('Processing %s: wid %d, hgt %d, grid size: %d x %d, %d patches\n', ...
            image_names{f}, wid, hgt, size(gridX,2), size(gridX,1), numel(gridX));
        %Processing training/Phoning/Phoning_0001.jpg: wid 200, hgt 200,grid size: 24 x 24, 576 patches
        
        %% find SIFT descriptors
        siftArr = find_sift_grid(I, gridX, gridY, patchSize, 0.8); %siftArr <576x128 double>
        %经过这步，提取sift特征 ？？？
        siftArr = normalize_sift(siftArr);% normalize是什么意思？归一化 siftArr <576x128 double> 数据不一样，一些数归0
        
        features.data = siftArr;
        features.x = gridX(:) + patchSize/2 - 0.5;%gridX(:)？？？按列走的
        features.y = gridY(:) + patchSize/2 - 0.5;
        features.wid = wid;
        features.hgt = hgt;
        features.patchSize=patchSize;
                                    
        image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(f,8)); % location descriptor
        save ([image_dir,'/','sift_features'], 'features');           % save the descriptors
        %  image_dir  E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/;
        fprintf('The %d th image finished...\n',f);
        
    end % for
    save ([opts.globaldatapath,'/',descriptor_opts.name,'_settings'],'descriptor_opts');      % save the settings of descriptor in opts.globaldatapath
end % if

end% function
