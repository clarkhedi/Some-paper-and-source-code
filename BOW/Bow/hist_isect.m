function K = hist_isect(x1, x2)

% Evaluate a histogram intersection kernel, for example
%评估直方图相交核
%    K = hist_isect(x1, x2);
%
% where x1 and x2 are matrices containing input vectors, where 
% each row represents a single vector.
% If x1 is a matrix of size m x o and x2 is of size n x o,
% the output K is a matrix of size m x n.

n = size(x2,1);%获取矩阵x2的行数
m = size(x1,1);
K = zeros(m,n);%m*n的0矩阵
if (m <= n)
   for p = 1:m
       nonzero_ind = find(x1(p,:)>0);%寻找矩阵x1中第p行中大于0的元素的列序号
       tmp_x1 = repmat(x1(p,nonzero_ind), [n 1]); %n为矩阵x2的行数
       K(p,:) = sum(min(tmp_x1,x2(:,nonzero_ind)),2)';
   end %sum(,2)对一行内的数字求和
else
   for p = 1:n
       nonzero_ind = find(x2(p,:)>0);
       tmp_x2 = repmat(x2(p,nonzero_ind), [m 1]);
       K(:,p) = sum(min(x1(:,nonzero_ind),tmp_x2),2);
   end
end


