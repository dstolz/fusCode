function cm = my_colormaps(type,ax,n,interpType)
% cm = my_colormaps(type,ax,n,interpType)
% 
% DJS 2020

if nargin < 1 || isempty(type), type = 'rwb'; end
if nargin < 2, ax = []; end
if nargin < 3 || isempty(n), n = 128; end
if nargin < 4, interpType = 'makima'; end




switch type
    case 'list'
        cm = {'rainbow','coarseRainbow','*any combination of r g b w k c y  m, ex: rwb*'};
        if nargout == 0
            cellfun(@display,cm)
            clear cm
        end
        
        return
    
    case 'rainbow'
        cm = [1 0 0;
              1 .65 0;
              1 1 0;
              0 1 0;
              0 0 1;
              .17 .13 .67;
              .93 .51 .93];
    
    
    case 'coarseRainbow'    
        cm = [0 .49 .76; ...
              .12 .85 .89; ...
              .93 .89 .30; ...
              1.0 .42 0; ...
              .77 .07 0];
        
    otherwise % try builtin map or char colors
        
        if exist(type,'file')
            cm = feval(str2func(type),n);
            interpType = [];
        else
            cm = [];
            for i = 1:length(type)
                switch type(i)
                    case 'r'
                        cm = [cm; 1 0 0];
                    case 'g'
                        cm = [cm; 0 1 0];
                    case 'b'
                        cm = [cm; 0 0 1];
                    case 'w'
                        cm = [cm; 1 1 1];
                    case 'k'
                        cm = [cm; 0 0 0];
                    case 'c'
                        cm = [cm; 0 1 1];
                    case 'y'
                        cm = [cm; 1 1 0];
                    case 'm'
                        cm = [cm; 1 0 1];
                end
            end
        end
end

s = size(cm,1);
if ~isempty(interpType) && s > 1 && s < n
    cm = interp1(1:s,cm,linspace(1,s,n),interpType);
end

cm(cm>1) = 1;
cm(cm<0) = 0;

if ~isempty(ax)
    colormap(ax,cm);
end

if nargout == 0, clear cm; end
