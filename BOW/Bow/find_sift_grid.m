function sift_arr = find_sift_grid(I, grid_x, grid_y, patch_size, sigma_edge)

% parameters
num_angles = 8;
num_bins = 4;
num_samples = num_bins * num_bins; %num_samples =4*4=16�����ӵ�
alpha = 9;

if nargin < 5 %nargin���������������
    sigma_edge = 1;
end

angle_step = 2 * pi / num_angles; % 2 * pi /8=0.7854 Ҫ�ֳ�8������
angles = 0:angle_step:2*pi; %[0,0.7854,1.5708,2.3562,3.1416,3.9270,4.7124,5.4978]
angles(num_angles+1) = []; % bin centers
%num_angles = 8��angles(8+1) = []
%����[0,0.7854,1.5708,2.3562,3.1416,3.9270,4.7124,5.4978]

[hgt wid] = size(I); %200*200
num_patches = numel(grid_x);  % number of.    numel(x)��ʾ��x*x
  %grid_x 24*24 double, num_patches =24*24=576��
sift_arr = zeros(num_patches, num_samples * num_angles); %4*4*8=128. 
  %sift_arr =576*128��0���� Ϊ��������׼��
[G_X,G_Y]=gen_dgauss(sigma_edge);%sigma_edge = 0.8  G_X��G_Y��5*5 double
%����һ��5*5��ģ�壬���ڼ����ݶ�ƫ�������˲���ģ�壬�˴����ɵ�ģ������sobel���ӣ�Ϊ�������I_X(�൱��gx)��I_Y(gy)��׼�� 

%ͼ��I����5*5��ģ���˲��󣬵õ��������ص���ݶ�ƫ����I_X��I_Y 
I_X = filter2(G_X, I, 'same'); % vertical edges  <200*200 double>  filter2():�����ά���������˲������뺯�� fspecial ����
I_Y = filter2(G_Y, I, 'same'); % horizontal edges  <200*200 double>
I_mag = sqrt(I_X.^2 + I_Y.^2); % gradient magnitude  <200*200 double> ���ݶȵķ�ֵ

I_theta = atan2(I_Y,I_X); %<200*200 double> ���ݶȵķ��� atan2()���������������������ķ�����ֵ���������صĽ����-�С���֮��Ļ���ֵ��

I_theta(find(isnan(I_theta))) = 0; % necessary???? 
%isnan(A)�ж������е�Ԫ���Ƿ�Ϊnan(not a number),isnan���������������г��ַ����ֵ����,��A��Ԫ��ΪNaN������ֵ�����ڶ�Ӧλ���Ϸ����߼�1���棩�����򷵻��߼�0���٣�

% make default grid of samples (centered at zero, width 2)�γ�4*4 ���ص�����
interval = 2/num_bins:2/num_bins:2; %4����[0.5000,1,1.5000,2]  num_bins=4
interval = interval - (1/num_bins + 1); %4����[-0.7500,-0.2500,0.2500,0.7500]  num_bins=4
[sample_x sample_y] = meshgrid(interval, interval); %sample_x <4*4 double>��sample_y <4*4 double>
                    %intervalΪһά���飬�����ĳ��ȵ����У�4�������У�4������γ�4*4�ľ���
sample_x = reshape(sample_x, [1 num_samples]); % change to array 1:16 <1*16 double> num_samples=16
sample_y = reshape(sample_y, [1 num_samples]); % change to array 1:16 <1*16 double>

% make orientation images ����ͼ
I_orientation = zeros(hgt, wid, num_angles);%I_orientation <200*200*8 double> num_angles=8 ȫ����0
% for each histogram angle 8������ֱ��ͼ

for a=1:num_angles    %num_angles=8 ѭ��8�Σ���Ϊ��8������
    % compute each orientation channel
    cos(I_theta - angles(a)); %<200*200 double>
    tmp = cos(I_theta - angles(a)).^alpha;%alpha=9 ÿ������9�η�
    tmp = tmp .* (tmp > 0);%<0��������
    %�����������ֵ����ÿ�����ص���ݶȷ���Ͷ�䵽8��������
    
    % weight by magnitude ����ÿ�����ص㷽���Ȩ��  I_orientation(:,:,0) ����0������ж���
    I_orientation(:,:,a) = tmp .* I_mag; %��ֵ�б仯  200*200*8 double
end

% for all patches     24*24=576��patches
for i=1:num_patches  %ѭ��576��
    r = patch_size/2;%patch_size=16  r=8
    cx = grid_x(i) + r - 0.5; %grid_x(1)=1 cx=8.5 patch�����ĺ�����
    cy = grid_y(i) + r - 0.5; %grid_y(1)=1 cy=8.5 patch������������

    % find coordinates of sample points (bin centers) ���ӵ������
    sample_x_t = sample_x * r + cx; %r=8 cx=8.5 ����ÿ��patch���������갴�����õ�bin��������
    sample_y_t = sample_y * r + cy;
    sample_res = sample_y_t(2) - sample_y_t(1); %������������bin���ĵļ�� ֮ǰ��0.5��������0.5*8=4    
    % find window of pixels that contributes to this descriptor
    %�γ�16*16��patch
    x_lo = grid_x(i);%1 i=1ʱ
    x_hi = grid_x(i) + patch_size - 1;%16 �ȼ���x���򣬼���������
    y_lo = grid_y(i);%1
    y_hi = grid_y(i) + patch_size - 1;%16
    
    % find coordinates of pixels һ��patch�е�ÿ�����ص�����  ÿ��patch��16*16=256�����ص�
    [sample_px, sample_py] = meshgrid(x_lo:x_hi,y_lo:y_hi);%1��16 sample_px��16*16 double
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
        
    % make sift descriptor ��ȡsift����
    curr_sift = zeros(num_angles, num_samples);%8*16��0���� ͳ��16�����ӵ��8������
    for a = 1:num_angles %1��8 ѭ��8�Σ�8������
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
	f_wid = 4 * ceil(sigma) + 1; %f_wid=5  ceil(value):����һ����С��value����С����
    G = fspecial('gaussian', f_wid, sigma); %����һ��5x5�Ķ�ά��˹�˲�
%	G = normpdf(-f_wid:f_wid,0,sigma);
%	G = G' * G;
else
    % anisotropic gaussian
    f_wid_x = 2 * ceil(sigma(1)) + 1;
    f_wid_y = 2 * ceil(sigma(2)) + 1;
    G_x = normpdf(-f_wid_x:f_wid_x,0,sigma(1));%normpdf()������ܶȺ���
    G_y = normpdf(-f_wid_y:f_wid_y,0,sigma(2));
    G = G_y' * G_x;
end

function [GX,GY]=gen_dgauss(sigma)

% laplacian of size sigma
%f_wid = 4 * floor(sigma);
%G = normpdf(-f_wid:f_wid,0,sigma);
%G = G' * G;
G = gen_gauss(sigma);
[GX,GY] = gradient(G); %���ݶ�

GX = GX * 2 ./ sum(sum(abs(GX))); % colum sum and all sum
GY = GY * 2 ./ sum(sum(abs(GY)));

