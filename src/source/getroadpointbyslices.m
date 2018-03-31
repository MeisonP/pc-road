  function roadPoint = getroadpointbyslices(pointCloudData,posData,roadThickness,marginW,minRoadWidth,windowW)
%
%ͨ��������Ƭʶ���·
% datetime('now','TimeZone','local','Format','HH:mm:ss Z')
if ~exist('roadThickness','var') || isempty(roadThickness),roadThickness = []; end
if ~exist('marginW','var') || isempty(marginW), marginW = []; end
if ~exist('minRoadWidth','var') || isempty(minRoadWidth), minRoadWidth = []; end
if ~exist('windowW','var') || isempty(windowW), windowW = []; end

% pointCloudData =  readpointcloudfile2('dataspace_slice\test#123.xyz');
% posData = readposfile('dataspace_slice\POS_#2_20150703.txt',14);
SliceArray = slice(pointCloudData(:,:),'bypos',posData,0,0.5,20);%��ƬԽϸ������Խ��
projectArray = project2section(SliceArray);
roadPoint = getroadfromproject(projectArray,roadThickness,marginW,minRoadWidth,windowW);
% savepointcloud2file(roadPoint,'road#123_byslices8888',false);
% datetime('now','TimeZone','local','Format','HH:mm:ss Z')
end

function projectArray = project2section(SliceArray)
%
% -X: �ڶ�άͶӰ���е�ĺ�����
%����ƬͶӰ������
nSlice = size(SliceArray,2);
projectArray = SliceArray;
for iSlice=1:nSlice,
    x1 = SliceArray(iSlice).x;
    y1 = SliceArray(iSlice).y;
    h1 = SliceArray(iSlice).h;
    info = SliceArray(iSlice).info;
    x0 = info(1);
    y0 = info(2);
    k0 = tan(info(3)+pi/2);
    k1 = -1/k0;
    %����Ƭ����ѹ������ά�ռ��ƽ��
%     pX = (y0-y1+k1.*x1-k0.*x0)/(k1-k0);
    pX = ((y0-y1)*k0+(-1).*x1-k0*k0.*x0)/(-1-k0*k0);%��ֹk0����0ʱ������k1��������������Է��ӷ�ĸͬ��k0
    if k0==0,
        pY = y1;
    else
        pY = k1.*(pX-x1)+y1;
    end
    if abs(k0)>1000,
        a=0;
    end
    
    %����ά�ռ��ƽ��ת��Ϊ��ά����
    minx = min(pX);
    miny = min(pY);
    X = sqrt((pX-minx).^2 + (pY-miny).^2); %�ڶ�άͶӰ���е�ĺ�����
    projectArray(iSlice).X = X;
end
end

function roadPoint= getroadfromproject(projectArray,roadThickness,marginW,minRoadWidth,windowW)
%
%
nProject = size(projectArray,2);
roadPoint = [];
for iProject = 1:nProject,
    X = projectArray(iProject).X;%ͶӰ������ʱ�ĺ�����
    H = projectArray(iProject).h;
    x = projectArray(iProject).x;
    y = projectArray(iProject).y;
    h = projectArray(iProject).h; 
    ins = projectArray(iProject).ins; 
    nPoint = size(X,1);
    pseudoWidth = 0.05;
    [pseudoScanline,pseudoIndex] = getpseudoscanline([X H],pseudoWidth,'min');
    %����αɨ���߽ṹ��
    pseudoX = pseudoScanline(:,1);
    pseudoY = (1:size(pseudoScanline,1))';%��¼αɨ���ߵ�˳�������ţ�
    pseudoH = pseudoScanline(:,2);  
%     plot(pseudoX,pseudoH,'r.');axis equal
    PseudoScanlineArray.x = pseudoX;
    PseudoScanlineArray.h = pseudoH;
    PseudoScanlineArray.y = pseudoY; 
    PseudoScanlineArray.ins = pseudoScanline(:,1)*0;%ֻ�������ݽṹͳһ������ʵ������
    %��αɨ�����г�����ȡ��α��·�����
     fluctuateH = 0.3;
     pseudoRoadPointData = getroadbyscanline(PseudoScanlineArray,[],[],fluctuateH);
     if isempty(pseudoRoadPointData),continue;end
     %��α��·����ֱ�߲��ֽ������
     pseudoRoadX = pseudoRoadPointData(:,1);
     pseudoRoadH = pseudoRoadPointData(:,3); 
     [coefficients,percet] = ransac([pseudoRoadX pseudoRoadH],1,0.1,10);
     if percet<0.6,continue;end
     %����ϵ�ֱ�߲�����ȡֱ�߻������ڵĵ���н�һ��������
     %����(1:nPoint)'Ϊ���������������ͶӰ��������ʵ�����Ӧ
     bufferpoint = getbufferpoint([X H (1:nPoint)'],coefficients,1);  %ͶӰ������ʽ 
%      index = bufferpoint1(1:end,3);
% if iProject==70,
%     a=1;
% end
     raodPointXH = refineroadpoint(bufferpoint,roadThickness,marginW,minRoadWidth,windowW);
 if isempty(raodPointXH),continue;end
    roadIndex = raodPointXH(:,3);  
     roadPoint = [roadPoint;x(roadIndex) y(roadIndex) h(roadIndex) ins(roadIndex)];    
%      plot(bufferpoint1(pseudoRoadIndex,1),bufferpoint1(pseudoRoadIndex,2),'g.');hold off
%      plot(X(:,1),H(:,1),'g.' );axis equal;hold on;
%      plot(bufferpoint1(:,1),bufferpoint1(:,2),'r.' );axis equal;hold on;
%      plot(pseudoScanline2(:,1),pseudoScanline2(:,2),'b.');axis equal;hold off
end
end

function  raodPointXH = refineroadpoint(bufferpoint,roadThickness,marginW,minRoadWidth,windowW)
%
%�ƶ����ڷ��˲���·����о�ϸ��ȡ
%����·����Ʋ����ڴ�ļ��
%-------Ĭ�ϲ���----------------------
%     -roadThickness ��0.2������ͶӰ���·���ȣ���·��ֲڳ̶ȡ���Ĳ��������Լ�����ͶӰ����С�й�;
%     -marginW �� 2����·��Ե�����˵ľ��룬���·��ԵС�ڴ˾����ͻ������Ϊ�����ˣ����Դ�ȷ��Ҫ��ȡ��·�淶Χ
%     -minRoadWidth ��4��,��С·��С�ڴο�ȵĵ��ƻ����                
%     -windowW��0.4����������зָ�ڵĿ�ȣ�·�渴�ӡ������ܶȴ���ʵ���С��·��ƽ̯�������ܶ�ϡ���ʵ��Ŵ󣬲���С��·�����
if ~exist('roadThickness','var') || isempty(roadThickness),roadThickness = 0.2; end
if ~exist('marginW','var') || isempty(marginW), marginW = 2; end
if ~exist('minRoadWidth','var') || isempty(minRoadWidth), minRoadWidth = 4; end
if ~exist('windowW','var') || isempty(windowW), windowW = 0.4; end
% windowW = 0.3;%���ڿ��
% roadThickness = 0.2;%��·ͶӰ���
% marginW = 2;%Χ����·��Ե����
% minRoadWidth = 4;%��С·��

raodPointXH =[];
minX = min(bufferpoint(:,1));
maxX = max(bufferpoint(:,1));
nWindow = ceil((maxX-minX)/windowW);
windowInfo = Inf(nWindow,4);%�ֱ�Ϊ���ڵĸ߲��ߵ㡢��͵㡢�����
windowArray = cell(1,nWindow);

%����ÿ�����ڵ����������Ϣ
for i=1:nWindow,
    window = bufferpoint((bufferpoint(:,1)<(i*windowW+minX))&(bufferpoint(:,1)>((i-1)*windowW+minX)),:);
    if isempty(window),windowInfo(i,4) = 0;continue;end
    windowArray(i) ={window};
    H = window(:,2);
    maxH = max(H);
    minH = min(H);
    dH = maxH-minH;
    np = size(H,1);
    windowInfo(i,1:4) = [dH,maxH,minH,np];
end

dminH = windowInfo(2:end,3) - windowInfo(1:end-1,3);
nCluster = 0;
isStart = false;
%ʶ���·��ѡƬ��
roadClusterIndex = [];
for  i=1:nWindow-1, 
    %��Ϊ��·�������͵��������Ҹ߳̽��Ƶ�
    if abs(dminH(i))<=0.2&&~isStart,
        nCluster = nCluster+1;
        roadClusterIndex(nCluster,1) = i;
        startIndex = i;
        isStart = true;
    elseif abs(dminH(i))>0.2&&isStart,
        roadClusterIndex(nCluster,2:3) = [i,i-startIndex+1];%�ڶ���Ϊ��·��ѡƬ���а����Ĵ�����
        isStart = false;
    end 
end
if isStart,
    %һ�����Ը߳�ͻ�䴰����ΪƬ�α߽�
    %�����������һ��������δ����ͻ��ʱ����������Ϊ��β�߽�
    roadClusterIndex(nCluster,2:3) = [nWindow,nWindow-startIndex+1];
end

%��Ϊ��ĺ�ѡƬ���ǵ�·���岿��
if isempty(roadClusterIndex),
    return;
end;
roadClusterIndex = sortrows(roadClusterIndex,3);
roadStartIndex = roadClusterIndex(end,1);
roadEndIndex = roadClusterIndex(end,2);
if roadClusterIndex(end,3)<ceil(minRoadWidth/windowW),
    %�����ѡƬ�γ���С��2�ף������
    return;
end

%���·���岿�ֱ߽���ӵĴ���Ҳ�п��ܰ������ֵ�·������Ӧ�����������һ�����ڲ������������ڵ�·���岿��
if roadStartIndex~=1&&windowInfo(roadStartIndex-1,4)~=0,
    minH = windowInfo(roadStartIndex,3);
    pdata = windowArray{roadStartIndex-1};
    pdata = sortrows(pdata,1);
    npdata = size(pdata,1);
    for i = npdata:1,
        H = pdata(i,2);
        if abs(H-minH)>roadThickness,
            break;
        end
    end
    if i<npdata,
        %�����䴰���еĵ�·����ӵ���·������
        windowData = windowArray{roadStartIndex};
        windowData = [windowData;pdata(i+1:end,:)];
        windowArray(roadStartIndex) = {windowData};
    end  
end
if roadEndIndex~=nWindow&&windowInfo(roadEndIndex+1,4)~=0,
   minH = windowInfo(roadEndIndex,3);
    pdata = windowArray{roadEndIndex+1};
    pdata = sortrows(pdata,1);
    npdata = size(pdata,1);
    for i = 1:npdata,
        H = pdata(i,2);
        if abs(H-minH)>roadThickness,
            break;
        end
    end
    if i>1,
        %�����䴰���еĵ�·����ӵ���·������
        windowData = windowArray{roadEndIndex};
        windowData = [windowData;pdata(1:i-1,:)];
        windowArray(roadEndIndex) = {windowData};
    end     
end

%��ȡ��·���岿�ֵĹؼ�����
%��Ϊ��ȳ���0.2��Ϊ�߽���ߵ��渽���
critcleWinClusterIndex = [];%�ؼ�������������
numCluster = 0;
isAddCluster = true;
for i = roadStartIndex:roadEndIndex,
    dH = windowInfo(i,1);
    if dH>roadThickness,
        if isAddCluster,
            numCluster = numCluster+1;
            critcleWinClusterIndex(numCluster,1:2) = [i,i];
        end    
        critcleWinClusterIndex(numCluster,2) = i;
        isAddCluster = false;
    else
        isAddCluster = true;
    end   
end

%
if numCluster==0,
    %ȫ����·���
    for m = roadStartIndex:roadEndIndex,
        winPoint =  windowArray{m};
        raodPointXH = [raodPointXH;winPoint];
    end
else
    %�����������ֻ���ǰ�����ͺ������ؼ����ڵ��߽�ľ���
    if numCluster>1&&(critcleWinClusterIndex(2,1)-roadStartIndex)<=ceil(marginW/windowW),
        cutIndexL = [critcleWinClusterIndex(2,2),2];
    elseif (critcleWinClusterIndex(1,1)-roadStartIndex)<=ceil(marginW/windowW),
        %��Ϊ����߽��и��
        cutIndexL = [critcleWinClusterIndex(1,2),1];
    else
        cutIndexL = [roadStartIndex-1,0];
    end
    if numCluster>1&&(roadEndIndex-critcleWinClusterIndex(end-1,2))<=ceil(marginW/windowW),
        cutIndexR = [critcleWinClusterIndex(end-1,1),2];
    elseif (roadEndIndex-critcleWinClusterIndex(end,2))<=ceil(marginW/windowW),
        %��Ϊ���Ҳ�߽��и��
        cutIndexR = [critcleWinClusterIndex(end,1),1];
    else
        cutIndexR = [roadEndIndex+1,0];
    end
    if cutIndexL>cutIndexR,return;end
    raodPointXH =  removeRoadNoise(windowArray,windowInfo,critcleWinClusterIndex,cutIndexL,cutIndexR,roadStartIndex,roadEndIndex);
end

% X = bufferpoint(:,1);
% H = bufferpoint(:,2);
% plot(X,H,'r.');axis equal;hold on;
% X = raodPointXH(:,1);
% H = raodPointXH(:,2);
% plot(X,H,'g.');axis equal;hold off;
% raodPointXH = [];
end

function raodPointXH = removeRoadNoise(wArray,wInfo,criWinCluIndex,cutL,cutR,rStart,rEnd)
%
%
raodPointXH = [];
flagL = 0;%0��ʾû�жԱ߽細�ڽ����и1��ʾ������һ���ؼ����ڽ������и2��ʾ�����ڶ����ؼ����ڽ������и�
flagR = 0;
cutLnum = cutL(1,2);
cutRnum = cutR(1,2);
cutL = cutL(1,1);
cutR = cutR(1,1);
%�˵㴰�ڴ���
if cutL>=rStart&&cutL<rEnd,
    maxH = wInfo(cutL+1,2);%���ڴ��ڵ���ߵ�
   winPoint =  wArray{cutL};
   winPoint =  sortrows(winPoint,1);
   np = size(winPoint,1);
   for i=np:-1:1,
       H = winPoint(i,2);
       if H>maxH,
           break;
       end
   end
   raodPointXH =[raodPointXH;winPoint(i+1:np,:)];  
   flagL = cutLnum;
   rStart = cutL+1;
end
if cutR<=rEnd&&cutR>rStart,
    maxH = wInfo(cutR-1,2);%���ڴ��ڵ���ߵ�
   winPoint =  wArray{cutR};
   winPoint =  sortrows(winPoint,1);
   np = size(winPoint,1);
   for i=1:np,
       H = winPoint(i,2);
       if H>maxH,
           break;
       end
   end
   raodPointXH =[raodPointXH;winPoint(1:i-1,:)];  
   flagR = cutRnum;
   rEnd = cutR-1;
end

%ͻ��·��Ĺؼ����ڴ������˳�ͻ������ĵ�
num = size(criWinCluIndex,1);
for i = 1+flagL:num-flagR,
   indexL =  criWinCluIndex(i,1);
   indexR = criWinCluIndex(i,2);
   if size(wInfo,1)<indexR+1||1>indexL-1,
       a=0;%��ʱ�����������ʱδ�ҵ�ԭ��
       return;
   end
   maxHL = wInfo(indexL-1,2);
   maxHR = wInfo(indexR+1,2);
   maxH = max([maxHL;maxHR]);
   for m = indexL:indexR,
       winPoint =  wArray{m};
       winPoint = winPoint(winPoint(:,2)<maxH,:);
       raodPointXH = [raodPointXH;winPoint];      
   end
end

%����������δͻ��·��ĵ�ֱ����ȡ
if flagL~=0,flagL = flagL-1;end
if flagR~=0,flagR = flagR-1;end
for i = 1+flagL:num-flagR-1,
   indexL =  criWinCluIndex(i,2)+1;
   indexR = criWinCluIndex(i+1,1)-1;
   for m = indexL:indexR,
       winPoint =  wArray{m};
       raodPointXH = [raodPointXH;winPoint];      
   end
end

%��Ե����
indexL =  criWinCluIndex(1,1);
indexR =  criWinCluIndex(end,2);
for m = rStart:indexL-1,
    winPoint =  wArray{m};
    raodPointXH = [raodPointXH;winPoint];
end
for m = indexR+1:rEnd,
    winPoint =  wArray{m};
    raodPointXH = [raodPointXH;winPoint];
end

end

function bufferPoint = getbufferpoint(pointData,coefficients,length)
%
%
x = pointData(:,1);
y = pointData(:,2);
A = coefficients(1);
B = -1;
C = coefficients(2);
d = abs(A.*x+B.*y+C)./sqrt(A^2+1);
d(:,2) =1:size(d,1); 
bufferPoint = pointData(d(d(:,1)<length,2),:);
end

function pointData = getpointfrompseudo(projectArray,pseudoIndex,index)
%��ȡ��αɨ����Ӧ�ĵ�
%   -projectArray:ԭʼͶӰ�����ݵĽṹ��
%   -pseudoIndex:αɨ�����ʵ�ʵ�Ķ�Ӧ���������һ��αɨ����Ӧ��Щʵ�ʵ�
%   -index:��Ҫ��ȡ��αɨ�������������ȡ������αɨ���
    nPseudoRoadPoint = size(index,1);
     pointData = [];
     for i=1:nPseudoRoadPoint,
          pIndex =   pseudoIndex{index(i)};
         px = projectArray.x(pIndex);
         py = projectArray.y(pIndex);
         ph = projectArray.h(pIndex);
         pins = projectArray.ins(pIndex);
         pointData = [pointData;px py ph pins];         
     end
end

function [pseudoScanline,pseudoIndex] = getpseudoscanline(pointData,width,type)
%
% -pseudoIndex:αɨ�����еĵ�����Ӧ�ĵ�ʵ�ʵ㼯������
%�Ӷ���ͶӰ������αɨ����
    nPoint = size(pointData,1);
    X = pointData(:,1);
    H = pointData(:,2);
    [X_sorted,index] = sortrows(X);
    XX = [X_sorted,index];
    nPseudoGrid = ceil((X_sorted(nPoint)-X_sorted(1))/width);
    pseudoX = X_sorted(1);
    nPseudoScanline = 0;
    for i=1:nPseudoGrid,
        pseudoX = pseudoX+width;
          XXtemp =  XX((XX(:,1)<pseudoX)&(XX(:,1)>=(pseudoX-width)),:);%��pseudoX����������
          if ~isempty(XXtemp),
              nPseudoScanline = nPseudoScanline+1;
              if strcmp(type,'min'),
                  pseudoH= min(H(XXtemp(:,2)));
              elseif strcmp(type,'max'),
                  pseudoH= max(H(XXtemp(:,2)));
              end  
             pseudoScanline(nPseudoScanline,:) = [pseudoX,pseudoH];
             pseudoIndex(nPseudoScanline,:) = {XXtemp(:,2)};
          end      
    end
%    if nPseudoScanline==0,
%        a=0;
%    end
end