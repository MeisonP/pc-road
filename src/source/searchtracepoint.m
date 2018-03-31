function tracePointData = searchtracepoint(pointCloudData)
% search the nearest point to scanner according to the point density of scanline 
%�Թ켣������˷ֶ���ϣ���δ�Զ˵����ƽ������
    nPoint = size(pointCloudData,1);
    prePoint = pointCloudData(1:nPoint-1,1:4);
    nextPoint = pointCloudData(2:nPoint,1:4);    
    dx = (prePoint(1:nPoint-1,1)-nextPoint(1:nPoint-1,1));
    dy = (prePoint(1:nPoint-1,2)-nextPoint(1:nPoint-1,2));
    dh = (prePoint(1:nPoint-1,3)-nextPoint(1:nPoint-1,3));
    ds = sqrt(dx.^2+dy.^2+dh.^2);
%�����ô�ͼ������Ȿ�㷨
%     plot(1:1000,ds(1:1000),'r.');
%     hold on
%     plot(10000:20000,ds(10000:20000));
    centerPointArray = zeros(fix(nPoint/100),4);
    iTracePoint = 0;
    num = 0;%ÿ��ɨ�����м��С��0.5m�ĵ���������켣������Щ�㵱��
    %intervalQuantity��ʾ����ɨ����֮�����ĵ������һ��ȡɨ���ߵ������0.75
    %�켣����ȡ����Դ˲������Ǻ����У���Ҫ��ʵ��������̫�󼴿�
    %intervalQuantit��С��ʹ�켣�������ȡ�������ʹһЩɨ���ߵĹ켣�㱻����
    intervalQuantity = 50;
    for i = 1:nPoint-1,
        if (ds(i))<0.5,
            num = num+1;
            linePointArray(num,1) = i;
            linePointArray(num,2) = round(ds(i),4);
        elseif (ds(i))>=0.5&&(num>=intervalQuantity),
            iTracePoint = iTracePoint+1;
            linePointArray=sortrows(linePointArray,2);
            minDs = linePointArray(1,2);%��С���
            nMinDs=0;%��С�������
            while (minDs==linePointArray(nMinDs+1,2))&&((nMinDs+1)<=num),
                %��Щ��С���������һ���ģ����Բ���ֻȡ��һ����
                nMinDs=nMinDs+1; 
            end
            a= median(linePointArray(1:nMinDs,1));
            %�ɼ��Ĺ켣����ϵĹ켣��ʵ��pos���ݶԱȣ��������г����������ڴ�Լ
            %2cm���ҵ�ϵͳ���ڲ�����4�������켣���������õ��ϴ���ƣ��Ʋ�
            %�����ǲ������궨ʱ���������
            minDsPointOrder=ceil((linePointArray(1,1)+linePointArray(nMinDs,1))/2)-4;%��С�����Ӧ��������   
            if minDsPointOrder<1
                minDsPointOrder = 1;
            end
            centerPointArray(iTracePoint,1:4) = pointCloudData(minDsPointOrder,1:4);
            num = 0;
            linePointArray = [];
        else
            num = 0;
        end     
    end
    nTracePoint = iTracePoint;
    tracePointData = centerPointArray(1:nTracePoint,:);
%     %�Թ켣�߷ֶ����,������10�׼�����׶���ʽ���
% %     segmentArray = zeros(nCenterPoint/10,1);
%     segmentArray(1) = 1;
%     iSegmentArray = 1;
%     preX = centerPointArray(1,1);
%     preY = centerPointArray(1,2);
%     for i = 1:nCenterPoint,
%         x = centerPointArray(i,1);
%         y = centerPointArray(i,2);
%         %�켣��֮��ļ������
%         dist = sqrt((x-preX)^2+(y-preY)^2);
%         if dist>10,
%             iSegmentArray = iSegmentArray+1;
%             segmentArray(iSegmentArray) = i;
%             preX = x;
%             preY = y;
%         end      
%     end
%     segmentArray(iSegmentArray) = nCenterPoint;
%     traceData = zeros((iSegmentArray-1)*100,2);
%     for i=1:iSegmentArray-1,
%         nStart = segmentArray(i);
%         nEnd = segmentArray(i+1);
%         traceTemp = centerPointArray(nStart:nEnd,:);
%         xdata = traceTemp(:,1);
%         ydata = traceTemp(:,2);
%         hdata = traceTemp(:,3);
%         p=polyfit(xdata,ydata,1);
%         %�ȷֳ�100�����
%         x1 = linspace(centerPointArray(nStart,1),centerPointArray(nEnd,1));
%         y1 = polyval(p,x1);
%         step = (nEnd-nStart)/100;
%         for m =1:100,
%             temp = ceil(step*m);      
%             h(m) = hdata(temp);
%         end
%         traceData((i-1)*100+1:i*100,1:3) = [x1' y1' h'];
% %         plot(xdata,ydata,'.')
% %         hold on
% %         plot(x1,y1,'r-')
% %         axis equal;
%     end
% %     traceData = 0;
end