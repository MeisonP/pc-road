function [criticalPoint midHeight] = revisecriticalpoint(criticalPoint,scanLinePoint)
%revise critical points. make sure that critical points are close to ground
%û����ÿ��ܻᵼ��ĳЩɨ����ȱʧ
     [temp heightOrder] = sortrows(scanLinePoint,3);
     nScanLinePoint = size(scanLinePoint,1);
     midHeight = scanLinePoint(heightOrder(ceil(nScanLinePoint/2)),3);
     nCriticalPoint = size(criticalPoint,2);
     x = scanLinePoint(:,1);
     y = scanLinePoint(:,2);
     h = scanLinePoint(:,3);
     if nCriticalPoint==2,
         %��û�м�⵽������ʱ����ʱĬ������������λ������
         %��ʱֻ�ø߶�ɸѡ
         num = 0;
         for i=1:nScanLinePoint,
             dH = abs(midHeight - h(i));
             if (dH<0.15)&&num==0,
                 num = num+1;
                 criticalPoint(1)=i;               
             elseif (dH>0.15)&&num==1,
                 criticalPoint(2)=i;    
             end
         end
         return;
     end
     for i = 1:nCriticalPoint,
         cX = scanLinePoint(criticalPoint(i),1);
         cY = scanLinePoint(criticalPoint(i),2);
         cH = scanLinePoint(criticalPoint(i),3);       
         %��һ���ǹؼ���-ɨ���ƽ�࣬�ڶ����ǹؼ���-ɨ���߲��������ɨ
         %���-�����߲�
         dxyh = [sqrt((x-cX).^2+(y-cY).^2) (cH-h) abs(midHeight-h)];
         [dxyh dxyOrder] = sortrows(dxyh);
        alternativePointInfo = [];
         for m = 1:nScanLinePoint,
             newCriticalPointOrder = dxyOrder(m);
             dXY = dxyh(m,1);
             dH1 = dxyh(m,2);
             dH2 = dxyh(m,3);
             if (dXY<0.2)&&(dH1>0.03)&&(dH2<0.3),
                 alternativePointInfo = [alternativePointInfo;dH2 newCriticalPointOrder];
             end             
         end
         if ~isempty(alternativePointInfo),
             alternativePointInfo = sortrows(alternativePointInfo);
            criticalPoint(i) = alternativePointInfo(1,2);
         end       
     end
     criticalPoint = sort(criticalPoint);
end