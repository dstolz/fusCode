function h = image(obj,varargin)
% h = image(obj,[ax])

h = [];
if length(varargin) > 1
    h  = varargin{3};
elseif length(varargin) == 1
    ax = varargin{1};
else
    ax = gca;
end

if isempty(h)
    h = imagesc(ax,obj.Structural);
    axis(ax,'image')
    set(ax,'xtick',[],'ytick',[]);
    colormap(ax,bone(512))
    evl = addlistener(obj,'Structural','PostSet',@(src,event) obj.image(src,event,h));
    set(ax,'DeleteFcn',@(~,~) delete(evl));

else
    h.CData = obj.Structural;
end

ax.Title.String = obj.FullName;
ax.Title.Interpreter = 'none';