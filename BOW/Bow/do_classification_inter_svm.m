% classification script using SVM
%�����Զ���ĺ˺���

fprintf('\nClassification using histogram intersection kernel svm\n');
% load the BOW representations, the labels, and the train and test set
%��������
load(pg_opts.trainset);
load(pg_opts.testset);
load(pg_opts.labels);
load([pg_opts.globaldatapath,'/',assignment_opts.name])

train_labels    = labels(trainset);          % contains the labels of the trainset 240*1
train_data      = BOW(:,trainset)';          %ת�� BOW:300*360   train_data:240*300   % contains the train data   
[train_labels,sindex]=sort(train_labels);    % we sort the labels to ensure that the first label is '1', the second '2' etc ��1������6��
train_data=train_data(sindex,:);
test_labels     = labels(testset);           % contains the labels of the testset
test_data       = BOW(:,testset)';           %120*300
%[B,IX] = sort(A,...)������������IX�����СΪsize(IX) == size(A)����A��һ��������B = A(IX)��
% contains the test data

%% train kernal ��һ���Ǹ���ѵ�����ĺ˾���
kernel_train = hist_isect(train_data,train_data);       % 240*240 double
kernel_train = [(1:size(kernel_train,1))',kernel_train];%240*241 double ������1��;���Ǵ�1��240��1��
%��Ҫʹ��-t 4��������Ҫ�����������кŷ��ں˾���ǰ�棬�γ�һ���µľ���
%Ȼ��ʹ��svmtrain����֧������������ʹ��svmpredict����Ԥ�⼴�ɡ�
%%
bestc=200;bestg=2;
bestcv=0;
% for log2c = -1:10,
%   for log2g = -1:0.1:1.5,
%     cmd = ['-v 5 -t 4 -c ', num2str(2^log2c), ' -g ', num2str(2^log2g)];
%     %cv = svmtrain(train_labels, train_data, cmd);
%     cv = svmtrain(train_labels, kernel_train, cmd);
%     if (cv >= bestcv),
%       bestcv = cv; bestc = 2^log2c; bestg = 2^log2g;
%     end
%     fprintf('%g %g %g (best c=%g, g=%g, rate=%g)\n', log2c, log2g, cv, bestc, bestg, bestcv);
%   end
% end

%-s 0:svm������C-SVC��  -t 4:Ԥ����˺�����   -c %f���ͷ����ӣ�   -b 1�����ʹ��ƣ��Ƿ����SVC�ĸ��ʹ��ƣ�
%-g %f�����ú˺�����gamma��ֵ
options=sprintf('-s 0 -t 4 -c %f -b 1 -g %f -q',bestc,bestg);%bestc=200;bestg=2;
%model=svmtrain(train_labels, train_data,options);
model=svmtrain(train_labels,kernel_train,options);%ʹ��svmtrain����֧����������������ѵ�����Ͻ�������ģ��
%[tmp svindex]=ismember(model.SVs, kernel_train,'rows');

% train_label����ʾѵ�����ı�ǩ��
% train_matrix����ʾѵ���������Ծ���
% libsvm_options������Ҫ���õ�һϵ�в��������������ɲμ���libsvm ����˵��.txt����������ܵĺ���ϸ����Ӣ�Ķ��еġ�����ûع�Ļ������е�-s����ֵӦΪ3��
% model:��ѵ���õ���ģ�ͣ���һ���ṹ�壨����������õ�-v���õ��ľͲ��ǽṹ�壬���ڷ������⣬�õ����ǽ�������µ�ƽ������׼ȷ�ʣ����ڻع����⣬�õ����Ǿ�������

%% kernel test ��һ���Ǹ������Լ��ĺ˾���
kernel_test = hist_isect(test_data,train_data);%120*240 double
kernel_test = [(1:size(kernel_test,1))',kernel_test];%120*241 double

%[predict_label, accuracy , dec_values] = svmpredict(test_labels,test_data, model,'-b 1');
%Ԥ����Լ��ϱ�ǩ  '-b 1'���ʹ���
[predict_label, accuracy , dec_values] = svmpredict(test_labels,kernel_test, model,'-b 1');
%���룺
%test_labels����ʾ���Լ��ı�ǩ(���ֵ���Բ�֪������Ϊ��Ԥ���ʱ�򣬱���������֪�����ֵ�ģ����ʱ������ƶ�һ��ֻ�Ϳ����ˣ�ֻ�����ʱ��õ���mse��û��������)��
%kernel_test����ʾ���Լ������Ծ���
%model��������ѵ���õ���ģ�͡�
%libsvm_options������Ҫ���õ�һϵ�в�����

%�����
%predict_label����ʾ�õ��ı�ǩ��
%accuracy����һ��3*1�������������е�1���������ڷ������⣬��ʾ����׼ȷ�ʣ�
%�������������ڻع����⣬��2�����ֱ�ʾmse�����������ֱ�ʾƽ�����ϵ����Ҳ����˵���������Ļ�������һ�����־Ϳ����ˣ��ع�Ļ��������������֣�
%dec_values����ʾ����ֵ��һ�������ô�ã���




