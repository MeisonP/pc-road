function [cluster,breakLines] = vectorizebreakline_for_solid(cluster)
%
% 
% ����ȡ�ı��ߵ�����ʶ������ߣ���ȷ����������Ԫ�ص�����˳��
% INPUT��
% cluster - ���ƾ������ݵĽṹ������
%
% OUTPUT��
% cluster - �����ĵ��ƾ������ݵĽṹ�����飬���һЩ������ص��ֶ���Ϣ
% breakLines - ��������cluster��������Ԫ������
%
% ������ʵ�ߵ���ȡ�Ѷ�Ҫ�������ߣ�һЩ������ȡ�㷨��������bug����ʵ����ȡ�����ֳ���


if ~isfield(cluster,'center')
    cluster = getclusterinfo(cluster);
end
[cluster,breakLines] = getbreakline(cluster);
%%%%%%%%%%%%%%ȥ���϶̵��߶�%%%%%%%%%%%%%%%
% breakFragmentinfo = getbreaklinefragmentinfo(cluster,breakLines);
% idx = 0;
% for i=1:size(breakFragmentinfo,2)
%     if breakFragmentinfo(i).range>5
%         idx =idx+1;
%         breakLinestmp(idx) = breakLines(i);
%     end
% end
% breakLines = breakLinestmp;
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%�����ô���%%%%%%%%%%%%%%%%%%%%%%%
for i=1:size(breakLines,2)
    idx = breakLines{i};
    color = [rand rand rand rand];
    plotPointdata = [];
    plotLinedata = [];
    for m = 1:size(idx,2)
        data = cluster(idx(m)).data;
        plotPointdata = [plotPointdata;data];
        plotLinedata = [plotLinedata;cluster(idx(m)).center];
%         figure(3); plot([c1(1) c2(1)],[c1(2) c2(2)],'-','Color',color);hold on;axis equal
        rx = cluster(idx(m)).rectx;
        ry = cluster(idx(m)).recty;
%         plot(rx,ry,'-','Color',color);%����Ӿ���
    end
    figure(2); plot(plotLinedata(:,1),plotLinedata(:,2),'-','Color',[ 0 0 0]);hold on;axis equal
    figure(2); plot(plotPointdata(:,1),plotPointdata(:,2),'.','Color',color);hold on;axis equal
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

function [cluster,breakLines] = getbreakline(cluster)
%
% ��ȡ������
%
% INPUT��
% cluster - ����������Ϣ�ı��ߵ��ƾ���
%
% OUTPUT - cluster��breakLinesΪ��ȡ�Ķ����߽��
%

[cluster,breakLines] = getbreaklinefragment(cluster,20,10);
[cluster,breakLines] = refinebreaklinefragment(cluster,breakLines);
breakindx = cell2mat(breakLines);
for i = 1:size(breakindx,2)
    cluster(breakindx(i)).label = 1;
end
end

function [cluster,linkedBreakLines] = refinebreaklinefragment(cluster,breakLines)
%
% �Գ�����ȡ�Ķ����߽�����о�ϸ�������õ�������ȡ���
%
% INPUT��
% cluster��breakLines
%
% OUTPUT��
% cluster - 
% linkedBreakLines - ��breakLines�н϶̵��߶����ӳɽϳ��Ķ�����Ƭ��
%

% ÿ��ֻ����һ���������ӹ������߶η���Ҳ�ᷢ���仯�����Զ��㼸��ʹ������ȫ
[cluster,linkedBreakLines] = linkBbreaklinefragment(cluster,breakLines,30,2);
% return;
%�˵�С��3��Ԫ�ص�Ƭ��
nLinked = size(linkedBreakLines,2);
n = 0;
for iLinked = 1:nLinked
    linekedline = linkedBreakLines{iLinked};
    if size(linekedline,2)<0
        continue;
    end
    n = n+1;
    linkedTmp(n) = {linekedline};
end
linkedBreakLines = linkedTmp;
for i=1:5
    %��Ҫ����ֱ��linkedBreakLines�����̶�Ϊֹ��һ����Ҫ5�μ��㣩
    [cluster,linkedBreakLines] = linkBbreaklinefragment(cluster,linkedBreakLines,90,5);
end
end

function [cluster,linkedBreakLines,isLink] = linkBbreaklinefragment2(cluster,...
    breakLines,isLink,breakNum,breakFragmentinfo,terminalEnd,terminal,Mdl,direction)

% ������ͬһ�������ߵ�Ƭ����������
% ��ʱ������Ԥ��

% breakFragmentinfo = getbreaklinefragmentinfo(cluster,breakLines);
nBreak = size(breakLines,2);
r = 60;
iBreak = breakNum;
    Y = terminalEnd(iBreak,1:2);%��endPoint��ʼ����
    pre_idx = iBreak;%breakLines������
    pre_idx_t = nBreak+iBreak;%����terminal�ж�Ӧ����
    breakLine = breakLines{pre_idx};
    pre_idx_c = breakLine(end);%��cluster�ж�Ӧ����
    loopflag = true;
linkedBreakLines = [];
     while(loopflag)
        [Idx,D] = rangesearch(Mdl,Y,r);%�Է�Բ20���ڵľ��������бȶ�
        Idx = Idx{1,1};
        for iNearst = 2:size(Idx,2) %��������Լ������Դ�2��ʼ
            now_idx_t = Idx(iNearst);
            now_idx = terminal(now_idx_t,3);
            breakLine = breakLines{now_idx};
            pre_breakLine = breakLines{pre_idx};
            if terminal(now_idx_t,4) == 1
                now_idx_c = breakLine(1);%��cluster�ж�Ӧ����
            elseif terminal(now_idx_t,4) == 2
                now_idx_c = breakLine(end);%��cluster�ж�Ӧ����
            end
            if  isLink(now_idx) % ����߶��Ѿ����������
                if iNearst ==size(Idx,2)
                    %����������ˣ�Ҳû�ҵ����Ƶģ�����
                    loopflag = false;
                    break;
                end
                continue;
            end
            preX = terminal(pre_idx_t,1);
            preY = terminal(pre_idx_t,2);
            nowX = terminal(now_idx_t,1);
            nowY = terminal(now_idx_t,2);
            preA = cluster(pre_idx_c).angle;
            nowA =cluster(now_idx_c).angle;
            pre_now_angle = atand((nowY-preY)/(nowX-preX));%�����������ߵĽǶ�
            if pre_now_angle<0
                pre_now_angle = pre_now_angle+180;
            end
            searchAngle = 5;%��Ѱ�ǣ������ھ൱ǰ���η���һ����Χ������
            limitAngle1 = abs(preA-pre_now_angle);%�����߼н�
            limitAngle2 = abs(nowA-pre_now_angle);
            if limitAngle1>90
                limitAngle1 = abs(limitAngle1-180);
            end
            if limitAngle2>90
                limitAngle2 = abs(limitAngle2-180);
            end
            if ~(limitAngle1<searchAngle&&limitAngle2<searchAngle)
%             if ~(abs(preA-pre_now_angle)<searchAngle&&abs(nowA-pre_now_angle)<searchAngle)
                %�����಻��ͬһ��ֱ���ϣ�����
                if iNearst ==size(Idx,2)
                    %����������ˣ�Ҳû�ҵ����Ƶģ�����
                    loopflag = false;
                    break;
                end
                continue;
            end
            %������ӷ����Ƿ�һ��
            if (size(linkedBreakLines,2)==0)&&(size(direction,2)==1)
                %���preֻ��һ��Ԫ�أ��Ҹ�Ԫ��û�и������ӷ����򲻷ַ���
                v2 = cluster(pre_idx_c).center - cluster(now_idx_c).center;
            else %size(linkedBreakLines,2)>1
                if size(direction,2)==2
                    v1 = -direction;
                   
                elseif size(linkedBreakLines,1)>0
                    ;
%                 else
%                     if terminal(pre_idx_t,4) == 1
%                         pre_idx_c2 = pre_breakLine(1,2);%��˵����ڵĵ���cluster�ж�Ӧ����
%                     elseif terminal(pre_idx_t,4) == 2
%                         pre_idx_c2 = pre_breakLine(1,end-1);
%                     end
%                     v1 =  cluster(pre_idx_c2).center - cluster(pre_idx_c).center;
                    
                end
                v2 = cluster(pre_idx_c).center - cluster(now_idx_c).center;
                angleV12  = acosd(v1*v2'/(norm(v1)*norm(v2)));%�����н�
                
                if size(breakLine,2)>1
                    if terminal(now_idx_t,4) == 1
                        now_idx_c2 = breakLine(1,2);%��˵����ڵĵ���cluster�ж�Ӧ����
                    elseif terminal(now_idx_t,4) == 2
                        now_idx_c2 = breakLine(1,end-1);
                    end
                    v3 = cluster(now_idx_c).center - cluster(now_idx_c2).center;
                    angleV23  = acosd(v2*v3'/(norm(v2)*norm(v3)));%�����н�
                else
                    angleV23=0;
                end
                if ~((abs(angleV12)<searchAngle)&&(abs(angleV23)<searchAngle))
                    if iNearst ==size(Idx,2)
                        %����������ˣ�Ҳû�ҵ����Ƶģ�����
                        loopflag = false;
                        break;
                    end
                    continue;
                end
            end             
            %�����ֻ���ж�ǰ�����������״���Ƴ̶�
            preL = breakFragmentinfo(pre_idx).length;
            nowL = breakFragmentinfo(now_idx).length;
            preW = breakFragmentinfo(pre_idx).width;
            nowW = breakFragmentinfo(now_idx).width;
            permitDl = 0.5;%����ĳ��Ȳ�
            permitDw = 0.15;%����Ŀ�Ȳ�
            if abs(preL-nowL)<permitDl&&abs(preW-nowW)<permitDw
                % ������Գ��Ȳ���Ϊ���Ƴ̶�������
                tmp = breakLines{now_idx};
                if terminal(now_idx_t,4) == 2
                    tmp = fliplr(tmp);
                end
                linkedBreakLines = [linkedBreakLines tmp];
                isLink(now_idx) = true;
                
                pre_idx = now_idx;
                if terminal(now_idx_t,4) == 1
                    pre_idx_c = breakLine(end);
                    pre_idx_t = nBreak+now_idx;
                elseif terminal(now_idx_t,4) == 2
                    pre_idx_c = breakLine(1);
                    pre_idx_t = now_idx;
                end
                Y = cluster(pre_idx_c).center;
                if exist('v2','var')
                    v1 = v2;
                end
                 direction=0;
                
%                 pre_idx = now_idx;
%                 pre_idx_t = now_idx_t;
%                 pre_idx_c = now_idx_c;
%                 Y = cluster(now_idx_c).center;
               break;% �ж��������������������
            end  
        end
        if (isempty(iNearst))||(iNearst ==size(Idx,2))
            %����������ˣ�Ҳû�ҵ����Ƶģ�����
            loopflag = false;
        end
     end 
a = 0;
end

function [cluster,linkedBreakLines] = linkBbreaklinefragment(cluster,breakLines,r,searchAngle)
% 
% ������ͬһ�������ߵĽ϶̵��߶����ӳɽϳ���Ƭ�Σ����㷨ֻ���߶ε���㿪ʼ������
% ��������ʱ����Ϊ�յ㣬�ʿ�ͨ�����ѭ��ʹ��linkBbreaklinefragmentʹ�߶�����
% ��ȫ
%
% INPUT��
% cluster,breakLines - 
% r - �߶�����ʱ�������뾶���ڴ˷�Χ��Ѱ���߶����ӵ�
% searchAngle - �����Ƕȣ�����������һ���Ƕȷ�Χ������
% 
% OUTPUT��
% cluster - 
% linkedBreakLines - 
%
%

breakFragmentinfo = getbreaklinefragmentinfo(cluster,breakLines);
nBreak = size(breakLines,2);
points = zeros(2*nBreak,2);
%�˵����ע�⵱������Ƭ��ֻ��һ��Ԫ�أ�����ĩ�˵���ͬһ����
for iBreak = 1:nBreak
   terminalStart(iBreak,1:4) =  [breakFragmentinfo(iBreak).startPoint iBreak 1];%ĩλ�Ǳ������1��ʾstart��2��ʾend
   terminalEnd(iBreak,1:4) =  [breakFragmentinfo(iBreak).endPoint iBreak 2];
end

%�ȴ�startPoint����
terminal = [terminalStart;terminalEnd];
Mdl = KDTreeSearcher(terminal(:,1:2));
% r = 30;
isLink = zeros(nBreak,1);%�����������߶��Ƿ��Ѿ����ӹ�
nLinkedBreak = 0;
for iBreak = 1:nBreak
    if isLink(iBreak)
        continue;
    end
    nLinkedBreak = nLinkedBreak+1;
    if nLinkedBreak==42
        a=0;
    end
    Y = terminalStart(iBreak,1:2);
    isLink(iBreak) = true;
    pre_idx = iBreak;%breakLines������
%     pre_idx_t = 2*iBreak-1;%����terminal�ж�Ӧ����
    pre_idx_t = iBreak;
    breakLine = breakLines{pre_idx};
    pre_idx_c = breakLine(1);%��cluster�ж�Ӧ����
    loopflag = true;
    linkedBreakLines(nLinkedBreak) = {fliplr(breakLines{iBreak})};%��start������˳��Ҫ������
%     [Idx,D]= rangesearch(Mdl,Y,r);
         while(loopflag)
        [Idx,D] = rangesearch(Mdl,Y,r);%�Է�Բ20���ڵľ��������бȶ�
        Idx = Idx{1,1};
        for iNearst = 2:size(Idx,2) %��������Լ������Դ�2��ʼ
            now_idx_t = Idx(iNearst);
            now_idx = terminal(now_idx_t,3);
            breakLine = breakLines{now_idx};
            pre_breakLine = linkedBreakLines{nLinkedBreak};%ע����Ҫ��pre_breakLineÿ�ν��и��£�����һֱʹ��breakLines����
            
            if terminal(now_idx_t,4) == 1
                now_idx_c = breakLine(1);%��cluster�ж�Ӧ����
            elseif terminal(now_idx_t,4) == 2
                now_idx_c = breakLine(end);%��cluster�ж�Ӧ����
            end
            if  isLink(now_idx) % ����߶��Ѿ����������
                if iNearst ==size(Idx,2)
                    %����������ˣ�Ҳû�ҵ����Ƶģ���ʱ��ʼ�µ�һ��linkedLine
                    loopflag = false;
                    break;
                end
                continue;
            end
            preX = terminal(pre_idx_t,1);%��ǰ�߶������˵�
            preY = terminal(pre_idx_t,2);
            nowX = terminal(now_idx_t,1);%���ж��Ƿ����ӵĶ���Ķ˵�
            nowY = terminal(now_idx_t,2);
            preA = cluster(pre_idx_c).angle;
            nowA =cluster(now_idx_c).angle;
            pre_now_angle = atand((nowY-preY)/(nowX-preX));%�����������ߵĽǶ�
            if pre_now_angle<0
                pre_now_angle = pre_now_angle+180;
            end
%             searchAngle = 5;%��Ѱ�ǣ������ھ൱ǰ���η���һ����Χ������
            limitAngle1 = abs(preA-pre_now_angle);%�˵���ξ��䷽���������߼н�
            limitAngle2 = abs(nowA-pre_now_angle);
            if limitAngle1>90
                limitAngle1 = abs(limitAngle1-180);
            end
            if limitAngle2>90
                limitAngle2 = abs(limitAngle2-180);
            end
            if ~(limitAngle1<searchAngle&&limitAngle2<searchAngle)
                %�����಻��ͬһ��ֱ���ϣ�����
                if iNearst ==size(Idx,2)
                    %����������ˣ�Ҳû�ҵ����Ƶģ���ʱ��ʼ�µ�һ��breakLine
                    loopflag = false;
                    break;
                end
                continue;
            end
            %������ӷ����Ƿ�һ��
            v2 = cluster(pre_idx_c).center - cluster(now_idx_c).center;
            if size(pre_breakLine,2)==1
                %���ֻ��һ��Ԫ�أ��򲻷ַ���
                v1 = v2;
                angleV12  = acosd(v1*v2'/(norm(v1)*norm(v2)));%�����н�
            else
%                 if terminal(pre_idx_t,4) == 1
%                     pre_idx_c2 = pre_breakLine(1,2);%��˵����ڵĵ���cluster�ж�Ӧ����
%                 elseif terminal(pre_idx_t,4) == 2
%                     pre_idx_c2 = pre_breakLine(1,end-1);
%                 end
                pre_idx_c2 = pre_breakLine(1,end-1);%ע��pre_breakLineÿ�ζ�ʹ��linkedBreakLines�����˸��£����Բ�����Ҫ�ж϶˵�˳��
                v1 =  cluster(pre_idx_c2).center - cluster(pre_idx_c).center;
                angleV12  = acosd(v1*v2'/(norm(v1)*norm(v2)));%�����н�
            end
            if size(breakLine,2)>1
                if terminal(now_idx_t,4) == 1
                    now_idx_c2 = breakLine(1,2);%��˵����ڵĵ���cluster�ж�Ӧ����
                elseif terminal(now_idx_t,4) == 2
                    now_idx_c2 = breakLine(1,end-1);
                end
                v3 = cluster(now_idx_c).center - cluster(now_idx_c2).center;
                angleV23  = acosd(v2*v3'/(norm(v2)*norm(v3)));%�����н�
            else
                angleV23=0;
            end
            if ~((abs(angleV12)<searchAngle)&&(abs(angleV23)<searchAngle))
                if iNearst ==size(Idx,2)
                    %����������ˣ�Ҳû�ҵ����Ƶģ���ʱ��ʼ�µ�һ��breakLine
                    loopflag = false;
                    break;
                end
                continue;
            end
            %�����ֻ���ж�ǰ�����������״���Ƴ̶�
            preL = breakFragmentinfo(pre_idx).length;
            nowL = breakFragmentinfo(now_idx).length;
            preW = breakFragmentinfo(pre_idx).width;
            nowW = breakFragmentinfo(now_idx).width;
            permitDl = 9999;%����ĳ��Ȳ�
            permitDw = 0.5;%����Ŀ�Ȳ�
            if abs(preL-nowL)<permitDl&&abs(preW-nowW)<permitDw
                % ������Գ��Ȳ���Ϊ���Ƴ̶�������
                tmp = breakLines{now_idx};
                if terminal(now_idx_t,4) == 2
                    tmp = fliplr(tmp);
                end
                linkedBreakLines(nLinkedBreak) = {[linkedBreakLines{nLinkedBreak} tmp]};
                isLink(now_idx) = true;
                % ���������㣬ע�������ǰ���ӵ���Ƭ����㣬����һ����������ӦƬ�����յ�
                pre_idx = now_idx;
                if terminal(now_idx_t,4) == 1
                    pre_idx_c = breakLine(end);
                    pre_idx_t = nBreak+now_idx;
                elseif terminal(now_idx_t,4) == 2
                    pre_idx_c = breakLine(1);
                    pre_idx_t = now_idx;
                end
                Y = cluster(pre_idx_c).center;
               break;% �ж��������������������
            end  
        end
        if (isempty(iNearst))||(iNearst ==size(Idx,2))
%            % ����������ˣ�Ҳû�ҵ����Ƶģ���ʱ��ʼ�µ�һ��breakLine
%            % �и�bug������һ����������ʱ���˵㰴�����㴦��ģ�û�п���֮ǰ����������
            if size(linkedBreakLines{nLinkedBreak},2)>1
                tmp = linkedBreakLines{nLinkedBreak};
                direction = cluster(tmp(1)).center - cluster(tmp(2)).center;
            else
                direction = 0;
            end
%             if nLinkedBreak==11
%                 a=0;
%             end
            %-----------------------------------------------
            % ÿ���߶���startpoint��endpoint�����˵㣬linkBbreaklinefragment��
            % ���ȴ�startpoint�����������������������linkBbreaklinefragment2
            % ����endpoint����������linkBbreaklinefragment2Ŀǰ��2��bug��1�ǻ��
            % ����ǵ����ӣ��ѽ������2���˵������þ����ֻ���֣���Ҫ���ơ�
            % ���û��linkBbreaklinefragment2������Ҫ�������linkBbreaklinefragmentʹ
            % �߶γ������֪���߶���Ŀ���ڱ仯��һ����5�����ϣ����������linkBbreaklinefragment2��
            % linkBbreaklinefragmentһ�����������߶θ����ͻ�̶�
%             [cluster,endlinkedBreakLine,isLink] = linkBbreaklinefragment2(cluster,...
%                 breakLines,isLink,iBreak,breakFragmentinfo,terminalEnd,terminal,Mdl,direction);
%             linkedBreakLines(nLinkedBreak) = {[fliplr(endlinkedBreakLine) linkedBreakLines{nLinkedBreak}]};
            %---------------------------------------------
            loopflag = false;
        end
     end 
end
end

function breaklinefragmentinfo = getbreaklinefragmentinfo(cluster,breakLines)
% 
% ���������Ƭ�εĳ��ȡ���β�˵㡢Ԫ�ص�ƽ�����Ե���Ϣ����Щ��Ϣ�����ں���������
%

nfrag  = size(breakLines,2);
for ifrag = 1:nfrag
    breakLine = breakLines{ifrag};
    startPoint = cluster(breakLine(1)).center;
    endPoint = cluster(breakLine(end)).center;
    %�߶ζ˵�
    breaklinefragmentinfo(ifrag).startPoint = startPoint;
    breaklinefragmentinfo(ifrag).endPoint = endPoint;
    centers = zeros(size(breakLine,2),2);
    %��ȡƽ����״
    nc = size(breakLine,2);
    for i = 1:nc
        centers(i,:) =  cluster(breakLine(i)).center;
        widths(i,:) = cluster(breakLine(i)).width;
        lengths(i,:) = cluster(breakLine(i)).length;
        areas(i,:) = cluster(breakLine(i)).area;
        perctsA(i,:) = cluster(breakLine(i)).perctA;
    end
    breaklinefragmentinfo(ifrag).width = mean(widths(1:nc));%������Ӧ��ȥ���������ݣ�������ʱ�򵥻�����
    breaklinefragmentinfo(ifrag).length = mean(lengths(1:nc));
    breaklinefragmentinfo(ifrag).area = mean(areas(1:nc));
    breaklinefragmentinfo(ifrag).perctA = mean(perctsA(1:nc));
    %��ȡ�߶γ���
    if size(centers,1)>1
        pre_cx = centers(1:end-1,1);
        pre_cy = centers(1:end-1,2);
        next_cx = centers(2:end,1);
        next_cy = centers(2:end,2);
        breaklinefragmentinfo(ifrag).range = ...
            sum(sqrt((pre_cx-next_cx).^2+(pre_cy - next_cy).^2));
    else
        breaklinefragmentinfo(ifrag).range = 0;%ֻ��һ������Ԫ�أ���Ϊ����Ϊ0
    end   
end
end

function [cluster,breakLines] = getbreaklinefragment(cluster,r,searchAngle)
%
% �Զ�����Ԫ�ؽ��г��������γɶ������߶�Ƭ��
%
% INPUT��
% cluster - 
% r -
% searchAngle -
%
% OUTPUT��
% cluster - 
% breakLines - ��˳��洢�Ķ�������cluster�е�����
%
% �����е���Ҫ������r��searchAngle��permitDl��permitDw
%
% ��ȡ������Ƭ�Σ�ʵ�ߣ�
% �����Ǹ���ǿɸѡ������ȡ��������Ƭ�Σ���ʱ��Ƭ������Ƭ���ģ������Ѿ�ӵ�и���
% һ��ά�ȵ���Ϣ����Щ���Ŀ����ڶ����ߵĽ�һ����ϸ������

if ~exist('searchAngle','var')||isempty(searchAngle),searchAngle = 5;end
if ~exist('r','var')||isempty(r),r = 20;end

% �ҳ����Ƴʾ��ηֲ��ľ���
 nRect = 0;
for iCluster=1:size(cluster,2)
    if cluster(iCluster).label
        continue;
    end
    data = cluster(iCluster).data;
    center = cluster(iCluster).center;
    limit_perctA = 0.6;
    limit_area = 0.3;
    if (cluster(iCluster).length/cluster(iCluster).width)>7
        %��������ȴ���7
        limit_perctA = 0.3;
        limit_area = 0.2;
    end
    
    limit_perctA = 0;
    limit_area = 0.1;
    width = cluster(iCluster).width;
    if cluster(iCluster).perctA>limit_perctA&cluster(iCluster).area>limit_area&width<0.5
        % ������ٷֱ��Լ���С��Ϊɸѡԭ��
        nRect = nRect+1;
        rectIndex(nRect,1:3) = [center,iCluster];
    end
    %figure(3); plot(data(:,1),data(:,2),'.');hold on;
end

% �Զ����߽��г������࣬ʹ�õ��ǵ����������㷨
Mdl = KDTreeSearcher(rectIndex(:,1:2));
nBreakLines = 0;
breakLines = {};
% r  = 20;
for iRect = 1:nRect
    idx = rectIndex(iRect,3);
    if  cluster(idx).isLabel % ����Ѿ����������
        continue;
    end
    nBreakLines = nBreakLines+1;
    Y = rectIndex(iRect,1:2); %���ξ��������
    cluster(idx).isLabel = true;
    pre_idx = idx;
    pre_pre_idx = 0;% 0��ʾ������pre_pre_idx
    loopflag = true;
    breakLines(nBreakLines) = {pre_idx};
%     if nBreakLines==28
%         a=0;
%     end
    while(loopflag)
        [Idx,D] = rangesearch(Mdl,Y,r);%�Է�Բһ�������ڵľ��������бȶ�
        Idx = Idx{1,1};
        for iNearst = 2:size(Idx,2) %��������Լ������Դ�2��ʼ
            now_idx = rectIndex(Idx(iNearst),3);
            if  cluster(now_idx).isLabel % ����Ѿ����������
                if iNearst ==size(Idx,2)
                    %����������ˣ�Ҳû�ҵ����Ƶģ���ʱ��ʼ�µ�һ��breakLine
                    loopflag = false;
                    break;
                end
                continue;
            end
            preX = cluster(pre_idx).center(1);
            preY = cluster(pre_idx).center(2);
            nowX = cluster(now_idx).center(1);
            nowY = cluster(now_idx).center(2);
            preA = cluster(pre_idx).angle;
            nowA =cluster(now_idx).angle;
            pre_now_angle = atand((nowY-preY)/(nowX-preX));%����������������ߵĽǶ�
            if pre_now_angle<0
                pre_now_angle = pre_now_angle+180;
            end
            if pre_pre_idx~=0
                v1 = cluster(pre_idx).center - cluster(pre_pre_idx).center;
                v2 = cluster(now_idx).center - cluster(pre_idx).center;
                angleV12  = acosd(v1*v2'/(norm(v1)*norm(v2)));%�����н�,������������ͻ��
            else
                angleV12 = 0;
            end
%             searchAngle = 5;%��Ѱ�ǣ������ھ൱ǰ���η���һ����Χ������
            limitAngle1 = abs(preA-pre_now_angle);%�����߼н�
            limitAngle2 = abs(nowA-pre_now_angle);
            if limitAngle1>90
                limitAngle1 = abs(limitAngle1-180);
            end
            if limitAngle2>90
                limitAngle2 = abs(limitAngle2-180);
            end
            if ~(limitAngle1<searchAngle&&limitAngle2<searchAngle&&(angleV12<searchAngle))
                %�����಻��ͬһ��ֱ���ϣ�����
                if iNearst ==size(Idx,2)
                    %����������ˣ�Ҳû�ҵ����Ƶģ���ʱ��ʼ�µ�һ��breakLine
                    loopflag = false;
                    break;
                end
                continue;
            end
            %�����ֻ���ж�ǰ�����������״���Ƴ̶�
            preL = cluster(pre_idx).length;
            nowL = cluster(now_idx).length;
            preW = cluster(pre_idx).width;
            nowW = cluster(now_idx).width;
            permitDl = 999;%����ĳ��Ȳ�
            permitDw = 0.5;%����Ŀ�Ȳ�
            if abs(preL-nowL)<permitDl&&abs(preW-nowW)<permitDw
                % ������Գ��Ȳ���Ϊ���Ƴ̶�������
                cluster(now_idx).isLabel = true;
                breakLineTmp = breakLines{nBreakLines};
                breakLines(nBreakLines) = {[breakLineTmp now_idx]};
                pre_idx = now_idx;
                Y = cluster(now_idx).center;
                if size(breakLineTmp,2)>0
                    pre_pre_idx = breakLineTmp(end);
                else
                    pre_pre_idx = 0;
                end
               break;% �ж��������������������
            end  
        end
        if iNearst ==size(Idx,2)
            %����������ˣ�Ҳû�ҵ����Ƶģ���ʱ��ʼ�µ�һ��breakLine
            loopflag = false;
        end
        if size(Idx,2)==1
            loopflag = false;
        end
    end
end
end

% function cluster = getclusterinfo(cluster)
% %
% % ������ƾ������������Ϣ������Ӿ��δ�С�����������λ�á�����ȣ�ʹ����Щ��
% % Ϣ�Կ��ԶԾ�����и��߲�εĳ����Ա�����һ���Ĵ���
% %
% % INPUT��
% % cluster - ���ƾ���ṹ��
% % 
% % OUTPUT��
% % cluster - ӵ����������������ֶεĵ��ƾ���ṹ��
% 
% nc  = size(cluster,2);%�������
% for i=1:nc
%     data = cluster(i).data;
%     cluster(i).isLabel = false;
%     cluster(i).label = -1;%-1��ʾ���δ֪
%     x = data(:,1);
%     y = data(:,2);
%     [rectx,recty,rectArea,perimeter] = minboundrect(data(:,1),data(:,2));
%     cluster(i).rectx = rectx;
%     cluster(i).recty = recty;
%     cx = mean(rectx);
%     cy = mean(recty);
%     cluster(i).center = [cx cy];%��Ӿ�������
%     cluster(i).rectArea = rectArea;%��С��Ӿ������
%     cluster(i).perimeter = perimeter;
%     d = sqrt((rectx(1:2) - rectx(2:3)).^2+(recty(1:2) - recty(2:3)).^2);%��Ӿ��α߳�
%     cluster(i).length = max(d);
%     cluster(i).width = min(d);
%     areaSeed = unique([roundn(x,-1) roundn(y,-1)],'rows');%�����Ӧ��0.1�׵ĸ�����
%     pointArea = 0.1*0.1*size(areaSeed,1)-0.5*perimeter*0.1;%�Ը����������Ƽ��������� 
%     cluster(i).area = pointArea;
%     cluster(i).perctA = pointArea/rectArea;
%     
%     %���η�����������ʾ�˾��ε���̬�����ַ��򣩣�ģ�Ĵ�С��ʾ�˳ʾ��εĳ̶�
%     if d(1)==d(2)
%         cluster(i).direction = [0,0];%����������ģΪ0
%     elseif d(1)>d(2)
%          cluster(i).direction = [(rectx(1) - rectx(2))/d(1),(recty(1) - recty(2))/d(1)].*(abs(d(1)/d(2)-1));   
%     elseif d(1)<d(2)
%         cluster(i).direction = [(rectx(3) - rectx(2))/d(2),(recty(3) - recty(2))/d(2)].*(abs(d(2)/d(1)-1));   
%     end
%     if cluster(i).direction(2)<0
%         cluster(i).direction = -cluster(i).direction;
%     end 
%     cluster(i).angle = atand(cluster(i).direction(2)/cluster(i).direction(1));
%     if cluster(i).angle<0
%         cluster(i).angle = cluster(i).angle+180;%�ǶȻ��㵽0~180
%     end
% %     plot(rectx,recty,'-');hold on;
% %     plot(x,y,'.');hold on;
% %     axis equal;
% end
% end
