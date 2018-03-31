function criticalPoint = getroughcriticalpoint(ScanLinePoint,curbHeight,minCurbSlope,fluctuateH)
%detect critical points rooughly by height and slope.
%     curbHeight��minCurbSlope��fluctuateH�������ǳ���Ҫ�Ĳ�����������·���
% �Ƶ���ȡЧ��Ӱ��������curbHeight����Ҫ������·��߽�ͻ���·�������壩��
% �߶��йأ�һ������Ϊ��ͻ����߶�ֵ��С������ֵΪɨ���ߴ���ͻ�����ϵ���С���ȣ���
% minCurbSlope��ӳ��͹������·��ļнǣ�minCurbSlopeֵ���õ�ԽС�߽���ȡԽ�ϸ�
% Խ��߽���ȡԽ�����ڲ�ʹɨ�������ߵ������ԽСԽ�ã�fluctuateH��ӳ�����·
% ����Ƶĸ̲߳����̶ȣ�����fluctuateHֵ�Ļ���Ϊ�Ǳ߽�.
%-------Ĭ�ϲ���----------------------
%     -curbHeight �� 0.08;
%     -minCurbSlope �� 25;
%     -fluctuateH ����ɨ������Ϊ0.05��αɨ�������ʵ�������0.15����αɨ��������
%                   ���ɨ�����������ɵã��ò���ֵ������Ϊ0.2~0.3��
%
if ~exist('curbHeight','var') || isempty(curbHeight),curbHeight = 0.08; end
if ~exist('minCurbSlope','var') || isempty(minCurbSlope), minCurbSlope = 25; end
if ~exist('fluctuateH','var') || isempty(fluctuateH), fluctuateH = 0.05; end
 
    x = ScanLinePoint.x;
    y = ScanLinePoint.y;
    h = ScanLinePoint.h;
    ins = ScanLinePoint.ins;
    nScanLinePoint = size(x,1);
    preX = x(1);
    preY = y(1);
    preH = h(1);
    nCriticalPoint = 0;
    criticalPoint = [];
        for m=2:nScanLinePoint,
            currentX = x(m);
            currentY = y(m);
            currentH = h(m);
            dh = abs(currentH-preH);
            dxy = sqrt((currentX-preX)^2+(currentY-preY)^2);
            ds = sqrt(dxy^2+dh^2);
            if (ds>curbHeight)&&(dxy~=0),
                slope = atand(dh/dxy);
                if (slope>minCurbSlope)||abs(dh)>fluctuateH,
                    nCriticalPoint = nCriticalPoint+1;
                    criticalPoint(nCriticalPoint) = m;
                end
                preH = currentH;
                preX = currentX;
                preY = currentY;
            elseif (ds>curbHeight)&&(dxy==0),
                nCriticalPoint = nCriticalPoint+1;
                criticalPoint(nCriticalPoint) = m;
                preH = currentH;
                preX = currentX;
                preY = currentY;
            end           
        end
        criticalPoint = [1 criticalPoint nScanLinePoint];
end