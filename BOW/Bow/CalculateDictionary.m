function [ ] = CalculateDictionary(opts, dictionary_opts)

fprintf('Building Dictionary using Training Data\n\n');

%% parameters
dictionary_flag=1;                               
dictionarySize = dictionary_opts.dictionarySize;%dictionarySize:300
featureName=dictionary_opts.name;               %name:'sift_features'
featuretype=dictionary_opts.type;               %type:'sift_dictionary'

try 
    dictionary_opts2=getfield(load([opts.globaldatapath,'/',dictionary_opts.name,'_settings']),'dictionary_opts');
    %路径：dictionary_opts/sift_features_settings  
    if(isequal(dictionary_opts,dictionary_opts2))
        dictionary_flag=0;
        display(' dictionary has already been computed for this settings');
    else
        display('Overwriting  dictionary with same name, but other  dictionary settings !!!!!!!!!!');
    end
end
%略过

if(dictionary_flag)
    %% k-means clustering 聚类
    
    nimages=opts.ntraning;  % number of traning images in data set, we must make sure the fist nimages is for trarning
                            %nimages=240
    niters=100;           %maximum iterations  最大迭代次数=100
    %第一张图片
    image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(1,8)); % location descriptor
    % localdatapath： E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data/local
    % image_dir： E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/
    inFName = fullfile(image_dir, sprintf('%s', featureName)); %featureName：sift_features
    % E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data\local\00000001\sift_features
    load(inFName, 'features');%mat文件中加载指定变量  加载inFName.features
    
                    %features.data:576*128
    data = features.data; %data:576*128
    %第二张图片
    image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(2,8)); % location descriptor
    % E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data/local/00000002/
    inFName = fullfile(image_dir, sprintf('%s', 'sift_features'));
    % E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data\local\00000002\sift_features
    load(inFName, 'features');
    data = [data;features.data];%data:1152*128
    
    centres = zeros(dictionarySize, size(data,2));%size(data,2)返回data的列数：128  centres：300*128的0矩阵
    [ndata, data_dim] = size(data);%ndata：1152 data_dim：128
    [ncentres, dim] = size(centres);%ncentres：300  dim：128
    %size函数将矩阵centres的行数返回到第一个输出变量ncentres：300，将矩阵的列数返回到第二个输出变量dim：128。
    %% initialization
    
    perm = randperm(ndata);%ndata=1152，产生ndata个在0到ndata之间产生的随机元素的向量 perm：1*1152 double
    perm = perm(1:ncentres);%ncentres：300  取第1-300列的元素，perm：1*300 double
    centres = data(perm, :);%？？？取data中前300行的所有元素，故centres：300*128 
        %data：1152*128        perm：1*300 double(数值在3-1147之间)
    num_points=zeros(1,dictionarySize);%1*300的0矩阵
    old_centres = centres;%old_centres：300*128
    display('Run k-means');
    
    for n=1:niters
        % Save old centres to check for termination
        e2=max(max(abs(centres - old_centres)));
        % max(A)：返回一个行向量，向量的第i个元素是矩阵A的第i列上的最大值
        inError(n)=e2;
        old_centres = centres;%old_centres：300*128
        tempc = zeros(ncentres, dim);%ncentres：300   tempc：300*128的0矩阵
        num_points=zeros(1,ncentres);%num_points：1*300的0矩阵
        
        for f = 1:nimages        %niters=100,n=1:niters   f=1:240
            fprintf('The %d th interation the %d th image. eCenter=%f \n',n,f,e2);%inError(n)=e2;
            image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(f,8)); % location descriptor
            inFName = fullfile(image_dir, sprintf('%s',featureName));
            
            
            load(inFName, 'features');
            data = features.data;%data：576*128
            [ndata, data_dim] = size(data);
            
            id = eye(ncentres);%id：300*300的单位矩阵
            d2 = EuclideanDistance(data,centres);%d2：576*300的矩阵 分别计算576个特征向量与300个词的欧式距离
            % Assign each point to nearest centre 
            [minvals, index] = min(d2', [], 1);%minvals：1*576  index：1*576 会计算出576个距离，576列
            % [Y,U]=min(A)：返回行向量Y和U，Y向量记录A的每列的最小值，U向量记录每列最小值的行号。
            %min(A,[],dim)：dim取1或2。dim取1时，该函数和min(A)完全相同；
            %dim取2时，该函数返回一个列向量，其第i个元素是A矩阵的第i行上的最小值。
            post = id(index,:);
            % matrix, if word i is in cluster j, post(i,j)=1, else 0;
            %post：576*300   id：300*300   index：1*576
            num_points = num_points + sum(post, 1);
            %num_points：1*300 
            for j = 1:ncentres
                tempc(j,:) =  tempc(j,:)+sum(data(find(post(:,j)),:), 1); %find(post(:,j))是找出post中第j列上不为0的行号
            end
            
        end
        
        for j = 1:ncentres
            if num_points(j)>0
                centres(j,:) =  tempc(j,:)/num_points(j); %每一类的均值作为中心
            end
        end
        if n > 1
            % Test for termination
            
            %Threshold
            ThrError=0.009; %设定阈值
            
            if max(max(abs(centres - old_centres))) <0.009 % e2
                dictionary= centres;%这个点就是codebook里的一个codewords
                fprintf('Saving texton dictionary\n');
                save ([opts.globaldatapath,'/',featuretype],'dictionary');      % save the settings of descriptor in opts.globaldatapath
                break;
            end
            
            fprintf('The %d th interation finished \n',n);
        end
        
    end
    
    save ([opts.globaldatapath,'/',dictionary_opts.name,'_settings'],'dictionary_opts');
    
end
end
