function []=do_assignment(opts,assignment_opts)
%����
display('Computing assignments');
assign_flag=1;
%% check if assignment already exists
try
    assignment_opts2=getfield(load([opts.globaldatapath,'/',assignment_opts.name,'_settings']),'assignment_opts');
    if(isequal(assignment_opts,assignment_opts2))
        assign_flag=0;
        display('Recomputing assignments for this settings');
    else
        display('Overwriting assignment with same name, but other Assignment settings !!!!!!!!!!');
    end
end %�Թ�

if(assign_flag)
    %% load data set information and vocabulary
    load(opts.image_names); %��ȡ 'E:\\���\\BOW\\PG_BOW_DEMO-master\\labels/image_names.mat'������  image_names��<1x360 cell>
    nimages=opts.nimages; %nimages=360
    vocabulary=getfield(load([opts.globaldatapath,'/',assignment_opts.dictionary_type]),'dictionary');
    %vocabulary��300*128
    vocabulary_size=size(vocabulary,1);%vocabulary_size��300
    featuretype=assignment_opts.featuretype;%featuretype��sift_features
    
    %% apply assignment method to data set
    BOW=[];%�������
    for ii=1:nimages  %360��ͼƬ  image_dir�� 'E:\\���\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/'
        image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(ii,8));% location where detector is saved
        inFName = fullfile(image_dir, sprintf('%s', featuretype));%'E:\\���\\BOW\\PG_BOW_DEMO-master\\data\local\00000001\sift_features'
        load(inFName, 'features');
        points = features.data;%576*128 double
        
        
        texton_ind.x = features.x;%x:576*1 double
        texton_ind.y = features.y;%y:576*1 double
        texton_ind.wid = features.wid;%wid:200
        texton_ind.hgt = features.hgt;%hgt:200
        
        
        %�ص�
        switch assignment_opts.type    %'1nn'   % select assignment method
            case '1nn'
                d2 = EuclideanDistance(points, vocabulary);%d2:576*300  EuclideanDistance ����ŷʽ����
                [minz, index] = min(d2', [], 1);%����������minz��index��minz������¼d2��ÿ�е���Сֵ��index������¼ÿ����Сֵ���кš�
                %max(A,[],dim)��dimȡ1��2��dimȡ1ʱ���ú�����max(A)��ȫ��ͬ
                %minz:1*576 ����Ǿ��룬����С��1���� index:1*576 �к�
                BOW(:,ii)=hist(index,(1:vocabulary_size));%����ֱ��ͼ BOW��300*1 double(��ii=1ʱ)
                %���ݴ����BOW(:,ii)�ĵ�ii�� 
                %��ÿ��ͼ���576�������������࣬���ƺ�����Ϊvocabulary��ֱ��ͼ
                %ii=1��360 �ܹ�360��
                %���BOW��300*360 double��360��ֱ��ͼ
                
                texton_ind.data = index; %1*576
                save ([image_dir,'/',assignment_opts.texton_name],'texton_ind');
                %'E:\\���\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/texton_ind'
            otherwise
                display('A non existing assignment method is selected !!!!!');
        end
        fprintf('Assign the %d th image\n',ii);%Assign 360��
    end
    
    BOW=do_normalize(BOW,1);   % normalize the BOW histograms to sum-up to one.��һ��
    save ([opts.globaldatapath,'/',assignment_opts.name],'BOW');    % save the BOW representation in opts.globaldatapath
    save ([opts.globaldatapath,'/',assignment_opts.name,'_settings'],'assignment_opts');
end
end