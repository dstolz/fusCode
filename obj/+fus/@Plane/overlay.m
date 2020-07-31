function h = overlay(obj,axBg,thr,watch) % fus.Plane
% [h] = overlay(Plane,a[xBg],[thr],[watch])
%
% example:
%   
% 
% DJS 2020





if nargin < 2 || isempty(axBg), axBg = gca; end
if nargin < 3, thr = obj.fgPlane.dataThreshold; end
if nargin < 4 || isempty(watch), watch = true; end



figH = axBg.Parent;


h(1) = imagesc(axBg,obj.bgPlane.Data,'Interpolation','bilinear','Tag','background');
axBg.XTick = [];
axBg.YTick = [];
axBg.Tag = 'background';
axBg.UserData = obj.bgPlane;

bgCM = getpref('fus_Plane_display','bgColormap','gray');

my_colormaps(bgCM,axBg);



axFg = axes(figH);

% TODO Needs checking for dimensional agreement with bg (?)
if isempty(thr)
    thr = median(obj.fgPlane.Data(:),'omitnan');
end

alpha = getpref('fus_Plane_display','alpha',.75);

aind = obj.fgPlane.Data >= thr;
if nnz(aind) == 0
    fprintf('%s: Note that no foreground voxels have values >= %.2f\n',obj.FullName,thr)
    ctxmsg
end
h(2) = imagesc(axFg,obj.fgPlane.Data,'AlphaData',aind*alpha,'Tag','foreground');

axFg.Color = 'none';
axFg.XTick = [];
axFg.YTick = [];
axFg.Tag = 'foreground';
axFg.UserData = obj.fgPlane;

fgCM = getpref('fus_Plane_display','fgColormap','parula');

my_colormaps(fgCM,axFg);



if ~all(isnan(obj.fgPlane.Data(:)))
    ch = colorbar(axFg);
    ch.Label.String = obj.fgPlane.Name;
    ch.Label.FontWeight = 'bold';
end



axFg.Title.String = obj.FullName;
axFg.Title.Interpreter = 'none';


linkaxes([axBg axFg]);
linkprop([axBg axFg],{'Position'});

axis(axFg,'image');
axis(axBg,'image');

if watch
    % listen for changes in object properties
    evl1 = addlistener([obj.fgPlane obj.bgPlane],'Data','PostSet', @(src,event) obj.overlay_update(src,event,h));
    evl2 = addlistener(obj.fgPlane,'dataThreshold','PostSet', @(src,event) obj.overlay_update(src,event,h));
    set([axBg axFg],'DeleteFcn',@(~,~) delete([evl1; evl2]));
end


display_menu_fgbg(obj,h);



if nargout == 0, clear h; end



function ctxmsg
disp('Right click the plot for options')









