function explorer(obj,tool)
% explorer(Plane,[roiType])
%
% Plane     ... a single Plane object.
% roiType   ... Determines how to interact with the ROI.
%               valid values: 'circle','rectangle','freehand',
%               'assisted','ellipse', or 'polygon' (default)

% DJS 2020


if nargin < 2 || isempty(tool),  tool = 'Rectangle'; end

mustBeMember(tool,{'Assisted','Circle','Ellipse','Freehand','Polygon','Rectangle'});


f = findobj('type','figure','-and','tag',strcat("ROIfig_", obj.FullName));
if isempty(f)
    f = figure('tag',strcat("ROIfig_", obj.FullName),'name',obj.FullName,'Color','w','NumberTitle','off');
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

title(ax,["Click the image to create an ROI" obj.FullName],'Interpreter','none')

fprintf('Click the image to create an ROI.\nUse right-click for additional options.\n')


roi = images.roi.(tool)('linewidth',2,'color',[1 .8 0], ...
    'deletable',false,'Parent',ax,'FaceSelectable',true, ...
    'Tag',strcat("ROI_", obj.FullName));

draw(roi);


if isempty(roi), return; end

title(ax,obj.FullName,'Interpreter','none')

% start the roi plot
obj.explorer_update(roi);

% listen for changes in roi
addlistener(roi,'MovingROI',@(src,evnt) obj.explorer_update(src,evnt));
addlistener(roi,'ROIMoved', @(src,evnt) obj.explorer_update(src,evnt));

% listen for changes in object properties
addlistener(obj,'Data','PostSet', @(src,evnt) obj.explorer_update(src,evnt));











