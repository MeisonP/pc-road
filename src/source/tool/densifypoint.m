function densePointData = densifypoint(pointData,step)
 %
 [nPoint,~]= size(pointData);
 interpol = pointData';
% �������߲�ֵ  
t=1:nPoint;  
ts = 1:step:nPoint;  
xys = spline(t,interpol,ts); 
 densePointData = xys';
end