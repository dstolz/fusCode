function fus_PlaneExplorer(Plane,roiType,logScale)
% fus_PlaneExplorer(Plane,[roiType],[logScale])
%
% Plane     ... a single Plane structure.
% roiType   ... Determines how to interact with the ROI.
%               valid values: 'circle','rectangle','freehand',
%               'assisted','ellipse', or 'polygon' (default)
% logScale  ... Scales image colors logarithmically (default = true)

% DJS 2020


if nargin < 2 || isempty(roiType),  roiType = 'polygon'; end
if nargin < 3 || isempty(logScale), logScale = true;     end


I = Plane.I;

X = Plane.Structural;

if logScale, X = log10(X); end

f = figure('color','w');
f.Position([3 4]) = [500 600];
movegui(f)

ax = axes(f,'Units','Normalized','Position',[.1 .5 .8 .4],'Tag','PlaneImage');


imagesc(ax,X);
axis(ax,'image')
set(ax,'xtick',[],'ytick',[]);
colormap(ax,bone(512))

hold(ax,'on')
plot(ax,I.roiMaskPerimeterXY(:,1),I.roiMaskPerimeterXY(:,2),'.c');
hold(ax,'off')

t = sprintf('%s | Plane %d',I.fileRoot,I.id);
title(ax,t,'Interpreter','none')

fprintf('Click the image to create an ROI.\nUse right-click for additional options.\n')


roi = feval(sprintf('draw%s',lower(roiType)),ax);
roi.Deletable = 0;
roi.LabelVisible = 'off';

if isempty(roi), return; end

update_roi(roi,[],Plane,ax);

addlistener(roi,'MovingROI',@(src,evnt) update_roi(src,evnt,Plane,ax));
addlistener(roi,'ROIMoved',@(src,evnt) update_roi(src,evnt,Plane,ax));