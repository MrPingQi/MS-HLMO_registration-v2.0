%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Gao Chenzhong
% Contact: gao-pingqi@qq.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function keypoint = ShiTomasi(I, scale, thresh, radius)

hx = [-1,0,1;-2,0,2;-1,0,1]; % 一阶梯度 Sobel算子
hy = hx';
Gx = imfilter(I, hx, 'replicate');
Gy = imfilter(I, hy, 'replicate');

W = floor(scale/2); % 窗半径
dx = -W : W; % 邻域x坐标
dy = -W : W; % 邻域y坐标
[dx,dy] = meshgrid(dx,dy);
Wcircle = ((dx.^2 + dy.^2) < (W+1)^2)*1.0; % 圆形窗
h = fspecial('gaussian',[scale+1,scale+1], scale/6).*Wcircle;
Gxx = conv2(Gx.*Gx, h, 'same');
Gyy = conv2(Gy.*Gy, h, 'same');
Gxy = conv2(Gx.*Gy, h, 'same');

cornerness = zeros(size(I,1),size(I,2));
for i=1:size(I,1)
    for j=1:size(I,2)
        M = [Gxx(i,j),Gxy(i,j);Gxy(i,j),Gyy(i,j)];
        [cornerness(i,j),~] = min(eig(M));
    end
end
cornerness([1:1+W,end-W:end],:) = 0;
cornerness(:,[1:1+W,end-W:end]) = 0;

% Nonmaximal suppression and threshold
if nargin > 2
    sze = 2*radius+1;                                  % Size of mask
	mx = ordfilt2(cornerness,sze^2,ones(sze));         % Grey-scale dilate
	cornerness_t = (cornerness==mx)&(cornerness>thresh); % Find maxima
	[rows,cols] = find(cornerness_t);                    % Find row,col coords.
    cornerness = cornerness(sub2ind(size(cornerness),rows,cols));
    keypoint = [cols, rows, cornerness];
else
    keypoint = [];
end