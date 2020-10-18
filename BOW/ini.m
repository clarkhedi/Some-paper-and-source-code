% ========================================================================
% Image Classification using Bag of Words and Spatial Pyramid BoW
% Created by Piji Li (pagelee.sd@gmail.com)  
% Blog: http://www.zhizhihu.com
% Weibo: http://www.weibo.com/pagecn
% IRLab. : http://ir.sdu.edu.cn     
% Shandong University,Jinan,China
% 10/24/2011

%���ļ���Ҫ���һЩ���������ݿ�����ӵ�ַ
clear pg_opts  %�������pg_opts��֮ǰ�������
               %pg_opts <1x1 struct>
% rootpath='/home/lipiji/PG_BOW_DEMO/';
% rootpath='C:\\Users\\Administrator\\Desktop\\PG_BOW_DEMO-master\\';
% rootpath='E:\\���\\BOW\\PG_BOW_DEMO-master\\'; %m�ļ���·��
rootpath='C:\\Users\\HD\\Desktop\\CVPR_work\\�ʰ�ģ��(BoW)\\PG_BOW_DEMO-master\\';
%%
addpath libsvm; %����·�� ��Ϊ��E:\���\BOW\PG_BOW_DEMO-master\libsvm
addpath BOW; 

%% change these paths to point to the image, data and label location
% �ı���Щ·��ָ��ͼ�����ݺͱ�ǩλ��
images_set=strcat(rootpath,'images'); %  E:\\���\\BOW\\PG_BOW_DEMO-master\\images
data=strcat(rootpath,'data');  %  E:\\���\\BOW\\PG_BOW_DEMO-master\\data
labels=strcat(rootpath,'labels');  %  E:\\���\\BOW\\PG_BOW_DEMO-master\\labels

%%
pg_opts.imgpath=images_set; % image path
pg_opts.datapath=data;
pg_opts.labelspath=labels;

%%
% local and global data paths
pg_opts.localdatapath=sprintf('%s/local',pg_opts.datapath);%localdatapath��'E:\\���\\BOW\\PG_BOW_DEMO-master\\data/local'
pg_opts.globaldatapath=sprintf('%s/global',pg_opts.datapath);%globaldatapath��'E:\\���\\BOW\\PG_BOW_DEMO-master\\data/global'

% initialize the training set
pg_opts.trainset=sprintf('%s/trainset.mat',pg_opts.labelspath);
% initialize the test set
pg_opts.testset=sprintf('%s/testset.mat',pg_opts.labelspath);
% initialize the labels
pg_opts.labels=sprintf('%s/labels.mat',pg_opts.labelspath);
% initialize the image names
pg_opts.image_names=sprintf('%s/image_names.mat',pg_opts.labelspath);

% Classes
pg_opts.classes = load([pg_opts.labelspath,'/classes.mat']);%���ļ����뵽MATLAB workspace��
                        %labelspath��E:\\���\\BOW\\PG_BOW_DEMO-master\\labels/classes.mat   
                        %classes��[1x1 struct] ����Ϊ{'Phoning';'PlayingGuitar';'RidingBike';'RidingHorse';'Running';'Shooting';}
pg_opts.classes = pg_opts.classes.classes;%��ʲô��˼��pg_opts��classes���ǽṹ�� %classes:{6x1 cell}
pg_opts.nclasses = length(pg_opts.classes);%nclasses:6

load(sprintf('%s',pg_opts.labels)); % labels <360x1 double>
                    %��ȡlabels.mat�ļ� 
                    %labels��E:\\���\\BOW\\PG_BOW_DEMO-master\\labels/labels.mat 
pg_opts.nimages = size(labels,1); %%nimages��360

load(pg_opts.trainset); %<360x1 logical> ��trainset.mat������trainset==1
load(pg_opts.testset); %<360x1 logical> ��testset.mat������testset==1
pg_opts.ntraning = length(find(trainset==1));%ntraning��240
pg_opts.ntesting = length(find(testset==1));%ntesting��120

%% creat the directory to save data 
MakeDataDirectory(pg_opts);
