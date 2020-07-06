function h = fus_imtileOverlay(Plane,ax,GridSize)


if nargin < 2 || isempty(ax), ax = gca; end
if nargin < 3, GridSize = fush_GridSize(Plane); end

X = []; P = [];
for i = 1:length(Plane)
    I = Plane(i).I;
    X = cat(3,X,Plane(i).Overlay);
    P = cat(3,P,I.id*ones([I.nY I.nX]));
end
X = imtile(X,'GridSize',GridSize);
P = imtile(P,'GridSize',GridSize);

m = fus_imtileMask(Plane,GridSize);
m(m==0) = nan;
m(m==1) = .5;

ax2 = axes(ax.Parent);

h = imagesc(ax2,X,'AlphaData',m);

ax2.Color = 'none';
axis(ax2,'image');

% dt = datatip(h,'visible','off');
% h.DataTipTemplate.DataTipRows(1) = dataTipTextRow('Plane',P);
% h.DataTipTemplate.DataTipRows(2) = dataTipTextRow('Value',X);
% h.DataTipTemplate.DataTipRows(3:end) = [];



ax2.XAxis.TickValues = [];
ax2.YAxis.TickValues = [];
colorbar(ax2);

drawnow
ax.Position = ax2.Position;
