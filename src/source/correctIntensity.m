function pointData = correctIntensity(pointData,info,calibdata)
% correct intensity of point clouod
% 
% 
sliceX = info(1);
sliceY = info(2);
sliceK = info(3);

PointSet= struct('data',[],'range',[]);
SliceArray=repmat(PointSet,[1 50]);
x = pointData(:,1);
y = pointData(:,2);
%�Ե��ƽ�����ת
A = pi/2-sliceK;%��ת��

%������ת�������е�Ϊԭ�㣬����Ϊ������������ϵ��
x0= (x - sliceX).*cos(A) - (y - sliceY).*sin(A) ;%��ʱ����תA��A�������޽ǣ���ת��Y��ָ��켣ǰ������
y0= (x - sliceX).*sin(A) + (y - sliceY).*cos(A) ;

%У��
minx0 = min(x0);
miny0= min(y0);
maxx0 = max(x0);
maxy0 = max(y0);
w = 0.05;
for loc=minx0:w:maxx0
    locStart  = (loc-w/2);
    locEnd = (loc+w/2);
    correctvar1= mean(calibdata(calibdata(:,1)>locStart&calibdata(:,1)<=locEnd,2));
    idx = find(x0<=locEnd&x0>locStart);
    if ~isnan(correctvar1)&~isempty(idx)
        pointData(idx,4)=pointData(idx,4)-correctvar1;
    end 
end
end

