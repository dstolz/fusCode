function explorer(obj,tool,logScale)
% explorer(Plane,[roiType],[logScale])
%
% Plane     ... a single Plane object.
% roiType   ... Determines how to interact with the ROI.
%               valid values: 'circle','rectangle','freehand',
%               'assisted','ellipse', or 'polygon' (default)
% logScale  ... Scales image colors logarithmically (default = true)

% DJS 2020


if nargin < 2 || isempty(tool),  tool = 'Rectangle'; end
if nargin < 3 || isempty(logScale), logScale = true;       end

mustBeMember(tool,{'Assisted','Circle','Ellipse','Freehand','Polygon','Rectangle'});

X = obj.Structural;

if logScale, X = log10(X); end

f = findobj('type','figure','-and','tag',['ROIfig_' obj.Name]);
if isempty(f)
    f = figure('tag',['ROIfig_' obj.Name],'name',obj.Name,'Color','w');
end

f.Position([3 4]) = [500 600];
movegui(f)

ax = axes(f,'Units','Normalized','Position',[.1 .5 .8 .4],'Tag','PlaneImage');

obj.image(ax);

hold(ax,'on')
h = obj.Mask.draw_overlay(ax);
h.FaceAlpha = 0;
h.EdgeAlpha = .5;
hold(ax,'off')

t = sprintf("Plane %d",obj.id);
title(ax,["Click the image to create an ROI" t],'Interpreter','none')

fprintf('Click the image to create an ROI.\nUse right-click for additional options.\n')


roi = images.roi.(tool)('linewidth',2,'color',[1 .8 0], ...
    'deletable',false,'Parent',ax,'FaceSelectable',true, ...
    'Tag',['ROI_' obj.Name]);

draw(roi);


if isempty(roi), return; end

title(ax,t,'Interpreter','none')

% start the roi plot
obj.explorer_update(roi);

% listen for changes in roi
addlistener(roi,'MovingROI',@(src,evnt) obj.explorer_update(src,evnt));
addlistener(roi,'ROIMoved', @(src,evnt) obj.explorer_update(src,evnt));

% listen for changes in object properties
addlistener(obj,'Data','PostSet', @(src,evnt) obj.explorer_update(src,evnt));











