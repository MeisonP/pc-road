function outpos = cutuselesspos(pointCloudData,posData_in,extendD)
% 
% outpos = cutuselesspos(pointCloudData,posData_in,extendD)
% ȥ������Ҫ��pos���ݣ�ֻ���µ��������ڵ�pos����
% pointCloudData - ��������
% posData_in  - �켣���ݣ��ṹ������
% extendD - �켣�����и�ʱ��ͷ��Ҫ�ӳ��ľ���
%

if ~exist('extendD','var')||isempty(extendD),extendD = 0;end
posData = [posData_in.x posData_in.y posData_in.h];

np = size(pointCloudData,1);
npos = size(posData,1);
if np<10001
    tracePoint1 = searchtracepoint(pointCloudData);
    tracePoint2 = tracePoint1;
else
    tracePoint1 = searchtracepoint(pointCloudData(1:10000,:));
    tracePoint2 = searchtracepoint(pointCloudData(end-10000:end,:));
end
Mdl = KDTreeSearcher(posData(:,1:2));
[idx1,d1] = knnsearch(Mdl,tracePoint1(:,1:2));
[idx2,d2] = knnsearch(Mdl,tracePoint2(:,1:2));
r1 = sortrows([idx1,d1],2);
r2 = sortrows([idx2,d2],2);
idx1 = r1(1,1);
d1 = r1(1,2);
idx2 = r2(1,1);
d2 = r2(1,2);


 extendN = ceil(extendD/norm(posData(1,:)-posData(2,:)))+10;%�ӳ���pos�����
 if (idx1-extendN)>0
     idx1 = idx1-extendN;
 end
  if (idx2+extendN)<=npos
     idx2 = idx2+extendN;
  end
  if d1<1&d2<1
      outpos.x = posData(idx1:idx2,1);
      outpos.y = posData(idx1:idx2,2);
      outpos.h = posData(idx1:idx2,3);
  else
      outpos = posData_in;
  end
%   plot(pointCloudData(:,1),pointCloudData(:,2),'g.');hold on;
%   plot(outpos.x,outpos.y,'r.');
end