function pointCloudData = readpointcloudfile(pointCloudFilePath,nPoint)
% read specified number of points from point cloud file
% suitable for reading the large text file 
if ischar(pointCloudFilePath),
    %��������ļ�·��
    fid=fopen(pointCloudFilePath,'r');
elseif isa(pointCloudFilePath,'double'),
    %���
    fid = pointCloudFilePath;
end
    tline=fgetl(fid);   %ִ������ļ�ָ���Ѿ�ָ��ڶ���
    lineByte = size(tline,2);
    %Ҫ���ƶ�2λ��������ÿһ�����ݿ�ͷ��β��ռһλ
    fseek(fid, -lineByte-2, 'cof');   
    lineData = regexp(tline, '\s+', 'split');
    col =  size(lineData,2);
    if col==4,
        %xyzi
        data = fscanf(fid,'%f %f %f %d',[4,nPoint])';
        pointCloudData = data;
    elseif col==7,
        %xyzirgb
        data = fscanf(fid,'%f %f %f %d %d %d %d',[7,nPoint])';
        pointCloudData = data(1:nPoint,1:4);
    end
    fseek(fid, 2, 'cof');  
    if ischar(pointCloudFilePath),
        %��������ļ�·��
        fclose(fid);
    end 
end