%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Gao Chenzhong
% Contact: gao-pingqi@qq.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; clear; clc;

%% Is there any obvious intensity difference (multi-modal)
int_flag = 1; % true:1, false:0
%% Is there any obvious rotation difference
rot_flag = 1;
%% Is there any obvious scale difference
scl_flag = 1;
%% Do you want parallel computing in multi-scale strategy
par_flag = 0;
%% What kind of feature point do you want as the keypoint
type = 'Harris'; % Harris, Shi-Tomasi
%% What spatial transformation model do you need at the end
trans = 'affine'; % similarity, affine, projective
%% What transformation model do you need at the end
form = 'union'; % union, inter, ref

%% Parameters
G_resize = 2;  % 高斯金字塔的降采样单元，默认：2
nOctaves_1 = 3; nOctaves_2 = 3; % 高斯金字塔的组数，默认：3
G_sigma = 1.6; % 高斯金字塔的模糊单元，默认：1.6
nLayers = 4;   % 高斯金字塔每组层数，默认：4
thresh = 50;   % 角点响应判别阈值，默认：50
radius = 5;    % 局部非极大值抑制窗半径，默认：5、2、1
N = 2000;      % 特征点数量择优阈值，默认：2000
patch_size = 96; % GGLOH尺寸，默认：96
NBS = 12;    % GGLOH空间划分，默认：12
NBO = 12;    % GGLOH角度划分，默认：12
Error = 5;
K = 1;

%% Images input and preproscessing
[image_1, image_2] = Readimage;
[I1_o,I1_s,I1,r1,I2_o,I2_s,I2,r2] = Preproscessing(image_1,image_2,radius);
figure,imshow(I1_s),title('Reference image');
figure,imshow(I2_s),title('Sensed Image');

warning off
fprintf('\n** Registration starts, have fun\n\n'); ts=cputime; tic

%% Keypoints Detection
keypoints_1 = Detect_Keypoint(I1,6,thresh,r1,N,nOctaves_1,G_resize,type);
str=['Done: Keypoints detection of reference image, time cost: ',num2str(toc),'s\n']; fprintf(str); tic
keypoints_2 = Detect_Keypoint(I2,6,thresh,r2,N,nOctaves_2,G_resize,type);
str=['Done: Keypoints detection of image to be registered, time cost: ',num2str(toc),'s\n\n']; fprintf(str); tic
figure,imshow(I1_s); hold on; plot(keypoints_1(:,1),keypoints_1(:,2),'r+');
figure,imshow(I2_s); hold on; plot(keypoints_2(:,1),keypoints_2(:,2),'r+');

%% Keypoints Description
descriptors_1 = Multiscale_Descriptor(I1,keypoints_1,patch_size,NBS,NBO,...
    nOctaves_1,nLayers,G_resize,G_sigma,int_flag,rot_flag);
str=['Done: Keypoints description of reference image, time cost: ',num2str(toc),'s\n']; fprintf(str); tic
descriptors_2 = Multiscale_Descriptor(I2,keypoints_2,patch_size,NBS,NBO,...
    nOctaves_2,nLayers,G_resize,G_sigma,int_flag,rot_flag);
str=['Done: Keypoints description of image to be registered, time cost: ',num2str(toc),'s\n\n']; fprintf(str); tic

%% Keypoints Matching
[cor1,cor2] = Matching_Process(descriptors_1,descriptors_2,...
    nOctaves_1,nOctaves_2,nLayers,scl_flag,par_flag,K,Error);
str = ['Done: Keypoints matching, time cost: ',num2str(toc),'s\n']; fprintf(str);
matchment = Show_Matches(I1_s,I2_s,cor1,cor2,1); tic

%% Image transforming
switch form
    case 'union'
        [I1_r,I2_r,I1_rs,I2_rs,I3,I4] = Transformation_union(I1_o,I2_o,...
            cor1,cor2,trans);
    case 'inter'
        [I1_r,I2_r,I1_rs,I2_rs,I3,I4] = Transformation_inter(I1_o,I2_o,...
            cor1,cor2,trans);
    case 'ref'
        [I2_r,I2_rs,I3,I4] = Transformation_ref(I1_o,I2_o,...
            cor1,cor2,trans);
    otherwise 
        assert(false,'Unexpected Transfomation Type encountered.');
end
str=['Done: Image tranformation, time cost: ',num2str(toc),'s\n\n']; fprintf(str); tic

%% Time and Result
te=cputime-ts;
str=['** Done: Image registration, time cost: ',num2str(te),'s\n']; fprintf(str);
figure; imshow(I3,[]); title('Fusion Form');
figure; imshow(I4,[]); title('Checkerboard Form'); 

%% Save images
if (exist('save_image','dir')==0)
    mkdir('save_image');
end
Date = datestr(now,'yyyy-mm-dd_HH-MM-SS__');
correspond = cell(2,1); correspond{1} = cor1; correspond{2} = cor2;
str=['.\save_image\',Date,'0 correspond','.mat']; save(str,'correspond')
str=['.\save_image\',Date,'1 Matching Result','.jpg']; saveas(matchment,str);
switch form
    case 'Reference'
        str=['.\save_image\',Date,'2 Reference Image','.mat']; save(str,'I1_o');
        str=['.\save_image\',Date,'4 Reference Image','.jpg']; imwrite(I1_s,str);
    otherwise
        str=['.\save_image\',Date,'2 Reference Image','.mat']; save(str,'I1_r');
        str=['.\save_image\',Date,'4 Reference Image','.jpg']; imwrite(I1_rs,str);
end
str=['.\save_image\',Date,'3 Registered Image','.mat']; save(str,'I2_r');
str=['.\save_image\',Date,'5 Registered Image','.jpg']; imwrite(I2_rs,str);
str=['.\save_image\',Date,'6 Fusion of results','.jpg']; imwrite(I3,str);
str=['.\save_image\',Date,'7 Checkerboard of results','.jpg']; imwrite(I4,str);
str='The registration results are saved in the save_image folder.\n\n'; fprintf(str);