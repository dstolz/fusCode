function h = overlay(obj,axBg,thr) % fus.Plane
% [h] = overlay(obj,a[xBg],[thr])
%
% DJS 2020





if nargin < 2 || isempty(axBg), axBg = gca; end
if nargin < 3, thr = obj.fgPlane.dataThreshold; end




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
h(2) = imagesc(axFg,obj.fgPlane.Data,'AlphaData',aind*alpha,'Tag','foreground');

axFg.Color = 'none';
axFg.XTick = [];
axFg.YTick = [];
axFg.Tag = 'foreground';
axFg.UserData = obj.fgPlane;

fgCM = getpref('fus_Plane_display','fgColormap','parula');

my_colormaps(fgCM,axFg);




if ~all(isnan(obj.fgPlane.Data(:)))
    colorbar(axFg);
end

axis(axBg,'image');
axis(axFg,'image');


axFg.Title.String = strcat(obj.FullName,' - ',obj.fgPlane.Name);
axFg.Title.Interpreter = 'none';


linkaxes([axBg axFg]);
linkprop([axBg axFg],{'Position'});


% listen for changes in object properties
evl(1) = addlistener(obj.fgPlane,'Data','PostSet', @(src,event) obj.overlay_update(src,event,h));
evl(2) = addlistener(obj.fgPlane,'dataThreshold','PostSet', @(src,event) obj.overlay_update(src,event,h));

set([axBg axFg],'DeleteFcn',@(~,~) delete(evl));





m = uimenu(figH,'Text','&Background');

uimenu(m,'Tag','clim', ...
    'Text',sprintf('Color Limits = %s',mat2str(axFg.CLim,2)), ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,h(1)));

uimenu(m,'Tag','colormap', ...
    'Text','Colormap', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,h(1)));



m = uimenu(figH,'Text','&Foreground');

uimenu(m,'Tag','dataThreshold', ...
    'Text',sprintf('Data &Threshold = %.2f',obj.fgPlane.dataThreshold), ...
    'accelerator','T', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj));

uimenu(m,'Tag','clim', ...
    'Text',sprintf('Color &Limits = %s',mat2str(axFg.CLim,2)), ...
    'accelerator','L', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,h(2)));


uimenu(m,'Tag','alpha', ...
    'Text',sprintf('Transparency (&alpha) = %.2f',max(h(2).AlphaData(:),[],'omitnan')), ...
    'accelerator','A', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,h(2)));

uimenu(m,'Tag','colormap', ...
    'Text','Color&map', ...
    'accelerator','M', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,h(2)));


if nargout == 0, clear h; end


    
    function mnu_update(src,event,obj,h)
        opts.Resize = 'off';
        opts.Windowstyle = 'modal';
        opts.Interpreter = 'none';
        switch src.Tag
            case 'dataThreshold'
                r = inputdlg('Enter a new data threshold:','Data',1, ...
                    {num2str(obj.fgPlane.dataThreshold)},opts);
                if isempty(r), return; end
                obj.fgPlane.dataThreshold = str2double(r{1});
                src.Text = sprintf('Data &Threshold = %.2f',obj.fgPlane.dataThreshold);
                
            case 'clim'
                r = inputdlg('Set color limits:','Data',1, ...
                    {mat2str(h.Parent.CLim)},opts);
                if isempty(r), return; end
                r = str2num(r{1}); %#ok<ST2NM>
                h.Parent.CLim = r;
                
            case 'alpha'
                r = inputdlg('Set transparency (alpha). Value must be between [0 1].','Data',1, ...
                    {mat2str(max(h.AlphaData(:),[],'omitnan'))},opts);
                if isempty(r), return; end
                r = str2num(r{1}); %#ok<ST2NM>
                a = h.AlphaData;
                a = a ./ max(a(:),[],'omitnan') * r;
                h.AlphaData = a;
                setpref('fus_Plane_display','alpha',r);
                
            case 'colormap'
                if isequal(h.Parent.UserData.role,'foreground')
                    cm = getpref('fus_Plane_display','fgColormap','parula');
                elseif isequal(h.Parent.UserData.role,'background')
                    cm = getpref('fus_Plane_display','bgColormap','grey');
                end
                r = inputdlg('Set colormap:','Data',1, ...
                    {cm},opts);
                if isempty(r), return; end
                my_colormaps(char(r),h.Parent);
                if isequal(h.Parent.UserData.role,'foreground')
                    setpref('fus_Plane_display','fgColormap',char(r));
                elseif isequal(h.Parent.UserData.role,'background')
                    setpref('fus_Plane_display','bgColormap',char(r));
                end
        end
    end
end












