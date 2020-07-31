function [mBg,mFg] = display_menu_fgbg(obj,h)
% [mBg,mFg] = display_menu_fgbg(obj,h)
%
% Create foreground and background display menus
%
% DJS 2020


if isa(obj,'fus.Volume')
    P = obj.Plane(1);
else
    P = obj;
end


fgH = h(ismember({h.Tag},'foreground'));
bgH = h(ismember({h.Tag},'background'));

fgAx = fgH.Parent;
bgAx = bgH.Parent;

figH = ancestor(fgH,'figure');


fgH.HitTest = 'off';

ctm = uicontextmenu(figH);

fgAx.ContextMenu = ctm;



% mFg = uimenu(ctm,'Label','&Foreground');

uimenu(ctm,'Tag','dataThreshold', ...
    'Text',sprintf('Data &Threshold = %.2f',P.fgPlane.dataThreshold), ...
    'accelerator','T', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,fgH));

uimenu(ctm,'Tag','clim', ...
    'Text',sprintf('Color &Limits = %s',mat2str(fgAx.CLim,2)), ...
    'accelerator','L', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,fgH));

uimenu(ctm,'Tag','alpha', ...
    'Text',sprintf('Opacity (&alpha) = %.2f',max(fgH.AlphaData(:),[],'omitnan')), ...
    'accelerator','A', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,fgH));

uimenu(ctm,'Tag','colormap', ...
    'Text','Color&map', ...
    'accelerator','M', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,fgH));

uimenu(ctm,'Tag','popout', ...
    'Text','&Popout', ...
    'accelerator','P', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,fgH));




mBg = uimenu(ctm,'Label','&Background');

uimenu(mBg,'Tag','clim', ...
    'Text',sprintf('Color Limits = %s',mat2str(bgAx.CLim,2)), ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,bgH));

uimenu(mBg,'Tag','colormap', ...
    'Text','Colormap', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,bgH));

end

function mnu_update(src,event,obj,h)

ax = h.Parent;

role = ax.UserData.role;


if isa(obj,'fus.Volume')
    P = obj.Plane(1);
else
    P = obj;
end
opts.Resize = 'off';
opts.Windowstyle = 'modal';
opts.Interpreter = 'none';
switch src.Tag
    case 'dataThreshold'
        r = inputdlg('Enter a new data threshold:','Data',1, ...
            {num2str(P.fgPlane.dataThreshold)},opts);
        if isempty(r), return; end
        P.fgPlane.dataThreshold = str2double(r{1});
        src.Text = sprintf('Data &Threshold = %.2f',P.fgPlane.dataThreshold);
        
    case 'clim'
        r = inputdlg('Set color limits:','Data',1, ...
            {mat2str(ax.CLim,2)},opts);
        if isempty(r), return; end
        r = str2num(r{1}); %#ok<ST2NM>
        ax.CLim = r;
        src.Text = sprintf('Color &Limits = %s',mat2str(ax.CLim,2));
        
    case 'alpha'
        r = inputdlg('Set data opacity (alpha). Value must be between [0 1].','Data',1, ...
            {mat2str(max(h.AlphaData(:),[],'omitnan'),2)},opts);
        if isempty(r), return; end
        r = str2double(r{1});
        a = h.AlphaData;
        a = a ./ max(a(:),[],'omitnan') * r;
        h.AlphaData = a;
        src.Text = sprintf('Opacity (&alpha) = %.2f',r);
        setpref('fus_Plane_display','alpha',r);
        
    case 'colormap'
        if isequal(role,'foreground')
            cm = getpref('fus_Plane_display','fgColormap','parula');
        elseif isequal(role,'background')
            cm = getpref('fus_Plane_display','bgColormap','grey');
        end
        r = inputdlg('Set colormap:','Data',1, ...
            {cm},opts);
        if isempty(r), return; end
        my_colormaps(char(r),ax);
        if isequal(role,'foreground')
            setpref('fus_Plane_display','fgColormap',char(r));
        elseif isequal(role,'background')
            setpref('fus_Plane_display','bgColormap',char(r));
        end
        
    case 'popout'
        cp = round(ax.CurrentPoint(1,1:2));
        pid = ax.UserData.planeIdx(cp(2),cp(1));
        p = obj.Plane(pid);
        figure('Name',p.FullName);
        p.overlay;
        
end
end
