function h = overlay(obj,axBg,thr,gridSize) % fus.Volume


if nargin < 2 || isempty(axBg), axBg = gca; end
if nargin < 3, thr = []; end
if nargin < 4, gridSize = obj.grid_size; end

f = axBg.Parent;


data = [];
for i = 1:obj.nPlanes
    data = cat(3,data,obj.Plane(i).bgPlane.Data);
end

data = imtile(data,'GridSize',gridSize);

h(1) = imagesc(axBg,data);

axBg.XTick = [];
axBg.YTick = [];
colormap(axBg,'gray');

data = [];
for i = 1:obj.nPlanes
    data = cat(3,data,obj.Plane(i).fgPlane.Data);
end

if isempty(thr)
    thr = median(data(:),'omitnan');
end
data = imtile(data,'GridSize',gridSize);

axFg = axes(f);

aind = data >= thr;
h(2) = imagesc(axFg,data,'AlphaData',aind*.75);

axFg.Color = 'none';
axFg.XTick = [];
axFg.YTick = [];

colormap(axFg,'parula');
colorbar(axFg);

axis(axBg,'image');
axis(axFg,'image');


axBg.Position = axFg.Position;

axFg.Title.String = obj.Name;
axFg.Title.Interpreter = 'none';

linkaxes([axBg axFg]);
linkprop([axBg axFg],{'Position'});



if nargout == 0, clear h; end





