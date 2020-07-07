function align_planes(obj,display)
% align_planes(Volume,display)
%
% Rigid alignment of planes
%
% Updates Plane.spatialTform with affine transformation matrix, but does not
% apply the transform

% DJS 2020

if nargin < 2 || isempty(display), display = true; end

if display
    warning('off','images:imshow:magnificationMustBeFitForDockedFigure');
end

midPlane = round(obj.nPlanes/2);

Plane = obj.Plane; % handles

set(Plane,'useSpatialTform',false);

refPlane = Plane(midPlane).Structural;
for i = midPlane+1:obj.nPlanes
    movingPlane = Plane(i).Structural;
    [tformPlane,tform] = process(movingPlane,refPlane);
    Plane(i).spatialTform = tform;
    if display
        show_steps(refPlane,movingPlane,tformPlane,tform,i,i-1);
    end
    refPlane = tformPlane;
end

refPlane = Plane(midPlane).Structural;
for i = midPlane-1:-1:1
    movingPlane = Plane(i).Structural;
    [tformPlane,tform] = process(movingPlane,refPlane);
    Plane(i).spatialTform = tform;
    if display
        show_steps(refPlane,movingPlane,tformPlane,tform,i,i+1);
    end
    refPlane = tformPlane;
end

set(Plane,'useSpatialTform',true);


if display
    warning('on','images:imshow:magnificationMustBeFitForDockedFigure');
end

function [registered,tform] = process(movingPlane,refPlane)
[optimizer, metric] = imregconfig('monomodal');
% optimizer.MinimumStepLength = 1e-6;
% optimizer.MaximumStepLength = .01;

[nY,nX] = size(movingPlane);

tform = imregtform(movingPlane,refPlane,'rigid',optimizer,metric);
registered = imwarp(movingPlane,tform);

registered = center_crop(registered,[nY nX]);
% win = centerCropWindow2d(size(registered),[nY nX]);
% registered = registered(win.YLimits(1):win.YLimits(2),:);
% registered = registered(:,win.XLimits(1):win.XLimits(2));



function show_steps(refPlane,movingPlane,tformPlane,tform,i,ref)

subplot(131)
imshowpair(refPlane,movingPlane,'falsecolor','scaling','joint');
title(sprintf('Plane %d vs %d (orig)',ref,i))

subplot(132)
imshowpair(movingPlane,tformPlane,'falsecolor','scaling','joint');
title(sprintf('Plane %d Original vs Registered',i));


subplot(133)
imshowpair(refPlane,tformPlane,'falsecolor','scaling','joint');
title(sprintf('Plane %d vs %d (registered)',ref,i))

fprintf('Plane %d aligned to %d\n',i,ref)
disp(tform.T);

pause(0.5)