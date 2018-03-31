function getroadpoint_batch(dataspaceFolder)
addpath(genpath(pwd));%����ǰĿ¼�ļ��м�����Ŀ¼��ӽ��ļ���
%---------------------------
%�������г�
% if isempty(gcp('nocreate'))
%     parpool('local',6);
% end
%--------------------------
datetime('now','TimeZone','local','Format','HH:mm:ss Z')
% dataspaceFolder = 'testdata\';
    lasdataInfo = dir(strcat(dataspaceFolder,'origindata\'));
    nfile = size(lasdataInfo,1);
    
    lasFilefolder = lasdataInfo(3).folder;
    roadfolder = strcat(dataspaceFolder,'roaddata\');
    roadFolderInfo = dir(roadfolder);
    nExistRoadFile = size(roadFolderInfo,1);
    xyzdatafolder = strcat(dataspaceFolder,'xyzdata\');   
    posdatafolder = strcat(dataspaceFolder,'tracedata\');
    if ~exist(roadfolder,'dir')
        mkdir(roadfolder);
    end
    if ~exist(posdatafolder,'dir')
        mkdir(posdatafolder);
    end
    if ~exist(xyzdatafolder,'dir')
        mkdir(xyzdatafolder);
    end
    iscomputeRoad = true;
    iscomputeTrace = false;%�Ƿ���ݵ��ܶȼ���켣
    isSliceTrace = false;%�Ƿ����ʱ�����GNSS�켣��Ƭ
    
    for iflie = 1:nfile       
        if ~lasdataInfo(iflie).isdir           
            lasFilename  = lasdataInfo(iflie).name;
            originalLasFilename = getoriginalname(lasFilename); 
            iscompute = true;
            if isSliceTrace
                filepath = strcat(lasFilefolder,'/',lasFilename);
                savefilename = strcat(posdatafolder,originalLasFilename,'_GNSStrace');
                traceData =  importdata(strcat(posdatafolder,'dandian.txt'));
                ladData = LASreadAll(filepath);
                traceDataOutput = slicetracebylasdata(traceData,ladData);
                savepointcloud2file(traceDataOutput,savefilename,0);
                continue;
            end
            for i = 1:nExistRoadFile
                existRoadfilename = roadFolderInfo(i).name;
                originalExistRoadfilename = getoriginalname(existRoadfilename);
                if strcmp(originalLasFilename,originalExistRoadfilename)
                    iscompute = false;%�Ѿ����ڲ��ڼ���
                    break;
                end
            end
            if ~iscompute
                continue;
            end         
            filepath = strcat(lasFilefolder,'/',originalLasFilename,'.las');
            disp(strcat(originalLasFilename,'��ʼ��ȡ��·'));
            [roadpoint,xyzdata] = getroadpoint(filepath);
            if iscomputeTrace
                disp(strcat(originalLasFilename,'��ʼ��ȡ�켣'));
                roughTraceData = searchtracepoint(roadpoint);
                traceData = curvefit(roughTraceData);  
                posdataname = strcat(posdatafolder,originalLasFilename,'_trace');
                savepointcloud2file(traceData,posdataname,false);
            end                 
            roadpointname = strcat(roadfolder,originalLasFilename,'_road');
            xyzdatatname = strcat(xyzdatafolder,'/',originalLasFilename);
            savepointcloud2file(roadpoint,roadpointname,false);
            savepointcloud2file(xyzdata,xyzdatatname,false);
        end
    end
    datetime('now','TimeZone','local','Format','HH:mm:ss Z')
end

function [roadpoint,xyzdata] = getroadpoint(filepath)
[a,b,c]=fileparts(filepath);
if c=='.las'
    pointCloudFilePath = filepath;
    lasdata = LASreadAll(pointCloudFilePath);
    xyzdata = [lasdata.x lasdata.y lasdata.z lasdata.intensity];
elseif c=='.xyz'
    xyzdata = readpointcloudfile2(filepath);
else
    roadpoint = [];
    xyzdata = [];
    return;
end
    nPointEachTime = 1000000;%һ�δ����ĸ���
    rows = size(xyzdata,1); 
    nData = ceil(rows/nPointEachTime);
    roadpoint = zeros(rows,4);
    nRoadpointPre = 0;
    for iData = 1:nData
        if iData == nData
            startindex = (iData-1)*nPointEachTime+1;
            pointCloudData = xyzdata(startindex:end,:);
        else
            startindex = (iData-1)*nPointEachTime+1;
            endindex = iData*nPointEachTime;
            pointCloudData = xyzdata(startindex:endindex,:);
        end       
        ScanLineArray = slice(pointCloudData,[],[],0.5);
        roadPointData = getroadbyscanline(ScanLineArray,0.1,30,0.06,400);
        nroadpoint = size(roadPointData,1);
        nRoadpoint = nRoadpointPre+nroadpoint;
        roadpoint(nRoadpointPre+1:nRoadpoint,:) =  roadPointData;
        nRoadpointPre = nRoadpoint;
    end
    roadpoint = roadpoint(1:nRoadpoint,:);
end

