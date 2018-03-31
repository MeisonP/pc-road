function fittedPointData = curvefit(pointData)
%�Թ켣�߷ֶ����,������10�׼�����׶���ʽ���
%     segmentArray = zeros(nCenterPoint/10,1);
    fitDist =10;%�ֶ���Ͼ���
    interpolationNum = 100;
%     pointCloudFilePath = 'dataspace\traceData_notfit.xyz';
%     pointData = readpointcloudfile2(pointCloudFilePath);
  
    segmentArray(1) = 1;%�洢�ֶε��˳���
    iSegmentArray = 1;
    preX = pointData(1,1);
    preY = pointData(1,2);
    nPoint = size(pointData,1);  
%     plot(pointData(1:500,1),pointData(1:500,2),'r.');
%     axis equal;
  
    for i = 2:nPoint,
    %�����뽫����ϵ�ֳ����ɶ�
        x = pointData(i,1);
        y = pointData(i,2);
        %�켣��֮��ļ������
        dist = sqrt((x-preX)^2+(y-preY)^2);
        if dist>fitDist,
            iSegmentArray = iSegmentArray+1;
            segmentArray(iSegmentArray) = i;
            preX = x;
            preY = y;
        end      
    end
    segmentArray(iSegmentArray) = nPoint;
    %���֮���ÿһ���ڲ��
    %����������Ȼ���һ����϶ο���С��fitDist������Ȼ�ڲ�interpolationNum����
    fittedPointData = zeros((iSegmentArray-1)*interpolationNum,2);
    for i=1:iSegmentArray-1,
        nStart = segmentArray(i);
        nEnd = segmentArray(i+1);
        traceTemp = pointData(nStart:nEnd,:);
        xdata = traceTemp(:,1);
        ydata = traceTemp(:,2);
        hdata = traceTemp(:,3);
        p=polyfit(xdata,ydata,2);
        syms d(varX);
        d(varX) = diff(p(1)*varX^2+p(2)*varX+p(3));%��ϵĶ��׶���ʽ��Ӧ��һ�׵���
        %�ȷֳ����ɸ����
        x1 = linspace(pointData(nStart,1),pointData(nEnd,1),interpolationNum);
        y1 = polyval(p,x1);
%         plot(x1,y1,'r-')
%         hold on
        step = (nEnd-nStart)/interpolationNum;
        for m =1:interpolationNum,
            temp = ceil(step*m);      
            h(m) = hdata(temp);
        end
        fragmentFittedPointData = [x1' y1' h'];%���ζ���ʽ��Ϻ��ֵ���
        fittedPointData((i-1)*interpolationNum+1:i*interpolationNum,1:3) ...
            = fragmentFittedPointData;        
        if i==1,
            %�˴�ʹ����һ��2/3���Ĳ�ֵ�㣬���߶���ӵĶ˵㣬��һ��1/3����ֵ������
            %������Ϊ������ϵ�
            %���ȷ����ĸ���,��������
%             SmoothFittedPointData(1:floor(interpolationNum*(2/3)),1:3) ...
%             = fragmentFittedPointData(1:floor(interpolationNum*(2/3)),1:3);
            currentFragmentFittedPointData = fragmentFittedPointData;
            interpolationX3 = ...
                fragmentFittedPointData(ceil(interpolationNum*(2/3)),1);
            interpolationY3 = ...
                fragmentFittedPointData(ceil(interpolationNum*(2/3)),2);
            derivativeP3 = d(interpolationX3);
            interpolationX4 = ...
                fragmentFittedPointData(interpolationNum,1);
            interpolationY4 = ...
                fragmentFittedPointData(interpolationNum,2);        
        else
            preFragmentFittedPointData = currentFragmentFittedPointData;
            currentFragmentFittedPointData = fragmentFittedPointData;
            interpolationPreX3 = interpolationX3;
            interpolationPreY3 = interpolationY3;
            derivativePreP3 = derivativeP3;
            interpolationPreX4 = interpolationX4;
            interpolationPreY4 = interpolationY4;      
            interpolationX1 = ...
                fragmentFittedPointData(1,1);
            interpolationY1 = ...
                fragmentFittedPointData(1,2);
            interpolationX2 = ...
                fragmentFittedPointData(ceil(interpolationNum*(1/3)),1);
            interpolationY2 = ...
                fragmentFittedPointData(ceil(interpolationNum*(1/3)),2);
            derivativeP2 = d(interpolationX2);
            interpolationX3 = ...
                fragmentFittedPointData(ceil(interpolationNum*(2/3)),1);
            interpolationY3 = ...
                fragmentFittedPointData(ceil(interpolationNum*(2/3)),2);
            derivativeP3 = d(interpolationX3);
            interpolationX4 = ...
                fragmentFittedPointData(interpolationNum,1);
            interpolationY4 = ...
                fragmentFittedPointData(interpolationNum,2);
            interpolationX = ...
                [interpolationPreX3 (interpolationPreX4+interpolationX1)/2 interpolationX2];
            interpolationY = ...
                [interpolationPreY3 (interpolationPreY4+interpolationY1)/2 interpolationY2];
            cs = spline(interpolationX,[double(derivativePreP3) interpolationY double(derivativeP2)]);
            xx1 = preFragmentFittedPointData(ceil(interpolationNum*(2/3)):interpolationNum,1);
            xx2 = currentFragmentFittedPointData(1:ceil(interpolationNum*(1/3)),1);
            xx = [xx1;xx2];
            interpolationDataY = ppval(cs,xx);
            interpolationStart = (i-2)*interpolationNum+ceil(interpolationNum*(2/3));
            interpolationEnd = (i-1)*interpolationNum+ceil(interpolationNum*(1/3));
            fittedPointData(interpolationStart:interpolationEnd,1:2) = ...
                [xx interpolationDataY];    
            a=0;                     
        end           
%         plot(xdata,ydata,'.')
%         hold on
%         plot(x1,y1,'r-')
%         plot(xx,interpolationDataY,'g-')
%         axis equal;
    end    
%     savepointcloud2file(fittedPointData,'dataspace\fittedPointData',false);   
end
