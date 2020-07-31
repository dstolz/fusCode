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

fgAx = ancestor(fgH,'axes');
bgAx = ancestor(bgH,'axes');

figH = ancestor(fgH,'figure');


mBg = uimenu(figH,'Text','&BG');

uimenu(mBg,'Tag','clim', ...
    'Text',sprintf('Color Limits = %s',mat2str(bgAx.CLim,2)), ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,fgH));

uimenu(mBg,'Tag','colormap', ...
    'Text','Colormap', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,fgH));



mFg = uimenu(figH,'Text','&FG');

uimenu(mFg,'Tag','dataThreshold', ...
    'Text',sprintf('Data &Threshold = %.2f',P.fgPlane.dataThreshold), ...
    'accelerator','T', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj));

uimenu(mFg,'Tag','clim', ...
    'Text',sprintf('Color &Limits = %s',mat2str(fgAx.CLim,2)), ...
    'accelerator','L', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,bgH));


uimenu(mFg,'Tag','alpha', ...
    'Text',sprintf('Transparency (&alpha) = %.2f',max(bgH.AlphaData(:),[],'omitnan')), ...
    'accelerator','A', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,P,bgH));

uimenu(mFg,'Tag','colormap', ...
    'Text','Color&map', ...
    'accelerator','M', ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,P,bgH));




    function mnu_update(src,event,obj,h)
        opts.Resize = 'off';
        opts.Windowstyle = 'modal';
        opts.Interpreter = 'none';
        switch src.Tag
            case 'dataThreshold'
                r = inputdlg('Enter a new data threshold:','Data',1, ...
                    {num2str(obj.Plane(1).fgPlane.dataThreshold)},opts);
                if isempty(r), return; end
                obj.Plane(1).fgPlane.dataThreshold = str2double(r{1});
                src.Text = sprintf('Data &Threshold = %.2f',obj.Plane(1).fgPlane.dataThreshold);
                
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
                src.Text = sprintf('Transparency (&alpha) = %.2f',r);
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