function cluster = vectorizeguidline(cluster,tracedata)
%
% �ӵ��ƾ�����ʶ������
% Ŀǰ�㷨ֻʹ����������ζȵ����Լ�ȡ�ýϺ�Ч��������������Ҫ�ɽ�һ��������ϸ����״

if ~isfield(cluster,'center')
    cluster = getclusterinfo(cluster,tracedata);
end
nc = size(cluster,2);

%���������Խ��г���ɸѡ
sVLimit = 99999;%���ζ���ֵ
sLimit = 0;%�����ֵ
lwLimit = 20;%�������ֵ
index_p = [];
center = [];
tmpdata = [];
for i = 1:nc
    sV = cluster(i).squareValue;
    s = cluster(i).rectArea;
    lwRate =  cluster(i).lenWidthRate;
    a2trace = cluster(i).angle2trace;
    w = cluster(i).width;
    pA = cluster(i).perctA;
    
    if (sV > sVLimit)||s<sLimit||lwRate>lwLimit||cluster(i).width<0.1
        continue;
    end
    if a2trace>70&&lwRate>10
            continue;
    end
    if a2trace>80&&cluster(i).width<0.45
        continue;
    end
    if cluster(i).perctA<0.118
        continue;
    end
    index_p = [index_p i];
%     center = [center;cluster(i).center];
%     tmpdata = [tmpdata;cluster(i).data];
%     pcd = cluster(i).data;
%     x = pcd(:,1);
%     y = pcd(:,2);
%     figure(12); plot(x,y,'.','Color',[rand rand rand]);hold on;axis equal;
%     plot(x,y,'g.');hold on;axis equal;
%         shp = alphaShape(pcd(:,1),pcd(:,2),10);
%     plot(shp);
%     j = boundary(x,y,0.1);
%     hold on;
%     plot(x(j),y(j),'r-','LineWidth',1);

end

%��ɸѡ��������ĵ����ŷʽ���ಢȥ��Ԫ�ظ������ٵľ�����
index_c = cluster_2(cluster,index_p,10,1.5);
[C,~,~] = unique(index_c);%ͳ��һ���ۼ��ɼ���
ic = 0;
for i=1:size(C,1)
    idx =  find(index_c==C(i));
% %     if size(idx,1)<4  %������һ���ɶ�����߹��ɣ����Ը�������3������Ϊ���ǵ�����
% %         continue;
% %     end
    ic = ic+1;
    cidx(ic) = {index_p(idx)};
    r = rand;g = rand;b = rand;
    m = cidx{ic};
    data_tmp = [];
    
    %ȥ������
    loop = 1;
    for k = 1:size(idx)
        w = cluster(m(k)).width;
        len = cluster(m(k)).length;
        li = 0.2;
        if (w>(2-li))&&(w<2+li)&&(len>6-li)&&(len<6+li)
            loop = 0;
            continue;
        end
    end
    if ~loop
        continue;
    end    
    
    for k = 1:size(idx)
        cluster(m(k)).label = 2;
        data = cluster(m(k)).data;
%          plot(data(:,1),data(:,2),'.','Color',[r g b]);hold on;axis equal;
        data_tmp = [data_tmp;data];
    end
%    figure(1);   plot(data_tmp(:,1),data_tmp(:,2),'.','Color',[r g b]);hold on;axis equal;
    cluster_tmp.data = data_tmp;
    cluster_tmp = getclusterinfo(cluster_tmp);
    if cluster_tmp(1).length>10&&cluster_tmp(1).area>4&&cluster_tmp(1).perctA>0.05&&cluster_tmp(1).width<5.5
      figure(1);    plot(data_tmp(:,1),data_tmp(:,2),'.','Color',[r g b]);hold on;axis equal;
    end
end

%�������Ч�����Ǹ�ͼ��ָ��кܴ��ϵ��Ӧ����취��ͼ��ָ�ʱ�������ȷ��
end

function out_idx = cluster_2(cluser,index_p,step,dist)
% ��cluster���¾��࣬matlabֱ�Ӿ���̫���������ȳ�ϡ�ھ���
% cluser - 
% index_p - Ҫ���ؾ���ľ�����cluser�е�������
%
% ��Ҫע��ĳ�ϡ�����֮�������
nc = size(index_p,2);
data2 = [];
for i=1:nc
    data = cluser(index_p(i)).data;
    data_tmp = data(1:step:end,:);%10����ϡ
    np = size(data_tmp,1);
    data2 = [data2;[data_tmp i.*ones([np 1])]];
end
idx_c = clustereuclid(data2(:,1:2),dist);
[C,~,~] = unique(idx_c);%ͳ��һ���ۼ��ɼ���
for i=1:size(C,1)
    idx =  find(idx_c==C(i));
    idx_2 = data2(idx,end);
    [C2,~,~] = unique(idx_2);%C2�洢����cluser�ı�ţ���Щ�����һ����
    out_idx(C2,1) = i;
end
end

