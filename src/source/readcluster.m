function cluster = readcluster(filename)
%
% ��ȡ���ƾ����ļ�
%filename = 'data-20170418-085955_marking_seg.txt';

if ischar(filename)
    %��������ļ�·��
    fid=fopen(filename,'r');
elseif isa(filename,'double')
    %���
    fid = filename;
end
    %�����ļ�ͷ
    nCluster = str2num(fgetl(fid));
    cluster = struct('index',zeros(1,2),'data',zeros(1,4));
    for i=1:nCluster
        tline = fgetl(fid); 
        lineData = regexp(tline, '\s+', 'split');
        cluster(i).index = [str2num(lineData{1}), str2num(lineData{2})];
    end
    nPoint = cluster(i).index(2)-cluster(1).index(1)+1;
    
    %���������
    tline=fgetl(fid);   %ִ������ļ�ָ���Ѿ�ָ��ڶ���
    lineByte = size(tline,2);
    %Ҫ���ƶ�2λ��������ÿһ�����ݿ�ͷ��β��ռһλ
    fseek(fid, -lineByte-2, 'cof');   
    lineData = regexp(tline, '\s+', 'split');
    col =  size(lineData,2);
    if col==2,
        %xyzi
        data = fscanf(fid,'%f %f',[2,nPoint])';
        pointCloudData = data;
    elseif col==4,
        %xyzi
        data = fscanf(fid,'%f %f %f %d',[4,nPoint])';
        pointCloudData = data;
    elseif col==7,
        %xyzirgb
        data = fscanf(fid,'%f %f %f %d %d %d %d',[7,nPoint])';
        pointCloudData = data(1:nPoint,1:4);
    end
    fseek(fid, 2, 'cof');  
    if ischar(filename),
        %��������ļ�·��
        fclose(fid);
    end 
    
    for i=1:nCluster
        index  = cluster(i).index;
        index = index-nCluster-1;
%         if index(2)>size(pointCloudData,1)
%             a=0;
%         end
        cluster(i).data = pointCloudData(index(1):index(2),:);
    end
end