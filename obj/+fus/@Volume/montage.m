function [X,h] = montage(obj,ax,varargin)
% [X,h] = montage(obj,ax,varargin)
%
% 'name','value' options
% datafield     ... which Plane subfield to display, default = 'Structural'
% display       ... true|false, default = true
% transformfcn  ... handle to tranform function, default = @log10
% maskalpha     ... scalar value between [0 1] determines out opaque to
%                   make the background, default = .8;
%
% Output
% X     ... tiled data used to create the image.
% h     ... handle to the image object

% DJS 2020

if nargin < 2 || isempty(ax), ax = gca; end


opts.datafield     = 'Structural';
opts.display       = true;
opts.transformfcn  = @log10;
opts.maskalpha     = .5;

for i = 1:2:length(varargin)
    opts.(lower(varargin{i})) = varargin{i+1};
end

Plane = obj.Plane(obj.active);

X = [];
for i = 1:length(Plane)
    X = cat(3,X,Plane(i).(opts.datafield)); 
end
X = opts.transformfcn(X);

% X = (X - min(X(:))) ./ (max(X(:)) - min(X(:))); % -> [0 1]

[nrow,ncol] = obj.grid_size;
X = imtile(X,'GridSize',[nrow,ncol]);

if opts.display
    h = imagesc(X,'parent',ax);
    axis(ax,'image');
    set(ax,'CLim',[.01 .99]);
    colormap(ax,bone(512))
    
%     fg = fus_imtileMask(Plane,[nrow ncol]);
%     fg(fg==0) = opts.maskalpha;
%     h.AlphaData = fg;

    [y,x] = size(X);
    xint = x/ncol;
    x = 1:xint:ncol*xint;
    yint = y/nrow;
    y = 5:yint:nrow*yint;
    
    k = 1;
    for j = 1:nrow
        for i = 1:ncol
            t(i,j) = text(ax,x(i),y(j),sprintf('%d',Plane(k).id),'Color','w');
            k = k + 1;
            if k > length(Plane), break; end
        end
        if k > length(Plane), break; end
    end
    ax.XAxis.TickValues = [];
    ax.YAxis.TickValues = [];
    ax.Title.String = obj.Name;
    ax.Title.Interpreter = 'none';   
end


if nargout == 0, clear X h; end


