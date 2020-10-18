function [] = GenerateSiftDescriptors(opts,descriptor_opts)
%��ȡsift��������
%descriptor_opts[](�ṹ��)�������
fprintf('Building Sift Descriptors\n\n');

%% parameters
descriptor_flag=1;
maxImageSize = descriptor_opts.maxImageSize; %1000
gridSpacing = descriptor_opts.gridSpacing; %8
patchSize = descriptor_opts.patchSize;%16

try %getfield()�õ��ṹ������ ��F=getfield(s,'field')�൱��F=s.field
    descriptor_opts2=getfield(load([opts.globaldatapath,'/',descriptor_opts.name,'_settings']),'descriptor_opts');
    if(isequal(descriptor_opts,descriptor_opts2))
        descriptor_flag=0;
        display('descriptor has already been computed for this settings');
    else
        display('Overwriting descriptor with same name, but other descriptor settings !!!!!!!!!!');
    end
end
%��data�ļ�ɾ������ִ�г����Թ���һ��

if(descriptor_flag)
    
    %% load image
    load(opts.image_names);     % load image in data set  ��ȡlabels�ļ����µ�image_names.mat�ļ�
    nimages=opts.nimages;    % number of images in data set 360��
    
    for f = 1:nimages
        
        I=load_image([opts.imgpath,'/', image_names{f}]);
        
        [hgt wid] = size(I); %��ȡͼ��ĸ�hgt�Ϳ�wid
        if min(hgt,wid) > maxImageSize %hgt��wid�е���Сֵ��maxImageSize=1000�Ƚ�
            I = imresize(I, maxImageSize/min(hgt,wid), 'bicubic'); %���ص�ͼ��I�ĳ�����ͼ��A�ĳ����maxImageSize/min(hgt,wid)����
                        %����1000/2000<1,��Ϊ����ͼ������С��������1000
                        %bicubic��
            fprintf('Loaded %s: original size %d x %d, resizing to %d x %d\n', ...
                image_names{f}, wid, hgt, size(I,2), size(I,1));
            [hgt wid] = size(I); %������Ĵ�С
        end  %���������С����һ��ͼ����200*200���������Ҳû�г���1000���Թ�ִ��
        
        %% make grid (coordinates of upper left patch corners)patch�����Ͻ�����
        %patch�������ҡ����ϵ����ƶ�
        remX = mod(wid-patchSize,gridSpacing);% the right edge gridSpacing=8��patchSize=16 (200-16)/8=23 mod()ȡ��
        offsetX = floor(remX/2)+1; %patch�����Ͻ������x���� floor()�Ӹ������ȡ��
        remY = mod(hgt-patchSize,gridSpacing);
        offsetY = floor(remY/2)+1;%patch�����Ͻ������y���� (1,1)
        
        [gridX,gridY] = meshgrid(offsetX:gridSpacing:wid-patchSize+1, offsetY:gridSpacing:hgt-patchSize+1);
        %�Ƴ�����grid��gridX <24*24>,gridY <24*24> meshgrid(1:8:185,1:8:185)
        fprintf('Processing %s: wid %d, hgt %d, grid size: %d x %d, %d patches\n', ...
            image_names{f}, wid, hgt, size(gridX,2), size(gridX,1), numel(gridX));
        %Processing training/Phoning/Phoning_0001.jpg: wid 200, hgt 200,grid size: 24 x 24, 576 patches
        
        %% find SIFT descriptors
        siftArr = find_sift_grid(I, gridX, gridY, patchSize, 0.8); %siftArr <576x128 double>
        %�����ⲽ����ȡsift���� ������
        siftArr = normalize_sift(siftArr);% normalize��ʲô��˼����һ�� siftArr <576x128 double> ���ݲ�һ����һЩ����0
        
        features.data = siftArr;
        features.x = gridX(:) + patchSize/2 - 0.5;%gridX(:)�����������ߵ�
        features.y = gridY(:) + patchSize/2 - 0.5;
        features.wid = wid;
        features.hgt = hgt;
        features.patchSize=patchSize;
                                    
        image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(f,8)); % location descriptor
        save ([image_dir,'/','sift_features'], 'features');           % save the descriptors
        %  image_dir  E:\\���\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/;
        fprintf('The %d th image finished...\n',f);
        
    end % for
    save ([opts.globaldatapath,'/',descriptor_opts.name,'_settings'],'descriptor_opts');      % save the settings of descriptor in opts.globaldatapath
end % if

end% function
