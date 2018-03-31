function traceDataOutput = slicetracebylasdata(traceData,ladData)
%
%����ʱ�����ȡ�����ƶ�Ӧ�Ĺ켣����
%-----���人���ݶ�������켣����Ϊ��
% traceData = importdata('dataspace_wuhan\dandian.txt');
% ladData = LASreadAll('dataspace_wuhan\origindata\data-20170418-085955.las');
lastime = ladData.time;
startTime = lastime(1);
endTime = lastime(end);

%���켣���ݵ�ʱ����ת������
tracetime = traceData(:,2);
tracetime = mod(tracetime.*1e-9,1).*1e9;%ʱ�������ִ���9λ��
traceH = floor(tracetime.*1e-7);%ʱ��2λ��
tracetime = tracetime - traceH.*1e7;
traceMin = floor(tracetime.*1e-5);
tracetime = tracetime - traceMin.*1e5;%5λС�����������
traceScd = tracetime.*1e-3;
traceT = traceH.*3600+traceMin.*60+traceScd;%

dT1 = abs(traceT - startTime);
[~,index] = sortrows(dT1);
startIndex = index(1);

dT2 = abs(traceT - endTime);
[~,index2] = sortrows(dT2);
endIndex = index2(1);
nTrace = size(traceData,1);
if nTrace>index2(1)+4
    endIndex = index2(1)+4;
end
traceDataOutput = traceData(startIndex:endIndex,4:6);
traceDataOutput = densifypoint(traceDataOutput,1/50);
% savepointcloud2file(traceDataOutput,'ahsdjkladlkslk.xyz',0);
end