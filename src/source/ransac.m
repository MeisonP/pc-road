%--------------------------------------------------------------------------
%Random Sample Consensus(RANSAC)
%Author��Qichao Chen
%Date:20170317
%--------------------------------------------------------------------------


function  [coefficients,percet,pointIndex] = ransac(pointData,shapeType,deviation,permitIterations)
% Random Sample Consensus
% [coefficients,percet,pointIndex] = ransac(pointData,shapeType,deviation,permitIterations)
% INPUT:
% pointData - ��������ݣ������Ƕ�ά�������ݣ������ֻʹ��ǰ��ά
% shapeType - ������ͣ�1һ�ζ�ά���ߡ�2���ζ�ά���ߡ�3���ζ�ά���ߡ�'plane'
%             ƽ����ϡ�'circle'Բ���
% deviation - ����ƫ����
% permitIterations - ����������
%
% OUTPUT:
% coefficients - ��Ͻ����ϵ��
% percet - ��ƫ�����ڵ�Ԫ��ռ�������
% pointIndex - ��ƫ�����ڵ�Ԫ������

if ~exist('permitIterations','var') || isempty(permitIterations),
    permitIterations = 100;
end
   
% deviation = 0.3;
nPoint = size(pointData,1);

% temp = [pointData(1:10,:);pointData(floor(nPoint/2)-10:floor(nPoint/2),:);pointData(nPoint-10:nPoint,:)];
% pointData = temp;
% nPoint = 32;
nSatisfiedPoint = 0;
mostSatisfiedPoint = 0;
iterations = 0;
coefficients = [];
while nSatisfiedPoint < nPoint*2/3 &&  iterations<permitIterations,      %��2/3�����ݷ������ģ�ͻ�ﵽ�����������Ϳ����˳���
    switch shapeType
        case 1
            [nSatisfiedPoint,coefficients,pointIndex]=  ransacline(pointData,deviation);%һ�ζ�ά����
        case 2
            [nSatisfiedPoint,coefficients]=  ransaccurve2(pointData,deviation);%���ζ�ά����
        case 3
            [nSatisfiedPoint,coefficients]=  ransaccurve3(pointData,deviation);%���ζ�ά����
        case 'plane'
            [nSatisfiedPoint,coefficients]=  ransacplane(pointData,deviation);%ƽ�����
        case 'circle'
            [nSatisfiedPoint,coefficients]=  ransaccircle(pointData,deviation);%Բ���
        otherwise
            return;
    end
    if nSatisfiedPoint>mostSatisfiedPoint,            %�ҵ��������ֱ�������������ֱ��
        mostSatisfiedPoint = nSatisfiedPoint;
        bestCoefficients=coefficients;          %�ҵ���õ����ֱ��
    end  
    iterations=iterations+1;
end
 percet = mostSatisfiedPoint/nPoint;%������ϲ����ĵ����
if mostSatisfiedPoint~=0,
    coefficients = bestCoefficients;
else
    %����������
    return;
end
% coefficients=polyfit(pointData(:,1),pointData(:,2),2); %��ͨ��С�������
%     drawresult(pointData,shapeType,coefficients);
end

function drawresult(pointData,shapeType,coefficients)
%��ʾ���������ϵ�����
nPoint = size(pointData,1);
    if shapeType==1,
        for i=1:nPoint
            plot(pointData(i,1),pointData(i,2),'r.');hold on
        end
        %������ϵ�ֱ��
        x = [pointData(1,1) ;pointData(nPoint,1)];
        y = coefficients(1,1)*x+[coefficients(1,2);coefficients(1,2)];
        plot(x,y,'b-');
    elseif shapeType==2,
        for i=1:nPoint
            plot(pointData(i,1),pointData(i,2),'r.');hold on
        end
        %���ƶ�������
        if 1 == size(coefficients,2),
            x= coefficients(1,1)*ones(nPoint,1);
            y = pointData(:,2);
        else
            x = pointData(:,1);
            y = coefficients(1,1).*x.^2+coefficients(1,2).*x+coefficients(1,3).*ones(nPoint,1);
        end
        plot(x,y,'b-');
    elseif strcmp(shapeType,'plane'),
        for i=1:nPoint
            plot3(pointData(i,1),pointData(i,2),pointData(i,3),'r.');hold on
        end
        %����ƽ��
        if pointData(1,1)>pointData(nPoint,1),
            L = pointData(nPoint,1);R=pointData(1,1);
        else
            R =pointData(nPoint,1) ; L=pointData(1,1);
        end
        if pointData(1,2)>pointData(nPoint,2),
            yL = pointData(nPoint,2);yR=pointData(1,2);
        else
            yR =pointData(nPoint,2) ; yL=pointData(1,2);
        end
        [x,y]=meshgrid(L-5:1:R+5,yL-5:1:yR+5);
        a = coefficients(1,1);
        b = coefficients(2,1);
        c = coefficients(3,1);
        z=1/c-(a/c).*x-(b/c).*y;
        surf(x,y,z);
        axis equal;
    elseif strcmp(shapeType,'circle'),
        for i=1:nPoint
            plot(pointData(i,1),pointData(i,2),'r.');hold on
        end
        x0 = coefficients(1,1);
        y0 = coefficients(2,1);
        r = coefficients(3,1);
        pos = [x0-r y0-r 2*r 2*r];
        rectangle('Position',pos,'Curvature',[1 1],'EdgeColor','b');
        axis equal
    end
end

function [nSatisfiedPoint ,coefficients,pointIndex]=  ransacline(pointData,deviation)  
%line
    nPoint = size(pointData,1);
    nSatisfiedPoint = 0;
    SampIndex=floor(1+(nPoint-1)*rand(2,1));  %������������������������ã�floor����ȡ��
    samp(1,:)=pointData(SampIndex(1),1:2);      %��ԭ�������������������
    samp(2,:)=pointData(SampIndex(2),1:2);
    x = samp(:,1);
    y = samp(:,2);
    if x(1,1)~=x(2,1),
        coefficients=polyfit(x,y,1);  
    elseif x(1,1)==x(2,1)&&y(1,1)~=y(2,1),
        %б�������ʱ
        coefficients = x(1,1);
    else
        %����������ͬ�������������
        nSatisfiedPoint = 0;
        coefficients = [];
        pointIndex = [];
        return;
    end
    p1 = samp(1,:);
    p2 = samp(2,:);
    dpp = norm(p2-p1);
    for i = 1:nPoint,
        p =  pointData(i,1:2);
        dist = abs(det([p2-p1;p-p1]))/dpp;
        if dist<deviation,
            nSatisfiedPoint = nSatisfiedPoint+1;
            pointIndex(nSatisfiedPoint) = i;
        end  
    end    
end

function [nSatisfiedPoint ,coefficients]=  ransaccurve2(pointData,deviation)  
%quadratic curve
    nPoint = size(pointData,1);
    nSatisfiedPoint = 0;
    nRand = 0;
    randNum =  floor(1+(nPoint-1)*rand(1,1));
    SampIndex = -ones(3,1);
    while nRand<3,
        rand0 =  floor(1+(nPoint-1)*rand(1,1));
        if rand0~=SampIndex(1,1)&&rand0~=SampIndex(2,1)&&rand0~=SampIndex(3,1),
            nRand = nRand+1;
            SampIndex(nRand,1) = rand0;
        end
    end
    samp(1,:)=pointData(SampIndex(1),1:2);      %��ԭ�������������������
    samp(2,:)=pointData(SampIndex(2),1:2);
    samp(3,:)=pointData(SampIndex(3),1:2);
    x = samp(:,1);
    y = samp(:,2);
    if x(1,1)~=x(2,1)&&x(1,1)~=x(3,1)&&x(2,1)~=x(3,1),
        %���㲻ͬ
        coefficients=polyfit(x,y,1);
    elseif x(1,1)==x(2,1)&&x(1,1)==x(3,1)&&x(2,1)==x(3,1)&&y(1,1)~=y(2,1)&&y(1,1)~=y(3,1)&&y(2,1)~=y(3,1),
        %б�������ʱ
        coefficients = x(1,1);
        dist = abs(pointData(:,1) - coefficients.*ones(nPoint,1));
        for i=1:nPoint,
            if dist(i)<deviation,
                nSatisfiedPoint = nSatisfiedPoint+1;
            end
        end
        return;
    else
        %���ٴ�������������ͬ�������������
        nSatisfiedPoint = 0;
        coefficients = [];
        return;
    end
    
    coefficients=polyfit(x,y,2);    
    a = coefficients(1,1);%�������ߵ�ϵ��
    b = coefficients(1,2);
    c = coefficients(1,3);
    for iPoint = 1:nPoint,
        X = pointData(iPoint,1);
        Y = pointData(iPoint,2);
        coeffi = [2*a^2 3*a*b 2*a*c-2*a*Y+b^2+1 b*c-b*Y-X];%��ֵ���̵�ϵ��
        root = roots(coeffi);
        minDist = -1;
        for i=1:3,
            x = root(i);
            if isreal(x),
                %��ʵ����������̾���Ϊ׼
                x=real(x);%�������루X��Y��������ĵ㣩
                y = a*x^2+b*x+c;
                dist = norm([X-x Y-y]);
                if minDist==-1,
                    minDist=dist;
                elseif dist<minDist,  
                    minDist = dist;
                end
            end
        end
        if minDist<deviation,
            nSatisfiedPoint = nSatisfiedPoint+1;
        end  
    end
end

function [nSatisfiedPoint,coefficients]=  ransacplane(pointData,deviation)  
%plane
    nPoint = size(pointData,1);
    nSatisfiedPoint = 0;
    nRand = 0;
    randNum =  floor(1+(nPoint-1)*rand(1,1));
    SampIndex = -ones(3,1);
    while nRand<3,
        rand0 =  floor(1+(nPoint-1)*rand(1,1));
        if rand0~=SampIndex(1,1)&&rand0~=SampIndex(2,1)&&rand0~=SampIndex(3,1),
            nRand = nRand+1;
            SampIndex(nRand,1) = rand0;
        end
    end
    samp(1,:)=pointData(SampIndex(1),1:3);      %��ԭ�����������3������
    samp(2,:)=pointData(SampIndex(2),1:3);
    samp(3,:)=pointData(SampIndex(3),1:3);
    x = samp(:,1);
    y = samp(:,2);
    h = samp(:,3);
    A = samp;
    b = [1 1 1]';
    r = rank(A);
    if r==3,
        coefficients = A\b;
    else
      %�������㣬�޷�Ψһȷ��ƽ��  
      nSatisfiedPoint = 0;
      coefficients = [];
      return;
    end       
    a1 = coefficients(1,1);%ƽ�淽�̵�ϵ��,Ax+By+Cz+1=0,����[A B C] = [a1 a2 a3]
    a2 = coefficients(2,1);
    a3 = coefficients(3,1);
    a4 = -1;
    x0 = pointData(:,1);
    y0 = pointData(:,2);
    h0 = pointData(:,3);
    dist = abs(a1.*x0+a2.*y0+a3.*h0+a4)./norm([a1 a2 a3]);
    for i=1:nPoint,
        if dist(i)<deviation,
            nSatisfiedPoint = nSatisfiedPoint+1;
        end
    end
end

function [nSatisfiedPoint,coefficients] = ransaccircle(pointData,deviation)
    nPoint = size(pointData,1);
    nSatisfiedPoint = 0;
    coefficients = [];
    index = getsampleindex(nPoint,3);
    samp(1,:)=pointData(index(1),1:2);      %��ԭ�����������3������
    samp(2,:)=pointData(index(2),1:2);
    samp(3,:)=pointData(index(3),1:2);
    x1 = samp(1,1);
    x2 = samp(2,1);
    x3 = samp(3,1);
    y1 = samp(1,2);
    y2 = samp(2,2);
    y3 = samp(3,2);
    a = x1-x2;
    b = y1-y2;
    c = x1-x3;
    d = y1-y3;
    e =((x1^2-x2^2)-(y2^2-y1^2))/2;
    f = ((x1^2-x3^2)-(y3^2-y1^2))/2;
    isCollineation = (det([a b;c d])==0);
    if ~isCollineation,
        x0 = -(d*e-b*f)/(b*c-a*d);
        y0 = -(a*f-c*e)/(b*c-a*d);
        r = norm([x0-x1,y0-y1]);
        coefficients = [x0 y0 r]';
    else
        return;
    end
    x = pointData(:,1);
    y = pointData(:,2);
    dist = abs(sqrt((x-x0).^2+(y-y0).^2)-r);
    for i=1:nPoint,
        if dist(i)<deviation,
            nSatisfiedPoint = nSatisfiedPoint+1;
        end
    end
end

function index = getsampleindex(nPoint,nSample)
%
%��1~nPoint�������ȡnSample�����ظ����񣬷��ض���������
    index = -ones(nSample,1);
    iSample = 0;
    while iSample<nSample,
        rand0 =  floor(1+(nPoint-1)*rand(1,1));
        isSave = true;
        for i = 1:iSample,          
            if rand0==index(i),
                isSave = false;
                break;
            end
        end
        if isSave,
            iSample = iSample+1;
            index(iSample,1) = rand0;
        end
    end
end




