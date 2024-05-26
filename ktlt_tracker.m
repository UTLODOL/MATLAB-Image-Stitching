%%开始工作和特征点提取
clc;
clear all;
close all;
Image = cell(1,5);
Image{1} = imread("choosen_data/1.jpg");
Image{2} = imread("choosen_data/2.jpg");
Image{3} = imread("choosen_data/3.jpg");
Image{4} = imread("choosen_data/4.jpg");
Image{5} = imread("choosen_data/5.jpg");
I = cell(1,5);
points = cell(1,5);
figure
for i=1:2
    I{i}=rgb2gray(Image{i});
    points{i} = detectSIFTFeatures(I{i});
    subplot(2,1,i);
    imshow(I{i});
    hold on 
    plot(points{i}.selectStrongest(20))
end
%% 
features = cell(1,2);
for i=1:2
    points{i} = detectSURFFeatures(I{i});
    [features{i},points{i}] = extractFeatures(I{i}, points{i});
end
pair = matchFeatures(features{1},features{2},'Unique',true);
%%特征点提取
%%]
tforms = projective2d;
matchpoints = points{1}(pair(:,1),:);
previousmatichpoints =points{2}(pair(:,2),:);
figure 
showMatchedFeatures(I{1},I{2},matchpoints.selectStrongest(10),previousmatichpoints.selectStrongest(10));

%%计算变化矩阵和创建全景图像边框
%%
 [tform,inlierIdx]= estimateGeometricTransform2D(matchpoints,previousmatichpoints,"projective");
 tform.T = tforms.T*tform.T;
 panorama = zeros([4896 4896 3], 'like', Image{2});
 imshow(panorama);
%%创建全景图像
%%
blender = vision.AlphaBlender('Operation', 'Binary mask', ...
    'MaskSource', 'Input port');  
%%
imageSize =zeros(2,2);
imageSize(1,:)=size(I{1});
imageSize(2,:)=size(I{2});
[xlim,ylim]=outputLimits(tform,[1 imageSize(2,2)],[1,imageSize(2,1)]);
[xlims,ylims]=outputLimits(tforms,[1 imageSize(1,2)],[1,imageSize(1,1)]);
maxImageSize = max(imageSize);
xmin =min([1;xlim(:);xlims(:)]);
xmax =max([maxImageSize(1);xlim(:);xlims(:)]);
ymin =min([1;ylims(:);ylim(:)]);
ymax =max([maxImageSize(2);ylim(:);ylims(:)]);
width  = round(xmax - xmin);
height = round(ymax - ymin);
panorama = zeros([height width 3], 'like', Image{2});
imshow(panorama);
%%定义panorama 的具体2d空间
xLimits = [xmin xmax];
yLimits = [ymin ymax];
panoramaView = imref2d([height width], xLimits, yLimits);
%%
figure
subplot(1,2,1);
imshow(Image{1});

subplot(1,2,2);
imshow(Image{2});

figure
res=imwarp(Image{1},tform,'OutputView',panoramaView);
mask = imwarp(true(size(Image{1},1),size(Image{1},2)), tform, 'OutputView', panoramaView);
panorama =step(blender,panorama,res,mask);
res=imwarp(Image{2},tforms,'OutputView',panoramaView);
mask = imwarp(true(size(Image{2},1),size(Image{2},2)), tforms, 'OutputView', panoramaView);
panorama =step(blender,panorama,res,mask);
imshow(panorama);
