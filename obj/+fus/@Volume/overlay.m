function h = overlay(obj,axBg,gridSize,fgData,thr,watch) % fus.Volume
% [h] = overlay(Volume,[ax],[gridSize],[fgData],[thr],[watch])
%
% example
%   V.overlay(gca,[V.nPlanes 1])
% 
% DJS 2020


if nargin < 2 || isempty(axBg), axBg = gca; end
if nargin < 3, gridSize = obj.grid_size; end
if nargin < 4, fgData = []; end
if nargin < 5, thr = []; end
if nargin < 6 || isempty(watch), watch = true; end



figH = axBg.Parent;


bgData = []; planeIdx = 1;
for i = 1:obj.nPlanes
    if isempty(obj.Plane(i).bgPlane)
        d = nan(obj.Plane(i).nYX);
    else
        d = obj.Plane(i).bgPlane.Data;
    end
    bgData = cat(3,bgData,d);
    planeIdx(end+1) = numel(bgData);
end

bgData = imtile(bgData,'GridSize',gridSize);

h(1) = imagesc(axBg,bgData,'Tag','background');
clear bgData

axBg.XTick = [];
axBg.YTick = [];
axBg.Tag = 'background';

bgCM = getpref('fus_Plane_display','bgColormap','gray');

my_colormaps(bgCM,axBg);



if isempty(fgData)
    fgData = [];
    for i = 1:obj.nPlanes
        if isempty(obj.Plane(i).fgPlane)
            d = nan(obj.Plane(i).nYX);
        else
            d = obj.Plane(i).fgPlane.Data;
        end
        fgData = cat(3,fgData,d);
    end
end


if isempty(thr)
    thr = median(fgData(:),'omitnan');
end
fgData = imtile(fgData,'GridSize',gridSize);

axFg = axes(figH);

alpha = getpref('fus_Plane_display','alpha',.75);

aind = fgData >= thr;
if nnz(aind) == 0
    fprintf('%s: Note that no foreground voxels have values >= %.2f\n',obj.Name,thr)
    ctxmsg
end
h(2) = imagesc(axFg,fgData,'AlphaData',aind*alpha,'Tag','foreground');

axFg.Color = 'none';
axFg.XTick = [];
axFg.YTick = [];
axFg.Tag = 'foreground';

fgCM = getpref('fus_Plane_display','fgColormap','parula');

my_colormaps(fgCM,axFg);


axFg.Title.String = obj.Name;
axFg.Title.Interpreter = 'none';

axis(axBg,'image');
axis(axFg,'image');


if ~all(isnan(fgData(:)))
    ch = colorbar(axFg);
    ch.Label.String = obj.Plane(1).fgPlane.Name;
    ch.Label.FontWeight = 'bold';
end



axFg.UserData.obj = [obj.Plane.fgPlane];
axFg.UserData.gridSize = gridSize;
axFg.UserData.partner = axBg;
axFg.UserData.role = 'foreground';
axFg.UserData.planeIdx = planeIdx;

axBg.UserData.obj = [obj.Plane.bgPlane];
axBg.UserData.gridSize = gridSize;
axBg.UserData.partner = axFg;
axBg.UserData.role = 'background';

linkaxes([axBg axFg]);
linkprop([axBg axFg],{'Position'});




if watch
    % listen for changes in object properties
    evl1 = addlistener([obj.Plane.fgPlane obj.Plane.bgPlane],'Data','PostSet', @(src,event) obj.overlay_update(src,event,h));
    evl2 = addlistener([obj.Plane.fgPlane],'dataThreshold','PostSet', @(src,event) obj.overlay_update(src,event,h));
    
    set([axBg axFg],'DeleteFcn',@(~,~) delete([evl1; evl2]));
end


display_menu_fgbg(obj,h);

if nargout == 0, clear h; end



function ctxmsg
disp('Right click the plot for options')