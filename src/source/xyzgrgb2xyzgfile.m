function xyzgrgb2xyzgfile
%��xyz�Ҷ�rgb�ļ�ת����xyzg�ļ���ʽ
    datetime('now','TimeZone','local','Format','HH:mm:ss Z')
    pointCloudFilePath = 'D:\20161219������ɫ\22.3\2#.xyz';
    pointData = readfile(pointCloudFilePath);
    x = pointData.x;
    y = pointData.y;
    h = pointData.h;
    ins = pointData.ins;
    savepointcloud2file([x y h ins],strcat(pointCloudFilePath,'_noColor'));
    datetime('now','TimeZone','local','Format','HH:mm:ss Z')
end

function pointData = readfile(filePath)
%��ȡpos����ʱע���������и�ʽ
    fid=fopen(filePath,'r');
    data = fscanf(fid,'%f %f %f %d %d %d %d',[7,inf])';
    pointData.x = data(1:end,1);
    pointData.y = data(1:end,2);
    pointData.h = data(1:end,3);
    pointData.ins = data(1:end,4);
    pointData.r = data(1:end,5);
    pointData.g = data(1:end,6);
    pointData.b = data(1:end,7);
    fclose(fid);
end

















