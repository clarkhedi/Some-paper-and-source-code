function [ ] = CalculateDictionary(opts, dictionary_opts)

fprintf('Building Dictionary using Training Data\n\n');

%% parameters
dictionary_flag=1;                               
dictionarySize = dictionary_opts.dictionarySize;%dictionarySize:300
featureName=dictionary_opts.name;               %name:'sift_features'
featuretype=dictionary_opts.type;               %type:'sift_dictionary'

try 
    dictionary_opts2=getfield(load([opts.globaldatapath,'/',dictionary_opts.name,'_settings']),'dictionary_opts');
    %·����dictionary_opts/sift_features_settings  
    if(isequal(dictionary_opts,dictionary_opts2))
        dictionary_flag=0;
        display(' dictionary has already been computed for this settings');
    else
        display('Overwriting  dictionary with same name, but other  dictionary settings !!!!!!!!!!');
    end
end
%�Թ�

if(dictionary_flag)
    %% k-means clustering ����
    
    nimages=opts.ntraning;  % number of traning images in data set, we must make sure the fist nimages is for trarning
                            %nimages=240
    niters=100;           %maximum iterations  ����������=100
    %��һ��ͼƬ
    image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(1,8)); % location descriptor
    % localdatapath�� E:\\���\\BOW\\PG_BOW_DEMO-master\\data/local
    % image_dir�� E:\\���\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/
    inFName = fullfile(image_dir, sprintf('%s', featureName)); %featureName��sift_features
    % E:\\���\\BOW\\PG_BOW_DEMO-master\\data\local\00000001\sift_features
    load(inFName, 'features');%mat�ļ��м���ָ������  ����inFName.features
    
                    %features.data:576*128
    data = features.data; %data:576*128
    %�ڶ���ͼƬ
    image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(2,8)); % location descriptor
    % E:\\���\\BOW\\PG_BOW_DEMO-master\\data/local/00000002/
    inFName = fullfile(image_dir, sprintf('%s', 'sift_features'));
    % E:\\���\\BOW\\PG_BOW_DEMO-master\\data\local\00000002\sift_features
    load(inFName, 'features');
    data = [data;features.data];%data:1152*128
    
    centres = zeros(dictionarySize, size(data,2));%size(data,2)����data��������128  centres��300*128��0����
    [ndata, data_dim] = size(data);%ndata��1152 data_dim��128
    [ncentres, dim] = size(centres);%ncentres��300  dim��128
    %size����������centres���������ص���һ���������ncentres��300����������������ص��ڶ����������dim��128��
    %% initialization
    
    perm = randperm(ndata);%ndata=1152������ndata����0��ndata֮����������Ԫ�ص����� perm��1*1152 double
    perm = perm(1:ncentres);%ncentres��300  ȡ��1-300�е�Ԫ�أ�perm��1*300 double
    centres = data(perm, :);%������ȡdata��ǰ300�е�����Ԫ�أ���centres��300*128 
        %data��1152*128        perm��1*300 double(��ֵ��3-1147֮��)
    num_points=zeros(1,dictionarySize);%1*300��0����
    old_centres = centres;%old_centres��300*128
    display('Run k-means');
    
    for n=1:niters
        % Save old centres to check for termination
        e2=max(max(abs(centres - old_centres)));
        % max(A)������һ���������������ĵ�i��Ԫ���Ǿ���A�ĵ�i���ϵ����ֵ
        inError(n)=e2;
        old_centres = centres;%old_centres��300*128
        tempc = zeros(ncentres, dim);%ncentres��300   tempc��300*128��0����
        num_points=zeros(1,ncentres);%num_points��1*300��0����
        
        for f = 1:nimages        %niters=100,n=1:niters   f=1:240
            fprintf('The %d th interation the %d th image. eCenter=%f \n',n,f,e2);%inError(n)=e2;
            image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(f,8)); % location descriptor
            inFName = fullfile(image_dir, sprintf('%s',featureName));
            
            
            load(inFName, 'features');
            data = features.data;%data��576*128
            [ndata, data_dim] = size(data);
            
            id = eye(ncentres);%id��300*300�ĵ�λ����
            d2 = EuclideanDistance(data,centres);%d2��576*300�ľ��� �ֱ����576������������300���ʵ�ŷʽ����
            % Assign each point to nearest centre 
            [minvals, index] = min(d2', [], 1);%minvals��1*576  index��1*576 ������576�����룬576��
            % [Y,U]=min(A)������������Y��U��Y������¼A��ÿ�е���Сֵ��U������¼ÿ����Сֵ���кš�
            %min(A,[],dim)��dimȡ1��2��dimȡ1ʱ���ú�����min(A)��ȫ��ͬ��
            %dimȡ2ʱ���ú�������һ�������������i��Ԫ����A����ĵ�i���ϵ���Сֵ��
            post = id(index,:);
            % matrix, if word i is in cluster j, post(i,j)=1, else 0;
            %post��576*300   id��300*300   index��1*576
            num_points = num_points + sum(post, 1);
            %num_points��1*300 
            for j = 1:ncentres
                tempc(j,:) =  tempc(j,:)+sum(data(find(post(:,j)),:), 1); %find(post(:,j))���ҳ�post�е�j���ϲ�Ϊ0���к�
            end
            
        end
        
        for j = 1:ncentres
            if num_points(j)>0
                centres(j,:) =  tempc(j,:)/num_points(j); %ÿһ��ľ�ֵ��Ϊ����
            end
        end
        if n > 1
            % Test for termination
            
            %Threshold
            ThrError=0.009; %�趨��ֵ
            
            if max(max(abs(centres - old_centres))) <0.009 % e2
                dictionary= centres;%��������codebook���һ��codewords
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
