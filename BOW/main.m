%% Script to perform BOW-based image classification demo
% ========================================================================
% Image Classification using Bag of Words and Spatial Pyramid BoW
% Created by Piji Li (pagelee.sd@gmail.com)  
% Blog: http://www.zhizhihu.com
% Weibo: http://www.weibo.com/pagecn
% IRLab. : http://ir.sdu.edu.cn     
% Shandong University,Jinan,China
% 10/24/2011

%% initialize the settings

clc;
clear;
display('*********** start *********')
ini;
detect_opts=[];descriptor_opts=[];dictionary_opts=[];assignment_opts=[];ada_opts=[];


%% Descriptors 特征提取
descriptor_opts.type='sift';                      % name descripto
descriptor_opts.name=['des',descriptor_opts.type]; % output name (combines detector and descrtiptor name)
descriptor_opts.patchSize=16;                     % normalized patch size
descriptor_opts.gridSpacing=8;      % patch移动的步长是网格边长8像素
descriptor_opts.maxImageSize=1000;
GenerateSiftDescriptors(pg_opts,descriptor_opts);

%% Create the texton dictionary  构建码本  texton:纹理基元
dictionary_opts.dictionarySize = 300; %dictionary_opts： 
dictionary_opts.name='sift_features';         %dictionarySize：300
dictionary_opts.type='sift_dictionary';              %name：sift_features
CalculateDictionary(pg_opts, dictionary_opts);          %type：sift_dictionary
   
%% assignment 分配
assignment_opts.type='1nn';  %k近邻分类算法                  % name of assignment method
assignment_opts.descriptor_name=descriptor_opts.name;       % name of descriptor (input)
assignment_opts.dictionary_name=dictionary_opts.name;       % name of dictionary
assignment_opts.name=['BOW_',descriptor_opts.type]; % name of assignment output  name:BOW_sift
assignment_opts.dictionary_type=dictionary_opts.type;%dictionary_type:sift_dictionary
assignment_opts.featuretype=dictionary_opts.name;%featuretype:sift_features
assignment_opts.texton_name='texton_ind';
do_assignment(pg_opts,assignment_opts);%Assign the 360  images

%% CompilePyramid 构建空间金字塔
pyramid_opts.name='spatial_pyramid';
pyramid_opts.dictionarySize=dictionary_opts.dictionarySize;%还是取字典大小=300
pyramid_opts.pyramidLevels=3;
pyramid_opts.texton_name=assignment_opts.texton_name; %assignment_opts.texton_name='texton_ind';
CompilePyramid(pg_opts,pyramid_opts);
%Pyramid: the 360  images

%前2个没有基于空间金字塔，后2个是
%% Classification    %BOW rbf_svm
do_classification_rbf_svm

%% histogram intersection kernel  %直方图正交核
do_classification_inter_svm 

%% pyramid bow rbf 空间金字塔+bow rbf
do_p_classification_rbf_svm   

%% pyramid bow histogram intersection kernel
do_p_classification_inter_svm
%show_results_script
