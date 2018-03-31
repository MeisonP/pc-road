function [imageData,gridArray] = convertpointcloud2img(pointCloudData,pxielSize,radius)
%
% -radius:���ز�ֵ�뾶����������Ӽ���������Сͼ�������ڶ����ص㣬һ������Ϊ��ļ����С
% datetime('now','TimeZone','local','Format','HH:mm:ss Z')
if ~exist('radius','var')||isempty(radius),radius = pxielSize*3;end
%     pointCloudFilePath = 'circle_30d60d_All.xyz';
%     pointCloudData = readpointcloudfile2(pointCloudFilePath);
%     pxielSize = 0.005;
    maxI = max(pointCloudData(:,4));
    minI = min(pointCloudData(:,4));
    [width,height,minX,minY,maxX,maxY] = calculatesize(pointCloudData,pxielSize);
    gridArray = gridpoint(pointCloudData,pxielSize);%������
    greyImage = idw(gridArray,minX,minY,maxI,minI,pxielSize,radius);%��ֵ���ȽϺ�ʱ 
%    img =  imread('qq.png');
%    img = rgb2gray(img);
%    hist =  imhist(img); 
%     [imageData,T] = histeq(greyImage);
    imageData = greyImage;
%     figure,plot((0:255)/255,T);
%     imwrite(imageData,'car.png');%ͼ������
% datetime('now','TimeZone','local','Format','HH:mm:ss Z')
end

function  normPara = normalizegray(imageArray)
%correct grat value
%�����ظ������ݽ���ϡ�������һ������
%ȡ�������֮һ�����ص���й�һ������
[row,col] = size(imageArray);
rowNum = ceil(row/100);%�в�������
colNum = ceil(col/100);
   indexRow= getsampleindex(row,rowNum); 
   indexCol= getsampleindex(col,colNum); 
   maxGray = 0;
    for i = 1:rowNum,
        for m = 1:colNum,
          data =  imageArray{indexRow(i),indexCol(m)};
          if isempty(data),
              continue;
          end
          gary =  max(data(:,4));
          if maxGray<gary,
              maxGray = gary;
          end
        end
    end
    if maxGray==0,
        normPara=1;
    else
        normPara = 1/maxGray;
    end
end


function gridArray = gridpoint(pointCloudData,gridSize)
%generate grid of points
    [width,height,minX,minY,maxX,maxY] = calculatesize(pointCloudData,gridSize);
    widthStripsArray = cut2strips(pointCloudData,width,minX,maxX,gridSize,1);
    gridArray = cell(height,width);
    for i = 1:width,
        widthStrip = widthStripsArray{i};
        heightStripsArray = cut2strips(widthStrip,height,minY,maxY,gridSize,2);
        gridArray(:,i) = heightStripsArray';
    end
end

function imageOut = idw(imageArray,minX,minY,maxI,minI,pxielSize,radius)
%inverse distance weighted interpolation
% -radius �� 0.10;��ֵ�뾶��������ն����ص�
nGrid = ceil(radius/pxielSize) - 1;%�Ҷ�ֵ����ΧnGrid������Ӱ��
[height,width] = size(imageArray);
imageOut = zeros(height,width);
% normPara = normalizegray(imageArray);%��һ������ϵ��
if maxI~=minI,
    normPara = 1/abs(0.8*maxI-minI);%����0.8maxI�����ص��
    normPara = 1/abs(maxI-minI);%����0.8maxI�����ص��
else
    normPara = 1;
end
% normPara=1/255;
    for iHeight=1:height,
%         if iHeight==200,
%             a=0;
%         end
        for iWidth=1:width,
            %�������и���
            xLR = iWidth - nGrid;
            yLR = iHeight - nGrid;
            xRB = iWidth + nGrid;
            yRB = iHeight + nGrid;
            if xLR<=0,
                xLR=1;
            end
            if yLR<=0,
                yLR=1;
            end
            if xRB>=width,
                xRB=width;
            end
            if yRB>=height,
                yRB=height;
            end
            pointsArray = imageArray(yLR:yRB,xLR:xRB);
            interX = minX+(iWidth-1)*pxielSize+0.5*pxielSize;%��ֵ��������
            interY = minY+(iHeight-1)*pxielSize+0.5*pxielSize;
            [wPoints,hPoints] = size(pointsArray);
            nPoints=0;
            points = zeros(100,4);%�ȳ�ʼ��50���ڴ棬�������Ƶ���ı䳤��
            for m=1:wPoints,
                for n=1:hPoints,
                    %����Ӱ�췶Χ�ڵĸ�����
                    %��Ҫ���������ķ�ʱ��
                    point = pointsArray{m,n};
                    nPoint = size(point,1);
                    if nPoint==0,
                        continue;
                    end
                    nPointsPre = nPoints;
                    nPoints = nPoints+nPoint;
                    points(nPointsPre+1:nPoints,:) = point;
                end
            end
            if nPoints==0,
                continue;
            end
            weightTotal = 0;
            insOut = 0;
            for i = 1:nPoints,
                x = points(i,1);
                y = points(i,2);
                ins = points(i,4);
                dist = norm([interX-x interY-y]);
                %��Ȩ����Խ�ߣ���ֵ����Աȶ�Խ��һ�����3�η�ʱ����������ȶ�
                weight = (pxielSize/dist)^3;
                %��Ȩ��ֵ������Ƚ�ģ��
%               weight = 1;
                insOut = insOut+weight*(ins-minI);
                weightTotal = weightTotal+weight;
            end
%             insOut = (insOut/weightTotal)/255;
            insOut = ((insOut)/weightTotal)*normPara;
            imageOut(iHeight,iWidth) = insOut;
        end
    end
end

function stripsArray = cut2strips(pointData,nStrips,startValue,endValue,pxielSize,type)
%cut point into strips
%type==1, cut by x coordinate;
%type==2, cut by y coordinate;
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

function grey = calculategrey(pointData)
%calculate grey value of each pixel
    grey =0;
    if isempty(pointData),
        return;
    end
    ins = pointData(:,4);
    grey = mean(ins)/225;
    grey = mean(ins)
end

function [width,height,minX,minY,maxX,maxY] = calculatesize(pointCloudData,pxielSize)
%calcullate width and height of inage
xAraay = pointCloudData(:,1);
yArray = pointCloudData(:,2);
minX = min(xAraay);
maxX = max(xAraay);
minY = min(yArray);
maxY = max(yArray);
width =  ceil((maxX - minX)/pxielSize);
height = ceil((maxY - minY)/pxielSize);
end

function index = getsampleindex(nPoint,nSample)
%
%��1~nPoint�������ȡnSample�����ظ����񣬷��ض���������
    index = -ones(nSample,1);
    iSample = 0;
    while iSample<nSample,
        rand0 =  floor(1+(nPoint-1)*rand(1,1));
        isSave = true;
        for i = 1:iSample,          
            if rand0==index(i),
                isSave = false;
                break;
            end
        end
        if isSave,
            iSample = iSample+1;
            index(iSample,1) = rand0;
        end
    end
end

