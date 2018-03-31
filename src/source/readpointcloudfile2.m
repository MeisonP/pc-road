function pointCloudData = readpointcloudfile2(pointCloudFilePath)
% read all of points from point cloud file

if ischar(pointCloudFilePath)
    %��������ļ�·��
    datadir=dir(pointCloudFilePath);
    if isempty(datadir)||(datadir.bytes==0)
        pointCloudData = [];
        return;
    end
    fid=fopen(pointCloudFilePath,'r');
elseif isa(pointCloudFilePath,'double')
    %���
    fid = pointCloudFilePath;
end
    tline=fgetl(fid);   %ִ������ļ�ָ���Ѿ�ָ��ڶ���
    lineByte = size(tline,2);
    %Ҫ���ƶ�2λ��������ÿһ�����ݿ�ͷ��β��ռһλ
    fseek(fid, -lineByte-2, 'cof');   
    lineData = regexp(tline, '\s+', 'split');
    col =  size(lineData,2);
    temp = col;
    for i = 1:temp
        %��ȥ��β�ո�
        if strcmp(lineData{i},'')
            col = col-1;
        end
    end  
    if col==4
        %xyzi
        data = fscanf(fid,'%f %f %f %f',[4,inf])';
        pointCloudData = data;
    elseif col==3
        %xyz
        data = fscanf(fid,'%f %f %f',[3,inf])';
        pointCloudData = data(:,1:3);
    elseif col==7
        %xyzirgb
        data = fscanf(fid,'%f %f %f %d %d %d %d',[7,inf])';
        pointCloudData = data(:,1:4);
    end
    if ischar(pointCloudFilePath)
        %��������ļ�·��
        fclose(fid);
    end
end