function align_planes(obj,display)
% align_planes(Volume,display)
%
% Rigid alignment of planes
%
% Updates Plane.spatialTform with affine transformation matrix, but does not
% apply the transform

% DJS 2020

if nargin < 2 || isempty(display), display = true; end


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


if display
    
    f = findobj('type','figure','-and','name','align_planes');
    if isempty(f)
        f = figure('name','align_planes');
    end
    clf(f);
    ax = subplot(211,'parent',f);
    obj.montage(ax);
    ax.Title.String = [obj.Name "original"];
    
    set(Plane,'useSpatialTform',true);
    ax = subplot(212,'parent',f);
    obj.montage(ax);
    ax.Title.String = [obj.Name "warped"];
    
end

function [registered,tform] = process(movingPlane,refPlane)
[optimizer, metric] = imregconfig('monomodal');
% optimizer.MinimumStepLength = 1e-6;
% optimizer.MaximumStepLength = .01;

[nY,nX] = size(movingPlane);

tform = imregtform(movingPlane,refPlane,'rigid',optimizer,metric);
registered = imwarp(movingPlane,tform);

registered = center_crop(registered,[nY nX]);


function show_steps(refPlane,movingPlane,tformPlane,tform,i,ref)

f = findobj('type','figure','-and','name','align_planes');
if isempty(f)
    f = figure('name','align_planes');
end


subplot(311,'Parent',f)
imshowpair(refPlane,movingPlane,'falsecolor','scaling','joint');
title(sprintf('Plane %d vs %d (orig)',ref,i))

subplot(312,'Parent',f)
imshowpair(movingPlane,tformPlane,'falsecolor','scaling','joint');
title(sprintf('Plane %d Original vs Registered',i));

subplot(313,'Parent',f)
imshowpair(refPlane,tformPlane,'falsecolor','scaling','joint');
title(sprintf('Plane %d vs %d (registered)',ref,i))

fprintf('Plane %d aligned to %d\n',i,ref)
disp(tform.T);

pause(0.5)