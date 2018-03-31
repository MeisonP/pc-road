function  [cluster,arrows] = vectorizearrow(cluster)
%
% ��ͷ����ʶ��
% [cluster,breakLines] = vectorizearrow(cluster)
% INPUT:
% cluster - ���Ƶľ���
% 
% OUTPUT:
% cluster - �����ĵ��ƾ��࣬��ʱ���á�
% arrows  - ��һ���Ǽ�ͷ��cluster�е������ţ��ڶ����Ƕ�Ӧ��ͷ�����

readtemplate();
nc = size(cluster,2);
if ~isfield(cluster,'center')
    cluster = getclusterinfo(cluster);
end
types = [];
breakLines = [];
for i = 1:nc
    c = cluster(i);
%         if i>=553
%             plot(c.data(:,1),c.data(:,2),'.');axis equal;
%             type = matchingarrow(c);
%               
%         end
%         continue;
    type = matchingarrow(c);
    if type~=0
        breakLines = [breakLines;i];
        types = [types;type];
    end
    if type~=0
        data = c.data;
      figure(1); plot(data(:,1),data(:,2),'k.');hold on;
    end
end
arrows = [breakLines types];
end

function type = matchingarrow(cluster)
%
% ��ͷ���߼��

global template;
w = cluster.length;
h = cluster.width;
% ����߳ߴ���Զ��ֱ���ų���
if (w>6.2)||(w<5)||(h<0.3)||(h>2.4)
    type =  0;
    return;
else
    %���ɵ���Ӱ���Ĭ�ϲ�����
    pixelsize = 0.05;
    buffersize = 0.2;
    if cluster.density<100
        buffersize = 4/cluster.density;
    end
    
    [imageData,~] = convertPD2img(cluster.data,pixelsize,buffersize,true);
    imageData(~isnan(imageData)) = 1;
    imageData(imageData~=1) = 0;
    
    se = strel('diamond',2);
    imageData = imclose(imageData,se);
    imageData= imfill(imageData,'holes');% ��׶�
end
% figure(2);imshow(imageData);

% Ӱ��ʶ���ʺʹ����ٶȵ�ԭ����Ҫ�Ǳ���ȱ���������ȱ����ٵĻ�����Ч�����ǿ��Ե�
[type,T,imageData] = findmostmatchbyskel(imageData,0.01/pixelsize);
if type
    % ����Ԥ����ʹģ����ƥ��ͼ���С��λ��һ��
    [tI,mI] =  preprocimage(abs(imresize(template{type}, 0.01/pixelsize)),imageData,T);
    % ƥ��
    [regist_perct,defect_perct,exceed_perct,defect_area,exceed_area] =  matching(tI,mI);
    if ~analysispara(type,regist_perct,defect_perct,exceed_perct,defect_area,exceed_area)
        type = 0;
    end
end
end

function isMatched = analysispara(type,regist_perct,defect_perct,exceed_perct,defect_area,exceed_area)
%
% �Խ���������з����������жϱ������

isMatched = false;
r07 = (regist_perct>0.7);
r06 = (regist_perct>0.6);
r05 = (regist_perct>0.5);
d05 = (defect_perct<0.5);
d03 = (defect_perct<0.3);
d01 = (defect_perct<0.1);
e01 = (exceed_perct<0.1);
e005 = (exceed_perct<0.05);
e001 = (exceed_perct<0.015);
if r07||(r06&&e01)||(r05&&e001)
    isMatched = true;
end
end

function  [regist_perct,defect_perct,exceed_perct,defect_area,exceed_area]...
    = matching(tImage,image)
%
%�������΢����Ҫ���ƥ��ͼ����ģ���Сһ�£����ܽ��оֲ�ƥ��ʶ��

% figure(1);imshow(tImage);
% figure(2);imshow(image);
% figure(1);imshow(tImage + image);
[h,w] = size(image);
image2 = imrotate(image,180);
d = sum(sum((tImage - image).^2 - (tImage - image2).^2));
% figure(1);imshow(image);
% figure(2);imshow(image2);
% figure(3);imshow(tImage);

% ȷ��ƥ�䷽��
if d<0
    image3 = image;
else
    image3 = image2;
end

%--------------------------------------------------------------------------
% �Ǽ�ƥ���Ѿ�����ƥ����ˣ������ٴν����ݡ��ᡢ��תƥ���Ƿ��б�Ҫ��
tmp = zeros([h,w]);
r = 10;%��10�������ڽ���΢��ƥ��
% ����������ƥ��λ��
for i = 0:r
    image_moveY1 = tmp;
    image_moveY2 = tmp;
    image_moveY1(1:end-i,:) = image(i+1:end,:);
    image_moveY2(i+1:end,:) = image(1:end-i,:);
    dImage = tImage - image_moveY1;
    dImage2 =tImage - image_moveY2;
    d(i+1,1) =  sum(sum(dImage.^2));
    d2(i+1,1) =  sum(sum(dImage2.^2));   
%     figure(1);imshow(tImage + image_moveY1);
%     figure(2);imshow(tImage + image_moveY2);
end 
[d_sort,idx] = sortrows([d;d2]);
pan_y = mod(idx(1),r+1)-1;%��������ƽ����
if pan_y<0
    pan_y = pan_y+r+1;
end
image_moveY = tmp;
if idx(1)<=r+1
    image_moveY(1:end-pan_y,:) = image(pan_y+1:end,:);
else
    image_moveY(pan_y+1:end,:) = image(1:end-pan_y,:);
end

% ���������ƥ��λ��
image = image_moveY;
for i = 0:r
    image_moveX1 = tmp;
    image_moveX2 = tmp;
    image_moveX1(:,1:end-i) = image(:,i+1:end);
    image_moveX2(:,i+1:end) = image(:,1:end-i);
    dImage = tImage - image_moveX1;
    dImage2 =tImage - image_moveX2;
    d(i+1,1) =  sum(sum(dImage.^2));
    d2(i+1,1) =  sum(sum(dImage2.^2));  
%         figure(1);imshow(tImage + image_moveX1);
%         figure(2);imshow(tImage + image_moveX2);
end
[d_sort,idx] = sortrows([d;d2]);
pan_x = mod(idx(1),r+1)-1;%���غ���ƽ����
if pan_x<0
    pan_x = pan_x+r+1;
end
image_moveX = tmp;
if idx(1)<=r+1
    image_moveX(:,1:end-pan_x) = image(:,pan_x+1:end);
else
    image_moveX(:,pan_x+1:end) = image(:,1:end-pan_x);
end
%--------------------------------------------------------------------------
 
%�����ת���ƥ��λ��
image = image_moveX;
tImage_area =  sum(sum(tImage));%ģ���������
rotateA = 10;%��ת�Ƕȷ�Χ
for i = -rotateA:rotateA
    image_rotate = imrotate(image,i);%��ת����Ϊͼ������
    [rh,rw] = size(image_rotate);
    mh = max([h rh]);
    mw = max([w rw]);
    tImage_ = zeros(mh,mw);% ��ƥ��ģ��
    tMatch_ = zeros(mh,mw);% ��ƥ��ͼ��
    tImage_(ceil(mh/2-h/2+1):ceil(mh/2+h/2),ceil(mw/2-w/2+1):ceil(mw/2+w/2)) = tImage ;
    tMatch_(ceil(mh/2-rh/2+1):ceil(mh/2+rh/2),ceil(mw/2-rw/2+1):ceil(mw/2+rw/2)) = image_rotate;
    
    dImage = tImage_ - tMatch_;
%     figure(5);imshow(tMatch_);
%     figure(6);imshow(tImage_);
%     figure(3);imshow(tMatch_ + tImage_);

    defect_area(i+rotateA+1,1) = sum(dImage(dImage>0));% ��ƥ��ͼ�����ģ��ȱ����������
    exceed_area(i+rotateA+1,1) = abs(sum(dImage(dImage<0)));% ��ƥ��ͼ�����ģ������������
    d4(i+rotateA+1,1) =  sum(sum(dImage.^2));
end
defect_perct = defect_area./tImage_area;
exceed_perct = exceed_area./tImage_area;
regist_perct = 1-(defect_perct+exceed_perct);
% �ҳ����ֵ
defect_area = min(defect_area);
exceed_area = min(exceed_area);
defect_perct = min(defect_perct);
exceed_perct = min(exceed_perct);
[regist_perct,idx] = max(regist_perct);
rA = idx-rotateA-1;
end

function [tI,mI] =  preprocimage(templateImage,matchImage,T)
% 
% ������ת����ģ�����ƥ��ͼ���������Ѵ�С��λ��
% [tI,mI] =  preprocimage(templateImage,matchImage,T)
% INPUT��
% templateImage - ģ��ͼ��
% matchImage -��ƥ��ͼ��
% T - ��ת����
%
% OUTPUT:
% tI - ������С���ģ��ͼ��
% mI - ������С������λ�ú�Ĵ�ƥ��ͼ��

% %����ת����ƽ��
% paraR = T(1:2,1:2);%��ת����
% paraM = T(4,1:2);%ƽ�Ʋ���
%����ֵͼ��ת��Ϊ������
[my2,mx2] = find(matchImage>0);
[ty2,tx2] = find(templateImage>0);

% ����ת��
transXY = [mx2 my2 zeros(size(mx2,1),1) ones(size(mx2,1),1)]*T;

% ȷ��ͳһ�߽磬ʹ�ɵ������ɵ�ͼ���Сλ��һ��
minX = min([min(transXY(:,1)) min(tx2)])-1;
minY = min([min(transXY(:,2)) min(ty2)])-1;
mx3 = transXY(:,1) - minX;
my3 = transXY(:,2) - minY;
tx3 = tx2 - minX;
ty3 = ty2 - minY;
maxX = max([max(mx3) max(tx3)]);
maxY = max([max(my3) max(ty3)]);
tmp = zeros([ceil(maxY) ceil(maxX)]);% ͼ���С
tI = tmp;
mI = tmp;
% ����ת����T�����ͼ��
tI(sub2ind(size(tI),ceil(ty3),ceil(tx3)))=1;
mI(sub2ind(size(mI),ceil(my3),ceil(mx3)))=1;
mI = imclose(mI,strel('diamond',1));% I2��������ת�����ɵ�ͼ������е����ؿն�
end

function  [tform,skelRate] =  matchingskel(MovingPcd,fixedPcd)
%
% �Ǽܵ���ƥ��
% [tform,skelRate] =  matchingskel(MovingPcd,fixedPcd)
% INPUT��
% MovingPcd - �ƶ����ƣ�����ͼ��ʱ���Ʒ�����ת
% fixedPcd - �̶����ƣ�����ͼ��ʱ���Ʋ�������ת
%
% OUTPUT��
% tform - ��MovingPcdƥ�䵽fixedPcd����ת����
% skelRate - MovingPcd��fixedPcd��ƥ�����
%
% ����ʹ�õ�����ά���Ƶ�ICP�㷨��ƥ��ʱ���ܷ���������ת����ƥ�����Ӧ�øĳɶ�άICP
%ICP�㷨�Գ�ʼλ����һ�������ԣ��ǶȲ���������ʹƥ������β�ߵ�,Ӧ��0��180��ƥ������ȡ��С
%������������1����ƥ���ͼ�����ƥ���ˣ�2��ƥ���ͼ���ʼ��������Ƕȣ�����ʹ�����ʾ��ƥ��
%--------------------------------------------------------------------------
%ICP�㷨�ٶ�һ���㼯����һ���㼯���Ӽ�������ģ����ƿ��Կ���ȫ����
%ICP�㷨Ҫȡ�úõĽ��Ҫ�������㼯��ʼλ���ǽ��ƶ���ģ����Է�����������㼯��
%�Ȼ�����������ʹ����ƥ�������󣬲������ڱ���ͼ�����ɵĵ��ƶ���һ�����η�
%Χ�ڣ����Խ���ƥ��ʱ�ǶȲ���0�Ⱥ�180�ȸ�����ֻ����0��180�������������ICPȡ��
%���С�Ľ�����ɣ�
%ICP�Գ�ʼλ������ԭ���������ŷʽ����ȷ����Ӧ�㣬������ϵģ���Ӧ��Ĳ�׼ȷ��
%��������ƥ�䲻�����������󡣽��ICPȷ����Ӧ��ķ�ʽ�����Կ�������ƥ��ʱ��ʼλ
%���������ϴ��ǵ���ƥ��ʧ�ܵ�ԭ�򣬽Ƕ�Ҳ����Ϊ��ת��������������Ӷ�Ӱ��ƥ
%��Ч����
%--------------------------------------------------------------------------
if (2==size(fixedPcd,2))
    fixedPcd = [fixedPcd zeros([size(fixedPcd,1) 1])];
end
if (2==size(MovingPcd,2))
    MovingPcd = [MovingPcd zeros([size(MovingPcd,1) 1])];%������ά�Ǽܵ���
end

% plot(MovingPcd(:,1),MovingPcd(:,2),'r.');axis equal;hold on;
% plot(fixedPcd(:,1),fixedPcd(:,2),'b.');axis equal;hold on;

[tform,movingReg] = pcregrigid(pointCloud(MovingPcd),pointCloud(fixedPcd));
matchedPcd = movingReg.Location;
tform = tform.T;
% �Ǽ�ƥ���
Mdl = KDTreeSearcher(fixedPcd(:,1:2));
[Idx,D] = knnsearch(Mdl,matchedPcd(:,1:2));
skelRate1 = sqrt(sum(D.*D)/size(Idx,1));%�����������ƥ���,��λ������

Mdl = KDTreeSearcher(matchedPcd(:,1:2));
[Idx,D] = knnsearch(Mdl,fixedPcd(:,1:2));
skelRate2 = sqrt(sum(D.*D)/size(Idx,1));% ģ�嵽��ƥ��ͼ��ĹǼ����
skelRate = [skelRate1;skelRate2];
end

function [type,T,image] =  findmostmatchbyskel(image,scale)
%
% ͨ��Ӱ�����ɵĹǼ�ȷ�����������Ƶı���ģ��
% [type,T,image] =  findmostmatchbyskel(image,scale)
% INPUT��
% image - �����ĵ��ƾ���Ӱ��
% scale - image�����س߶ȣ�����ģ���ǰ�1cm/px���ɵģ�image��2cm/pc,��ͬ����С
%         ��image�߶���ģ���һ�룬��scale=0.5
%
% OUTPUT ��
% type - ƥ�����ģ�����ͱ��
% T - Ӱ����ģ�����ƥ��ʱimage�ı任����ͨ��T���Խ�Ӱ����ģ����ƶ���
% image - ������Ӱ�죬��ʱ��������



% 0.01mһ���������ɵ�ͼ����Ҫ����40�εõ��Ǽܣ�����Խ��������������Խ����
% ʹ��'shrink'�����Ǽܻ��ᵼ�¶˵�һ���̶���������ʵӦ��ʹ��'skel'��Ȼ����ȥ��֦
% 辵õ��Ǹɣ�����ȥ��֦辵��㷨�÷ѵ㹦��
mSkel = bwmorph(image,'shrink',40*scale); %�Ǽܻ�
% mSkel = bwmorph(image,'skel',inf); 

[my,mx] = find(imrotate(mSkel,0)>0);%��ά�Ǽܵ�
% figure(2);imshow(mSkel);

%ȥ����Ⱥ�㣬��Ⱥ���п����Ǵ����
TT = clustereuclid([mx my],5);
[C,~,ic] = unique(TT);
tmpy = [];
tmpx = [];
rN = 4;%ȥ������4�����
for i=1:size(C,1)
   idx =  find(ic==C(i));
%    plot(mx(idx),my(idx),'o','Color',[rand rand rand]);axis equal;hold on
   if size(idx,1)>rN 
       tmpx = [tmpx;mx(idx)];
       tmpy = [tmpy;my(idx)];
   end
end
% plot(mx,my,'b.');axis equal; hold on;
mx = tmpx;
my = tmpy;
% plot(mx,my,'r.');axis equal;

if isempty(mx)
    type = 0;
    T = eye(4);
    return;
end

matchPcd = [mx my zeros([size(mx,1) 1])];%������ά�Ǽܵ���;
% figure(1);imshow(mSkel);
% figure(2);imshow(image);
[type,T] =  findmostmatchbyskelpcd(matchPcd,scale);
if type
     return;%����Ѿ�ƥ��ɹ���������ת180�ȼ��
end
matchPcd2 = pcdroateXY(matchPcd,[mean(mx) mean(my)],180);
[type,T] =  findmostmatchbyskelpcd(matchPcd2,scale);
image = imrotate(image,180);
end

function [type,T] =  findmostmatchbyskelpcd(matchPcd,scale)
%
% ͨ���Ǽܵ���ƥ�����������Ƶı���ģ��
% [type,T] =  findmostmatchbyskelpcd(matchPcd,scale)
% INPUT��
% matchPcd - ��ƥ��ĹǼܵ���
% scale - image�����س߶ȣ�����ģ���ǰ�1cm/px���ɵģ�image��2cm/pc,��ͬ����С
%         ��image�߶���ģ���һ�룬��scale=0.5
% 
% OUTPUT ��
% type - ƥ�����ģ�����ͱ��
% T - Ӱ����ģ�����ƥ��ʱimage�ı任����ͨ��T���Խ�Ӱ����ģ����ƶ���
% 
% ע�⣺limit_R2�Ǹ���Ҫ����

global skel;

% limit_R2�Ǿ����Ǽ�ƥ���ϸ�̶ȵĲ������൱��ƥ��������ֵԽ��ƥ��ı�׼
% Խ�ͣ�����ȱ��Ƚϴ���߹Ǽ�Ҳ����ƥ���������������Լ������к����ģ��ƥ�䣬
% �������ڹǼ�ƥ����һ���ͱ����˵�������ͬʱҲ�Ὣ������ĹǼ�ƥ�����������
% ����ģ��ƥ��ļ�������ʶ���Ѷȡ�
limit_R2 = 15;

%���Ʊ��ߴ�С
% [h,w] = size(image);
% h = (h*(1/scale))/100;
% w = (w*(1/scale))/100;

%������ʱ�����н�һ���жϣ����Ƕ�����ģ�����ƥ�䣬�߼��򵥣�Ч�ʽϵ�
rate = [];
for i=1:8
    pcd = skel{i};
    np = size(skel{i},1);%�Ǽܵ����
    p = randperm(np,ceil(np.*scale));%�������
    [tform{i},skelRate(i,1:2)] =  matchingskel(matchPcd,pcd(p,:).*scale);
%     ptCloudOut = pctransform(pointCloud(matchPcd),affine3d(tform{i}));
%     ptCloudOut = ptCloudOut.Location;hold off;
%     plot(pcd(p,1).*scale,pcd(p,2).*scale,'r.','markersize',10);hold on; axis equal;
%     plot(matchPcd(:,1),matchPcd(:,2),'b.','markersize',10); axis equal;
%     plot(ptCloudOut(:,1),ptCloudOut(:,2),'g.','markersize',10); axis equal;
    T = tform{i};
    R = skelRate(i,1:2);
    R1 = R(1);
    R2 = R(2);
    % �����ֱ�м�ͷ��ͼ���Ǿ���ƥ�䣬��������ƥ������2�����أ����߷���ƥ
    % ������5������,��Ϊƥ����Ч
    % ���ڹǼ��㷨�����ƣ��õ��ĹǼܶ˵������������R2���õĴ�һЩ����ʵ�����
    % �����СһЩ�Ļ���R2Ӧ��֮��R1��ֵ�Դ󣬱���R2=5��
    if (-1==T(3,3)&&(i~=1))||(R1>2||R2>limit_R2)
         rate = [rate;inf];
        continue;
    end
    rate = [rate;sqrt(R*R'/2)];
end
[m,I] = min(rate);
if m<(limit_R2/2)
    type = I;
    T = tform{type};
else
    type = 0;
    T = tform{eye(4)};
end
end

function pcdRoatated = pcdroateXY(pcd,point,rA)
%
% ������pcd��point��Ϊ����תrA��
% pcdRoatated = pcdroateXY(pcd,point,rA)

if (2==size(pcd,2))
    pcd = [pcd zeros([size(pcd,1) 1])];
end
cx = point(1,1);
cy = point(1,2);
a = cosd(rA);
b =  -sind(rA);
c = sind(rA);
d =  cosd(rA);
rT = [a b 0 0;c d 0 0;0 0 1 0;0 0 0 1];
mT = [1 0 0 0;0 1 0 0;0 0 1 0;-cx -cy 0 1];
mT2 = [1 0 0 0;0 1 0 0;0 0 1 0;cx cy 0 1];
% mT*rT*mT2,���Ƚ���mTƽ�ƣ��ڽ���rT��ת���ڽ���mT2ƽ�ƣ�mT��mT2��С��ȣ������෴
ptCloudOut = pctransform(pointCloud(pcd),affine3d(mT*rT*mT2));
pcdRoatated = ptCloudOut.Location;
end

function readtemplate()
%
%��ȡģ������

global template_go;
global template_go_right;
global template_go_left;
global template_right;
global template_left;
global template_around;
global template_merge_left;
global template_merge_right;
template_go = im2double(rgb2gray(255-imread('source\markingimage\go.png')));
template_go_right = im2double(rgb2gray(255-imread('source\markingimage\go_right.png')));
template_go_left = im2double(rgb2gray(255-imread('source\markingimage\go_left.png')));
template_right = im2double(rgb2gray(255-imread('source\markingimage\right.png')));
template_left = im2double(rgb2gray(255-imread('source\markingimage\left.png')));
template_around = im2double(rgb2gray(255-imread('source\markingimage\around.png')));
template_merge_left = im2double(rgb2gray(255-imread('source\markingimage\merge_left.png')));
template_merge_right = im2double(rgb2gray(255-imread('source\markingimage\merge_right.png')));
global template;
template= cell([8 1]);
template(1) = {template_go};
template(2) = {template_go_right};
template(3) = {template_go_left};
template(4) = {template_right};
template(5) = {template_left};
template(6) = {template_around};
template(7) = {template_merge_left};
template(8) = {template_merge_right};


%��ȡ�Ǽܵ���
%��Ϊ��ͷ�Ǽܷ�������С��Ӿ��γ���Ϊx�ᣬ�̱�Ϊy��
%ע�⣺����ģ��Ǽ���0.01��һ�����أ����������ɵ�ͼ��һ���õ�0.02�ף��������
%      ��ע������֮���Ӱ���ϵ
global skel_go;
global skel_go_right;
global skel_go_left;
global skel_right;
global skel_left;
global skel_around;
global skel_merge_left;
global skel_merge_right;
global skel;
skel_go = load('source\markingimage\go.mat');skel_go = skel_go.skelPcd;
skel_go_right = load('source\markingimage\go_right.mat');skel_go_right = skel_go_right.skelPcd;
skel_go_left = load('source\markingimage\go_left.mat');skel_go_left = skel_go_left.skelPcd;
skel_right = load('source\markingimage\right.mat');skel_right = skel_right.skelPcd;
skel_left = load('source\markingimage\left.mat');skel_left = skel_left.skelPcd;
skel_around = load('source\markingimage\around.mat');skel_around = skel_around.skelPcd;
skel_merge_left = load('source\markingimage\merge_left.mat');skel_merge_left = skel_merge_left.skelPcd;
skel_merge_right = load('source\markingimage\merge_right.mat');skel_merge_right = skel_merge_right.skelPcd;
skel= cell([8 1]);
skel(1) = {skel_go};
skel(2) = {skel_go_right};
skel(3) = {skel_go_left};
skel(4) = {skel_right};
skel(5) = {skel_left};
skel(6) = {skel_around};
skel(7) = {skel_merge_left};
skel(8) = {skel_merge_right};
end



