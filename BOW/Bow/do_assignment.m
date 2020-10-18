function []=do_assignment(opts,assignment_opts)
%分配
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
end %略过

if(assign_flag)
    %% load data set information and vocabulary
    load(opts.image_names); %读取 'E:\\李东红\\BOW\\PG_BOW_DEMO-master\\labels/image_names.mat'的数据  image_names：<1x360 cell>
    nimages=opts.nimages; %nimages=360
    vocabulary=getfield(load([opts.globaldatapath,'/',assignment_opts.dictionary_type]),'dictionary');
    %vocabulary：300*128
    vocabulary_size=size(vocabulary,1);%vocabulary_size：300
    featuretype=assignment_opts.featuretype;%featuretype：sift_features
    
    %% apply assignment method to data set
    BOW=[];%存放数据
    for ii=1:nimages  %360张图片  image_dir： 'E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/'
        image_dir=sprintf('%s/%s/',opts.localdatapath,num2string(ii,8));% location where detector is saved
        inFName = fullfile(image_dir, sprintf('%s', featuretype));%'E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data\local\00000001\sift_features'
        load(inFName, 'features');
        points = features.data;%576*128 double
        
        
        texton_ind.x = features.x;%x:576*1 double
        texton_ind.y = features.y;%y:576*1 double
        texton_ind.wid = features.wid;%wid:200
        texton_ind.hgt = features.hgt;%hgt:200
        
        
        %重点
        switch assignment_opts.type    %'1nn'   % select assignment method
            case '1nn'
                d2 = EuclideanDistance(points, vocabulary);%d2:576*300  EuclideanDistance 计算欧式距离
                [minz, index] = min(d2', [], 1);%返回行向量minz和index，minz向量记录d2的每列的最小值，index向量记录每列最小值的行号。
                %max(A,[],dim)：dim取1或2。dim取1时，该函数和max(A)完全相同
                %minz:1*576 算的是距离，都是小于1的数 index:1*576 行号
                BOW(:,ii)=hist(index,(1:vocabulary_size));%绘制直方图 BOW：300*1 double(当ii=1时)
                %数据存放在BOW(:,ii)的第ii列 
                %把每张图像的576个特征向量归类，绘制横坐标为vocabulary的直方图
                %ii=1：360 总共360张
                %最后BOW：300*360 double，360个直方图
                
                texton_ind.data = index; %1*576
                save ([image_dir,'/',assignment_opts.texton_name],'texton_ind');
                %'E:\\李东红\\BOW\\PG_BOW_DEMO-master\\data/local/00000001/texton_ind'
            otherwise
                display('A non existing assignment method is selected !!!!!');
        end
        fprintf('Assign the %d th image\n',ii);%Assign 360张
    end
    
    BOW=do_normalize(BOW,1);   % normalize the BOW histograms to sum-up to one.归一化
    save ([opts.globaldatapath,'/',assignment_opts.name],'BOW');    % save the BOW representation in opts.globaldatapath
    save ([opts.globaldatapath,'/',assignment_opts.name,'_settings'],'assignment_opts');
end
end