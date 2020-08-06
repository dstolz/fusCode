function explorer(obj,tool) % Volume
% explorer(Volume,[roiType])
%
% Volume    ... a single Volume object.
% roiType   ... Determines how to interact with the ROI.
%               valid values: 'circle','rectangle','freehand',
%               'assisted','ellipse', or 'polygon' (default)

% DJS 2020


if nargin < 2 || isempty(tool),  tool = 'Rectangle'; end

mustBeMember(tool,{'Assisted','Circle','Ellipse','Freehand','Polygon','Rectangle'});


P = obj.Plane(1);

figH = findobj('type','figure','-and','tag',strcat("ROIfig_", obj.Name));
if isempty(figH)
    figH = figure('tag',strcat("ROIfig_", obj.Name),'name',obj.Name,'Color','w','NumberTitle','off');
end

figH.Position([3 4]) = [800 600];
movegui(figH)

ax = axes(figH,'Units','Normalized','Position',[.1 .5 .8 .4],'Tag','PlaneImage');

h = obj.overlay(ax);
ax = h(2).Parent;

% hold(ax,'on')
% h = obj.Mask.draw_overlay(ax);
% h.FaceAlpha = 0;
% h.EdgeAlpha = .5;
% hold(ax,'off')

title(ax,strcat("Click the image to create an ROI - ",obj.Name),'Interpreter','none')

fprintf('Click the image to create an ROI.\nUse right-click for additional options.\n')


roi = images.roi.(tool)('linewidth',2,'color',[1 .8 0], ...
    'deletable',false,'Parent',ax,'FaceSelectable',true, ...
    'Tag',strcat("ROI_", obj.Name));

draw(roi);


if isempty(roi), return; end

title(ax,obj.Name,'Interpreter','none')

% setup time plot
axTime = axes(figH,'Units','Normalized','Position',[.2 .1 .7 .3]);

axTime2 = axes(figH,'units','normalized','position',axTime.Position,'color','none', ...
    'ytick',[]);
grid(axTime,'on');

n = P.num;

axTime.XLim  = [1 n.(P.timeDimName)];
axTime2.XLim = [0 (n.(P.timeDimName)-1)/P.Fs];
axTime.XAxisLocation = 'top';
x = (axTime.XAxis.TickValues-1)/P.Fs;
axTime2.XAxis.TickValues = x;

box(axTime,'on');

axTime.Tag = 'ROITimePlot'; % for some reason, this needs to be set last???
axTime2.Tag = 'ROITimePlot2';


nEvent = P.num.(P.eventDimName);

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

if ~isempty(P.Event)
    hl.String = P.Event.uValueStr;
    hl.Title.String = P.Event.Name;
else
    hl.Title.String = 'Event ID';
end
xlabel(axTime,'frame #','FontSize',12)
xlabel(axTime2,'time (s)','FontSize',12)


linkprop([axTime axTime2],{'Position'});

axTime2.YLim = [1 P.num.(P.timeDimName)];


% start the roi plot
obj.explorer_update(roi,h);


% listen for changes in roi
evl(1) = addlistener(roi,'MovingROI',@(src,evnt) obj.explorer_update(src,evnt,h));
evl(2) = addlistener(roi,'ROIMoved', @(src,evnt) obj.explorer_update(src,evnt,h));

% listen for changes in object properties
evld = addlistener([obj.Plane],'Data','PostSet', @(src,evnt) obj.explorer_update(src,evnt,h));


set(ax,'DeleteFcn',@(~,~) delete(evl));
set(ax,'DeleteFcn',@(~,~) delete(evld));




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