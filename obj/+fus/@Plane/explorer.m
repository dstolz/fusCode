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


figH = findobj('type','figure','-and','tag',strcat("ROIfig_", obj.FullName));
if isempty(figH)
    figH = figure('tag',strcat("ROIfig_", obj.FullName),'name',obj.FullName,'Color','w','NumberTitle','off');
end

figH.Position([3 4]) = [500 600];
movegui(figH)

ax = axes(figH,'Units','Normalized','Position',[.1 .5 .8 .4],'Tag','PlaneImage');

% obj.image(ax);
h = obj.overlay(ax);
ax = h(2).Parent;

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

% setup time plot
axTime = axes(figH,'Units','Normalized','Position',[.2 .1 .7 .3]);

axTime2 = axes(figH,'units','normalized','position',axTime.Position,'color','none', ...
    'ytick',[]);
grid(axTime,'on');

n = obj.num;

axTime.XLim  = [1 n.(obj.timeDimName)];
axTime2.XLim = [0 (n.(obj.timeDimName)-1)/obj.Fs];
axTime.XAxisLocation = 'top';
x = (axTime.XAxis.TickValues-1)/obj.Fs;
axTime2.XAxis.TickValues = x;

box(axTime,'on');

axTime.Tag = 'ROITimePlot'; % for some reason, this needs to be set last???
axTime2.Tag = 'ROITimePlot2';

nEvent = obj.num.(obj.eventDimName);

if nEvent == 1
    cm = [0 0 0];
else
    cm = my_colormaps('coarseRainbow',[],nEvent);
end


line([-1e6 1e6],[0 0],'parent',axTime,'color',[.6 .6 .6],'linewidth',2, ...
    'Tag','zeroline');

for i = 1:nEvent
    hs(i) = line(nan,nan,'color',cm(i,:),'linewidth',2, ...
        'parent',axTime,'tag',sprintf('stimline%d',i), ...
        'DisplayName',sprintf('Event %d',i)); %#ok<AGROW>
end

hl = legend(axTime,hs, ...
    'Location','EastOutside','Orientation','vertical');

if ~isempty(obj.Event)
    hl.String = obj.Event.uValueStr;
    hl.Title.String = obj.Event.Name;
else
    hl.Title.String = 'Event ID';
end
xlabel(axTime,'frame #','FontSize',12)
xlabel(axTime2,'time (s)','FontSize',12)


linkprop([axTime axTime2],{'Position'});

axTime2.YLim = [1 obj.num.(obj.timeDimName)];

% start the roi plot
obj.explorer_update(roi);

% listen for changes in roi
evl(1) = addlistener(roi,'MovingROI',@(src,evnt) obj.explorer_update(src,evnt));
evl(2) = addlistener(roi,'ROIMoved', @(src,evnt) obj.explorer_update(src,evnt));

% listen for changes in object properties
evl(3) = addlistener(obj,'Data','PostSet', @(src,evnt) obj.explorer_update(src,evnt));


set(ax,'DeleteFcn',@(~,~) delete(evl));





m = uimenu(figH,'Text','Time Plot');

uimenu(m,'Tag','ylim', ...
    'Text',sprintf('Y-Axis Limits = %s',mat2str(axTime.YLim,2)), ...
    'MenuSelectedFcn',@(src,event) mnu_update(src,event,obj,axTime));


    function mnu_update(src,event,obj,h) %#ok<INUSL>
        opts.Resize = 'off';
        opts.Windowstyle = 'modal';
        opts.Interpreter = 'none';
        switch src.Tag
            case 'ylim'
                r = inputdlg('Set Y-Axis limits:','Data',1, ...
                    {mat2str(h.YLim,2)},opts);
                if isempty(r), return; end
                h.YLim = str2num(r{1}); %#ok<ST2NM>
                
        end
    end


end