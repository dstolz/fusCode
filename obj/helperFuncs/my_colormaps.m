function cm = my_colormaps(type,n,interpType)

if nargin < 1 || isempty(type), type = 'rwb'; end
if nargin < 2 || isempty(n), n = 128; end
if nargin < 3 || isempty(interpType), interpType = 'makima'; end
switch type
    
    case 'rwb'
        cm = [0 0 1; 1 1 1; 1 0 0];
        
    case 'bwr'
        cm = [1 0 0; 1 1 1; 0 0 1];
        
    case 'rkb'
        cm = [1 0 0; 0 0 0; 0 0 1];
        
    case 'bkr'
        cm = [0 0 1; 0 0 0; 1 0 0];
        
    otherwise % try builtin map
        cm = colormap(feval(str2func(type),n));
        interpFlag = false;
end

if ~isempty(interpType)
    s = size(cm,1);
    cm = interp1(1:s,cm,linspace(1,s,n),interpType);
end

cm(cm>1) = 1;
cm(cm<0) = 0;