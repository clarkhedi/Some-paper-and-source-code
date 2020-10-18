% classification script using SVM
%采用自定义的核函数

fprintf('\nClassification using histogram intersection kernel svm\n');
% load the BOW representations, the labels, and the train and test set
%载入数据
load(pg_opts.trainset);
load(pg_opts.testset);
load(pg_opts.labels);
load([pg_opts.globaldatapath,'/',assignment_opts.name])

train_labels    = labels(trainset);          % contains the labels of the trainset 240*1
train_data      = BOW(:,trainset)';          %转置 BOW:300*360   train_data:240*300   % contains the train data   
[train_labels,sindex]=sort(train_labels);    % we sort the labels to ensure that the first label is '1', the second '2' etc ‘1’到‘6’
train_data=train_data(sindex,:);
test_labels     = labels(testset);           % contains the labels of the testset
test_data       = BOW(:,testset)';           %120*300
%[B,IX] = sort(A,...)返回索引数组IX，其大小为size(IX) == size(A)。若A是一个向量，B = A(IX)。
% contains the test data

%% train kernal 这一步是给出训练集的核矩阵
kernel_train = hist_isect(train_data,train_data);       % 240*240 double
kernel_train = [(1:size(kernel_train,1))',kernel_train];%240*241 double 增加了1列;数是从1到240的1列
%想要使用-t 4参数还需要把样本的序列号放在核矩阵前面，形成一个新的矩阵，
%然后使用svmtrain建立支持向量机，再使用svmpredict进行预测即可。
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

%-s 0:svm类型是C-SVC；  -t 4:预定义核函数；   -c %f：惩罚因子；   -b 1：概率估计，是否计算SVC的概率估计；
%-g %f：设置核函数中gamma的值
options=sprintf('-s 0 -t 4 -c %f -b 1 -g %f -q',bestc,bestg);%bestc=200;bestg=2;
%model=svmtrain(train_labels, train_data,options);
model=svmtrain(train_labels,kernel_train,options);%使用svmtrain建立支持向量机，即利用训练集合建立分类模型
%[tmp svindex]=ismember(model.SVs, kernel_train,'rows');

% train_label：表示训练集的标签。
% train_matrix：表示训练集的属性矩阵。
% libsvm_options：是需要设置的一系列参数，各个参数可参见《libsvm 参数说明.txt》，里面介绍的很详细，中英文都有的。如果用回归的话，其中的-s参数值应为3。
% model:是训练得到的模型，是一个结构体（如果参数中用到-v，得到的就不是结构体，对于分类问题，得到的是交叉检验下的平均分类准确率；对于回归问题，得到的是均方误差）。

%% kernel test 这一步是给出测试集的核矩阵
kernel_test = hist_isect(test_data,train_data);%120*240 double
kernel_test = [(1:size(kernel_test,1))',kernel_test];%120*241 double

%[predict_label, accuracy , dec_values] = svmpredict(test_labels,test_data, model,'-b 1');
%预测测试集合标签  '-b 1'概率估计
[predict_label, accuracy , dec_values] = svmpredict(test_labels,kernel_test, model,'-b 1');
%输入：
%test_labels：表示测试集的标签(这个值可以不知道，因为作预测的时候，本来就是想知道这个值的，这个时候，随便制定一个只就可以了，只是这个时候得到的mse就没有意义了)。
%kernel_test：表示测试集的属性矩阵。
%model：是上面训练得到的模型。
%libsvm_options：是需要设置的一系列参数。

%输出：
%predict_label：表示得到的标签。
%accuracy：是一个3*1的列向量，其中第1个数字用于分类问题，表示分类准确率；
%后两个数字用于回归问题，第2个数字表示mse；第三个数字表示平方相关系数（也就是说，如果分类的话，看第一个数字就可以了；回归的话，看后两个数字）
%dec_values：表示决策值（一般好像不怎么用）。




