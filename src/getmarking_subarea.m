function  getmarking_subarea(pointCloudFilePath)
% ���Ʒ�������
datetime('now','TimeZone','local','Format','HH:mm:ss Z')
addpath(genpath(pwd));

% ��ȡ·���������
pointCloudFilePath = 'CASEDATA\marking_anys\yingwuzhou.xyz';
fid=fopen(pointCloudFilePath,'r');
pointCloudData = readpointcloudfile2(fid);

% ���ڵ��ܶȼ���켣
%  roughTraceData = searchtracepoint(pointCloudData);
%  traceData = curvefit(roughTraceData);

% ʹ�þ��ܹ켣�ļ����Ƽ���
posFilePath ='YingwuzhouBridge\tracedata\road-all_GNSStrace.xyz';
% posData = readposfile(posFilePath,14);
traceData = importdata(posFilePath);
posData.x = traceData(:,1);
posData.y = traceData(:,2);
posData.h = traceData(:,3);

% savepointcloud2file([posData.x posData.y posData.h zeros(size(posData.h,1),1)],'tracedata',1);
%��Ƭ���˹��񣬷���Թ��䴦�����и�ʱ�и��߻���·��ƽ��
%�и��õ�pos����Ҫ���ٱȵ��Ƴ���һ���и�ȣ��������ܱ����и�ʱ��·�˵㸽��������
posData = cutuselesspos(pointCloudData,posData,10);
SliceArray = slice(pointCloudData,'bypos',posData,[0,5,25]);
nSlice = size(SliceArray,2);
PointSet= struct('x',0,'y',0,'h',0,'ins',0);
markingPoint=repmat(PointSet,[1 nSlice]);
%---------------------------
% �������г�
% if isempty(gcp('nocreate'))
%     parpool('local',5); 
% end
%--------------------------
calibinterval = 100;% ǿ��У���������¼��
 imdata =  [];
for iSlice = 1:nSlice
% parfor iSlice = 1:nSlice
    x = SliceArray(iSlice).x;
    y = SliceArray(iSlice).y;
    h = SliceArray(iSlice).h;
    ins = SliceArray(iSlice).ins;
    info = SliceArray(iSlice).info;% info�����е�����ͽǶ�
    slicePoint = [x y h ins];
    
    % ���е�Ϊ����0��ķָ�㻮��
    seg1 = -4.7;
    seg2 = -2;
    seg3 = 2;
    seg4 = 4.7;
    data = slicePoint;
    %ǿ��У������
%     if 1==mod(iSlice,calibinterval)
        outposData = cutuselesspos(data,posData,2);
        dataSliceArray = slice(data,'bypos',outposData,[0,0.5,25]);%ȡ�м�0.5�׵ĵ��Ƽ���У��ģ��
        nDataSlice = size(dataSliceArray,2);
        k = floor((nDataSlice+1)/2);%�м���Ƭ�����
        calibPointdata = [dataSliceArray(k).x dataSliceArray(k).y  dataSliceArray(k).h dataSliceArray(k).ins];
        calibInfo = dataSliceArray(k).info;
        calibdata_update = calibratintensity(calibPointdata,calibInfo);
        calibdata=calibdata_update;
%     end
    data = correctIntensity(slicePoint,calibInfo,calibdata);
%     [imageData ,gridArray] = convertPD2img(data,0.05,0.2);
%     imshow(imageData);
    imdata =  [imdata;data];
    continue;
        
    %     data(data(:,4)<0,4) =0;
    cutLenght = [-20,seg1,seg1,seg2,seg2,seg3,seg3,seg4,seg4,20];
%         cutLenght = [-20,20];
    blockArray = slice(data,'subarea',[],[info cutLenght]);
    
%     [imageData ,gridArray] = convertPD2img(data,0.05,0.2);
%    figure(); imshow(imageData);
%     [imageData2 ,gridArray] = convertPD2img(slicePoint,0.05,0.2);
%     figure();imshow(imageData2);
    
    markingpiece = [];
    markingpiece2 = [];
    markingpiece3 = [];
    markingpieceBW = [];
    for iBlock = 1:size(blockArray,2)
        data = blockArray(iBlock).data;
        if size(data,1)<10
            continue;
        end
        [imageData ,gridArray] = convertPD2img(data,0.05,0.2);
        imageData = imgaussfilt(imageData,2);
%         imwrite(imageData,'test--.png');
        % ���㱳���Ҷ�ֵ������Ӧ�ָ���ֵ���ɻ���ͼȷ������·������ĻҶ�ֵΪ0�����Խ�
        % ��·���Ե���ߵ���ȡ����Ӱ����·������ķǱ��ߵͻҶ�ֵ���ؾ�ֵȷ��
        imageData = imfillnan(imageData);
        
        SensityValue = 0.53;
        BW = imbinarize(imageData,'adaptive','Sensitivity',SensityValue);
        
%         imageData2=medfilt2(imageData,[5,5]);
        thresh = mygraythresh(imageData);
        imageData2 = imbinarize(imageData,thresh);
        
        seg_I  = mymultithresh(imageData,2);
        imageData3 = imageData;
        imageData3(isnan(imageData3)) = 0;
        imageData3(imageData3<seg_I(2)) = 0;
        imageData3(imageData3>=seg_I(2)) = 1;
        
        se = strel('line',3,3);
        se2 = strel('diamond',2);
        imageData2 = imopen(imageData2,se2);%ustu����ֵ�ָ�
        
        imageData3 = imopen(imageData3,se);%ustu����ֵ�ָ�Ҷ�ֵ��Ľ��
        BW = imopen(BW,se);%����Ӧ��ֵ���
        
       I = padarray(imageData,[10 10],'replicate','both');%��Ե��չ
       BW2 =  imadaptive(I,10,1.1);
       BW2 = BW2(11:end-10,11:end-10);
       BW2 = bwareaopen(BW2,10);
       BW2 = imclose(BW2,se);
%        BW2 = imopen(BW2,se);
%        BW2 =  imopen(BW2,se);

       I = padarray(imageData,[10 10],'replicate','both');%��Ե��չ
       BW3 =  imadaptive(I,10,1.25);
       BW3 = BW3(11:end-10,11:end-10);
       BW3 = bwareaopen(BW3,10);
       BW3 = imopen(BW3,se);
       
        point2 = getpointfromgrid(gridArray,imageData2,1,12);
        point3 = getpointfromgrid(gridArray,imageData3,1,12);
        pointBW = getpointfromgrid(gridArray,BW,1,12);
        pointBW2 = getpointfromgrid(gridArray,BW2,1,12);
        pointBW3 = getpointfromgrid(gridArray,BW3,1,12);
        
       figure(1);imshow(imageData);
       figure(2);imshow(imageData2);
%         figure(3);imshow(imageData3);       
        figure(4);imshow(BW);
        figure(5);imshow(BW2);
        figure(6);imshow(BW3);
%         imwrite(BW,'��У���Դ�����Ӧ.png');
%         imwrite(BW2,'��У���ҵ�����Ӧ.png');

% %
        if iBlock == 1
            markingpiece = [markingpiece;pointBW2];
        elseif iBlock == 2
             markingpiece = [markingpiece;pointBW3];
        elseif iBlock == 3          
            markingpiece = [markingpiece;pointBW3];
        elseif iBlock == 4 
            markingpiece = [markingpiece;point2];
        elseif iBlock == 5 
            markingpiece = [markingpiece;pointBW3];
        end
        markingpiece2 = [markingpiece2;point2];
        markingpiece3 = [markingpiece3;point3];
        markingpieceBW = [markingpieceBW;pointBW];
    end    
%     markingPoint = [markingPoint;markingpiece];
%parpool���м���ʱ�ƺ�������Ԫ��������ʹ�ýṹ�����顣
markingPoint(iSlice).x = markingpiece(:,1);
markingPoint(iSlice).y = markingpiece(:,2);
markingPoint(iSlice).h = markingpiece(:,3);
markingPoint(iSlice).ins = markingpiece(:,4);

markingPoint2(iSlice).x = markingpiece2(:,1);
markingPoint2(iSlice).y = markingpiece2(:,2);
markingPoint2(iSlice).h = markingpiece2(:,3);
markingPoint2(iSlice).ins = markingpiece2(:,4);

markingPoint3(iSlice).x = markingpiece3(:,1);
markingPoint3(iSlice).y = markingpiece3(:,2);
markingPoint3(iSlice).h = markingpiece3(:,3);
markingPoint3(iSlice).ins = markingpiece3(:,4);

markingPointBW(iSlice).x = markingpieceBW(:,1);
markingPointBW(iSlice).y = markingpieceBW(:,2);
markingPointBW(iSlice).h = markingpieceBW(:,3);
markingPointBW(iSlice).ins = markingpieceBW(:,4);
end
savepointcloud2file(imdata,'yingwuzhou_c',false);
    [imageData ,gridArray] = convertPD2img(imdata,0.05,0.2);
    imwrite(imageData,'lai.png');
%------------------
%�رղ��г�
% parpool close 
%-----------------
 markingPoint =  getpointfromstructArray(markingPoint);
 [path,originalname,type]=fileparts(pointCloudFilePath);
 savepointcloud2file(markingPoint,strcat(originalname,'_marking_test'),false);
%  plot(markingPoint(:,1),markingPoint(:,2),'.');
% imageData = convertpointcloud2img(markingPoint,0.05,0.2);
% imshow(imageData);

% fclose(fid);

% imwrite(imageData,'road.png');%ͼ������
% img = imread('roadimage\22.png');
% gimg = edge(img,'Canny',0.2);
datetime('now','TimeZone','local','Format','HH:mm:ss Z')
end



function point = getpointfromgrid(gridArray,seg_I,num,type)
%
% -seg_I:���������ͼ�����
% -num;Ҫ��ȡ����������
% -type:������������λ����12������1��2λ��56������5��6λ��
[row,col] = size(seg_I);
point = zeros(10000,4);
np = 0;
for m = 1:row
    for n = 1:col
        if seg_I(m,n)~=num
            continue;
        end
        p = gridArray{m,n};
        if (type==56)&&(~isempty(p))
            x = p(:,5);
            y = p(:,6);
            h = p(:,3);
            ins = p(:,4);
            p = [x y h ins]; 
        elseif type==12&&(~isempty(p))
            x = p(:,1);
            y = p(:,2);
            h = p(:,3);
            ins = p(:,4);
            p = [x y h ins];
        end       
        if seg_I(m,n)==num&&(~isempty(p))
            preNp = np;
            np = np + size(p,1);
            point(preNp+1:np,:) = p;
        end        
    end
end
point = point(1:np,:);
end

