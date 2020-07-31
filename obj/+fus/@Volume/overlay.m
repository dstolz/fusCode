function h = overlay(obj,axBg,gridSize,thr) % fus.Volume
% [h] = overlay(Volume,[ax],[gridSize],[thr])
%
% example
%   V.overlay(gca,[V.nPlanes 1])
% 
% DJS 2020


if nargin < 2 || isempty(axBg), axBg = gca; end
if nargin < 3, gridSize = obj.grid_size; end
if nargin < 4, thr = []; end




figH = axBg.Parent;


data = [];
for i = 1:obj.nPlanes
    if isempty(obj.Plane(i).bgPlane)
        d = nan(obj.Plane(i).nYX);
    else
        d = obj.Plane(i).bgPlane.Data;
    end
    data = cat(3,data,d);
end

data = imtile(data,'GridSize',gridSize);

h(1) = imagesc(axBg,data,'Tag','background');

axBg.XTick = [];
axBg.YTick = [];
axBg.Tag = 'background';

bgCM = getpref('fus_Plane_display','bgColormap','gray');

my_colormaps(bgCM,axBg);





data = [];
for i = 1:obj.nPlanes
    if isempty(obj.Plane(i).fgPlane)
        d = nan(obj.Plane(i).nYX);
    else
        d = obj.Plane(i).fgPlane.Data;
    end
    data = cat(3,data,d);
end

if isempty(thr)
    thr = median(data(:),'omitnan');
end
data = imtile(data,'GridSize',gridSize);

axFg = axes(figH);

alpha = getpref('fus_Plane_display','alpha',.75);

aind = data >= thr;
h(2) = imagesc(axFg,data,'AlphaData',aind*alpha,'Tag','foreground');

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


if ~all(isnan(data(:)))
    ch = colorbar(axFg);
    ch.Label.String = obj.Plane(1).fgPlane.Name;
    ch.Label.FontWeight = 'bold';
end



axFg.UserData = obj.Plane(1).fgPlane;
axBg.UserData = obj.Plane(1).bgPlane;

linkaxes([axBg axFg]);
linkprop([axBg axFg],{'Position'});





% listen for changes in object properties
evl1 = addlistener([obj.Plane.fgPlane obj.Plane.bgPlane],'Data','PostSet', @(src,event) obj.overlay_update(src,event,h));
evl2 = addlistener([obj.Plane.fgPlane],'dataThreshold','PostSet', @(src,event) obj.overlay_update(src,event,h));

set([axBg axFg],'DeleteFcn',@(~,~) delete([evl1; evl2]));



display_menu_fgbg(obj,h);

if nargout == 0, clear h; end
