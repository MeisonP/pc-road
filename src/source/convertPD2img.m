function [imageData,gridArray] = convertPD2img(pointData,pxielSize,radius,isRotate)
%   
% [imageData,gridArray] = convertPD2img(pointData,pxielSize,radius,isRotate)%
% convertPD2img��������ת����դ��ͼ�����convertpointcloud2img����
%
% arguments: (input)
% radius - ���ز�ֵ�뾶����������Ӽ���������Сͼ�������ڶ����ص㣬һ������
%          Ϊ��ļ����С
% isRotate - ��OPTIONAL��- �Ƿ���תͼ��ͨ����ת����ʹ��·ͼ���ӹ켣ˮƽ���ã�
%           ����ͼ����ͼ���нϴ�н�
% arguments: (output)
% radius - ���ز�ֵ�뾶����������Ӽ���������Сͼ�������ڶ����ص㣬һ������
%          Ϊ��ļ����С
%           DEFAULT: 'radius'    (pxielSize*3)
%                    'isRotate'  (true)
%
% isRotate - ��OPTIONAL��- �Ƿ���תͼ��ͨ����ת����ʹ��·ͼ���ӹ켣ˮƽ���ã�
%           ����ͼ����ͼ���нϴ�н�
% 
% arguments: (output)
% imageData - ת����ĻҶ�ͼ��
% gridArray - �Ҷ�ͼ��ÿ�����ض�Ӧ�ĵ���
% 
% datetime('now','TimeZone','local','Format','HH:mm:ss Z')
if ~exist('radius','var')||isempty(radius),radius = pxielSize*3;end
if ~exist('isRotate','var')||(isRotate==true)
    x = pointData(:,1);
    y = pointData(:,2);
    [rectx,recty,~,~] = minboundrect(x,y);
    d = sqrt((rectx(1:2) - rectx(2:3)).^2+(recty(1:2) - recty(2:3)).^2);%��Ӿ��α߳�
    [a,idx_a] = max(d);%�ϳ��ı�
    b = min(d);
    rotateA = atand((recty(idx_a)-recty(idx_a+1))/(rectx(idx_a)-rectx(idx_a+1)));%��Ӿ��νϳ��ı���x��н�
    if rotateA>=0
        [minY,idx_minY] = min(recty);
        origin  = [rectx(idx_minY) minY];%ͼ��ԭ���Ӧ����
    else
        [minX,idx_minX] = min(rectx);
        origin  = [minX recty(idx_minX)];%ͼ��ԭ���Ӧ����
    end
else
    [width,height,minX,minY,maxX,maxY] = calculatesize(pointData,pxielSize);
    a = maxX - minX;
    b = maxY - minY;
    origin = [minX,minY];
    rotateA = 0;
end
    gridArray = gridpoint(pointData,pxielSize,origin,rotateA);%������
    greyImage = idw(pointData,origin,a,b,rotateA,pxielSize,radius);%��ֵ���ȽϺ�ʱ 
    imageData = greyImage;
end

function gridArray = gridpoint(pointData,gridSize,origin,rotateA)
%generate grid of points
   % [width,height,minX,minY,maxX,maxY] = calculatesize(pointData,gridSize);
    
    x0 = pointData(:,1);
    y0 = pointData(:,2);
    if abs(tand(rotateA))~=inf
        k = tand(rotateA);
        A = k;
        B = -1;
        C = origin(2)-k*origin(1);
        d1 = abs(A.*x0+B.*y0+C)./sqrt(A*A+B*B);%�㵽���ߵľ���,��Ӧ����Y
        %�㵽�̱ߵľ��룬��Ӧ��ת���x����
        k = tand(rotateA+90);
        A = k;
        B = -1;
        C = origin(2)-k*origin(1);
        d2 = abs(A.*x0+B.*y0+C)./sqrt(A*A+B*B);
    else
        d1 = y0-origin(2);
        d2 = x0 - origin(1);
    end
    minX = min(d2);%d1.d2������x��y
    minY = min(d1);
    maxX = max(d2);
    maxY = max(d1);
    width = ceil((maxX-minX)/gridSize);
    height = ceil((maxY-minY)/gridSize);
    pointData(:,5) = d2;%���и���������5,6λ�����5,6λ�洢���������ݣ�����͵��޸ĵ�����λ
    pointData(:,6) = d1;
    widthStripsArray = cut2strips(pointData,width,minX,maxX,gridSize,5);
    gridArray = cell(height,width);
    for i = 1:width
        widthStrip = widthStripsArray{i};
        heightStripsArray = cut2strips(widthStrip,height,minY,maxY,gridSize,6);
        gridArray(:,i) = heightStripsArray';
    end
end

function stripsArray = cut2strips(pointData,nStrips,startValue,endValue,pxielSize,type)
%cut point into strips
%type==1, cut by x coordinate;
%type==2, cut by y coordinate;
%typeҲ����������ָ����;
    stripsArray(1:nStrips) = {[]};
    if isempty(pointData),
        return;
    end
    pointData = sortrows(pointData,type);%��x��������
    nPoint = size(pointData,1);
    valueArray = pointData(:,type);%�ָ�����ݣ��簴x����y����
    cutStart = startValue;
    cutEnd = startValue + pxielSize;
    iPoint=1;
    value = valueArray(1);
    isEndPoint = false;%�Ƿ���������һ����
    for i = 1:nStrips,%�ֳ�nStrips��
        strip = [];
        iStripPoint = 0;
        while value<cutEnd,
            iStripPoint = iStripPoint+1;
            strip(iStripPoint,:) = pointData(iPoint,:);
            if iPoint<nPoint,
                iPoint = iPoint+1;   
                value = valueArray(iPoint);
            else
                isEndPoint = true;
                break;
            end
        end  
        stripsArray(i) = {strip};
        cutStart = cutEnd;
        cutEnd = cutEnd + pxielSize;
        if isEndPoint,
            break;
        end
    end
end


function [width,height,minX,minY,maxX,maxY] = calculatesize(pointCloudData,pxielSize)
%calcullate width and height of image
xAraay = pointCloudData(:,1);
yArray = pointCloudData(:,2);
minX = min(xAraay);
maxX = max(xAraay);
minY = min(yArray);
maxY = max(yArray);
width =  ceil((maxX - minX)/pxielSize);
height = ceil((maxY - minY)/pxielSize);
end

function [imageOut,gridArray]= idw(pointData,origin,a,b,rotateCloudA,pxielSize,radius)
%inverse distance weighted interpolation for pointcloud
%
% arguments(input):
% pointData - ��������xyzi
% origin - ��ֵ����ԭ�㣨���½ǣ�
% a - ��ֵ���ο�
% b - ��ֵ���θ�
% rotateCloudA - ԭ����ϵ����ֵ��������ϵ��ת�ǣ�˳ʱ��Ϊ����
% radius - 0.10;��ֵ�뾶��������ն����ص�
%
% ��ֵ����ָ�Ե��ƵĲ�ֵ��Χ��һ�������֣�һ�������������ϵxy��ƽ�е���Ӿ��Σ�
% ��һ������С��Ӿ��Ρ��������С��Ӿ��Σ���a��Ӧ���ߣ�b��Ӧ�̱ߣ���Ϊ��·��
% ��״�ģ�ϣ����ֵ���ͼ�����������򣬶�����������
%
% arguments(output):
% imageOut - ��ֵ��ͼ��
% gridArray - ��ֵͼ��ÿ�����ض�Ӧ�ĵ��ƣ���ȱ
%

Mdl = KDTreeSearcher(pointData(:,1:2));%����kd������
maxI = max(pointData(:,4));
minI = min(pointData(:,4));
minX = origin(1);
minY = origin(2);
height = ceil(b/pxielSize);
width = ceil(a/pxielSize);
imageOut = zeros(height,width);
% normPara = normalizegray(imageArray);%��һ������ϵ��
if maxI~=minI
    normPara = 1/abs(0.6*maxI-minI);%����0.8maxI�����ص��
%     normPara = 1/abs(maxI-minI);%����0.8maxI�����ص��
else
    normPara = 1;
end
interX = (0.5*pxielSize:pxielSize:width*pxielSize);%��ֵ����������������
interY = (0.5*pxielSize:pxielSize:height*pxielSize)';
interX = repmat(interX,height,1);
interY = repmat(interY,1,width);
rotateImageA = atand(interY./interX);%��ֵ����������������ϵ��x��н�
rotateA = rotateCloudA + rotateImageA;
distO = sqrt(interX.^2+interY.^2);%��ֵ���������������ϵԭ�����
dx = distO.*cosd(rotateA);
dy = distO.*sind(rotateA);
interX = minX + dx;
interY = minY + dy;

ix = reshape(interX',[1 width*height])';
iy = reshape(interY',[1 width*height])';
Idx = rangesearch(Mdl,[ix iy],radius);
for iHeight=1:height
    for iWidth=1:width
        idx_pixel = (iHeight-1)*width+iWidth;%���ص����������е�˳���
        points = pointData(Idx{idx_pixel},:);%��ֵ�뾶�ڵĵ�
        nPoints = size(points,1);
        distC = sqrt((points(:,1)-ix(idx_pixel)).^2 + (points(:,2)-iy(idx_pixel)).^2);
        weight = [];
        weight(distC(:,1)~=0,1) = (pxielSize./distC).^3;
        weight(distC(:,1)==0,1) = 1;
        ins = points(:,4);
        insOutTotal = sum(weight.*(ins-minI));
        weightTotal = sum(weight);
        insOut = ((insOutTotal)/weightTotal)*normPara;
        imageOut(iHeight,iWidth) = insOut;
    end
end
end



