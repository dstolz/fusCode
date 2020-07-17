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
    addlistener(obj,'Structural','PostSet',@(src,event) obj.image(src,event,h));
else
    h.CData = obj.Structural;
end

