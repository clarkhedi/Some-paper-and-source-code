function sift_arr = find_sift_grid(I, grid_x, grid_y, patch_size, sigma_edge)

% parameters
num_angles = 8;
num_bins = 4;
num_samples = num_bins * num_bins; %num_samples =4*4=16个种子点
alpha = 9;

if nargin < 5 %nargin：函数输入变量数
    sigma_edge = 1;
end

angle_step = 2 * pi / num_angles; % 2 * pi /8=0.7854 要分成8个方向
angles = 0:angle_step:2*pi; %[0,0.7854,1.5708,2.3562,3.1416,3.9270,4.7124,5.4978]
angles(num_angles+1) = []; % bin centers
%num_angles = 8，angles(8+1) = []
%还是[0,0.7854,1.5708,2.3562,3.1416,3.9270,4.7124,5.4978]

[hgt wid] = size(I); %200*200
num_patches = numel(grid_x);  % number of.    numel(x)表示求x*x
  %grid_x 24*24 double, num_patches =24*24=576个
sift_arr = zeros(num_patches, num_samples * num_angles); %4*4*8=128. 
  %sift_arr =576*128的0矩阵 为存数据做准备
[G_X,G_Y]=gen_dgauss(sigma_edge);%sigma_edge = 0.8  G_X，G_Y：5*5 double
%生成一个5*5的模板，用于计算梯度偏导数的滤波器模板，此处生成的模板类似sobel算子，为下面计算I_X(相当于gx)和I_Y(gy)做准备 

%图像I经过5*5的模板滤波后，得到各个像素点的梯度偏导数I_X和I_Y 
I_X = filter2(G_X, I, 'same'); % vertical edges  <200*200 double>  filter2():计算二维线型数字滤波，它与函数 fspecial 连用
I_Y = filter2(G_Y, I, 'same'); % horizontal edges  <200*200 double>
I_mag = sqrt(I_X.^2 + I_Y.^2); % gradient magnitude  <200*200 double> 求梯度的幅值

I_theta = atan2(I_Y,I_X); %<200*200 double> 求梯度的幅角 atan2()计算给定横坐标和纵坐标点的反正切值。函数返回的结果是-π～π之间的弧度值。

I_theta(find(isnan(I_theta))) = 0; % necessary???? 
%isnan(A)判断数组中的元素是否为nan(not a number),isnan常用来修正数组中出现非数字的情况,若A的元素为NaN（非数值），在对应位置上返回逻辑1（真），否则返回逻辑0（假）

% make default grid of samples (centered at zero, width 2)形成4*4 像素的网格
interval = 2/num_bins:2/num_bins:2; %4个数[0.5000,1,1.5000,2]  num_bins=4
interval = interval - (1/num_bins + 1); %4个数[-0.7500,-0.2500,0.2500,0.7500]  num_bins=4
[sample_x sample_y] = meshgrid(interval, interval); %sample_x <4*4 double>，sample_y <4*4 double>
                    %interval为一维数组，用它的长度当作列：4、当作行：4，最后形成4*4的矩阵
sample_x = reshape(sample_x, [1 num_samples]); % change to array 1:16 <1*16 double> num_samples=16
sample_y = reshape(sample_y, [1 num_samples]); % change to array 1:16 <1*16 double>

% make orientation images 方向图
I_orientation = zeros(hgt, wid, num_angles);%I_orientation <200*200*8 double> num_angles=8 全部是0
% for each histogram angle 8个方向直方图

for a=1:num_angles    %num_angles=8 循环8次，因为是8个方向
    % compute each orientation channel
    cos(I_theta - angles(a)); %<200*200 double>
    tmp = cos(I_theta - angles(a)).^alpha;%alpha=9 每个数的9次方
    tmp = tmp .* (tmp > 0);%<0的数置零
    %计算各个余弦值，将每个像素点的梯度方向投射到8个方向上
    
    % weight by magnitude 计算每个像素点方向的权重  I_orientation(:,:,0) 落在0方向的有多少
    I_orientation(:,:,a) = tmp .* I_mag; %数值有变化  200*200*8 double
end

% for all patches     24*24=576个patches
for i=1:num_patches  %循环576次
    r = patch_size/2;%patch_size=16  r=8
    cx = grid_x(i) + r - 0.5; %grid_x(1)=1 cx=8.5 patch的中心横坐标
    cy = grid_y(i) + r - 0.5; %grid_y(1)=1 cy=8.5 patch的中心纵坐标

    % find coordinates of sample points (bin centers) 种子点的坐标
    sample_x_t = sample_x * r + cx; %r=8 cx=8.5 根据每个patch的中心坐标按比例得到bin中心坐标
    sample_y_t = sample_y * r + cy;
    sample_res = sample_y_t(2) - sample_y_t(1); %按比例扩大后的bin中心的间隔 之前是0.5，现在是0.5*8=4    
    % find window of pixels that contributes to this descriptor
    %形成16*16的patch
    x_lo = grid_x(i);%1 i=1时
    x_hi = grid_x(i) + patch_size - 1;%16 先计算x方向，即从左往右
    y_lo = grid_y(i);%1
    y_hi = grid_y(i) + patch_size - 1;%16
    
    % find coordinates of pixels 一个patch中的每个像素的坐标  每个patch有16*16=256个像素点
    [sample_px, sample_py] = meshgrid(x_lo:x_hi,y_lo:y_hi);%1：16 sample_px：16*16 double
    num_pix = numel(sample_px);%16*16=256
    sample_px = reshape(sample_px, [num_pix 1]);%256*1
    sample_py = reshape(sample_py, [num_pix 1]);%256*1
        
    % find (horiz, vert) distance between each pixel and each grid sample
    dist_px = abs(repmat(sample_px, [1 num_samples]) - repmat(sample_x_t, [num_pix 1])); %256*16
    dist_py = abs(repmat(sample_py, [1 num_samples]) - repmat(sample_y_t, [num_pix 1])); %256*16
    
    % find weight of contribution of each pixel to each bin    
    weights_x = dist_px/sample_res;%256*16
    weights_x = (1 - weights_x) .* (weights_x <= 1);%256*16
    weights_y = dist_py/sample_res;%256*16
    weights_y = (1 - weights_y) .* (weights_y <= 1);%256*16
    weights = weights_x .* weights_y;%256*16
%     % make sure that the weights for each pixel sum to one?
%     tmp = sum(weights,2);
%     tmp = tmp + (tmp == 0);
%     weights = weights ./ repmat(tmp, [1 num_samples]);
        
    % make sift descriptor 提取sift特征
    curr_sift = zeros(num_angles, num_samples);%8*16的0矩阵 统计16个种子点的8个方向
    for a = 1:num_angles %1：8 循环8次，8个方向
        tmp = reshape(I_orientation(y_lo:y_hi,x_lo:x_hi,a),[num_pix 1]); %256*1       
        tmp = repmat(tmp, [1 num_samples]);%256*16
        curr_sift(a,:) = sum(tmp .* weights);
    end %curr_sift:8*16
    sift_arr(i,:) = reshape(curr_sift, [1 num_samples * num_angles]); %576*128
     
%     % visualization
%     if sigma_edge >= 3
%         subplot(1,2,1);
%         rescale_and_imshow(I(y_lo:y_hi,x_lo:x_hi) .* reshape(sum(weights,2), [y_hi-y_lo+1,x_hi-x_lo+1]));
%         subplot(1,2,2);
%         rescale_and_imshow(curr_sift);
%         pause;
%     end
end

function G=gen_gauss(sigma)

if all(size(sigma)==[1, 1])
    % isotropic gaussian
	f_wid = 4 * ceil(sigma) + 1; %f_wid=5  ceil(value):返回一个不小于value的最小整数
    G = fspecial('gaussian', f_wid, sigma); %创建一个5x5的二维高斯滤波
%	G = normpdf(-f_wid:f_wid,0,sigma);
%	G = G' * G;
else
    % anisotropic gaussian
    f_wid_x = 2 * ceil(sigma(1)) + 1;
    f_wid_y = 2 * ceil(sigma(2)) + 1;
    G_x = normpdf(-f_wid_x:f_wid_x,0,sigma(1));%normpdf()求概率密度函数
    G_y = normpdf(-f_wid_y:f_wid_y,0,sigma(2));
    G = G_y' * G_x;
end

function [GX,GY]=gen_dgauss(sigma)

% laplacian of size sigma
%f_wid = 4 * floor(sigma);
%G = normpdf(-f_wid:f_wid,0,sigma);
%G = G' * G;
G = gen_gauss(sigma);
[GX,GY] = gradient(G); %求梯度

GX = GX * 2 ./ sum(sum(abs(GX))); % colum sum and all sum
GY = GY * 2 ./ sum(sum(abs(GY)));

