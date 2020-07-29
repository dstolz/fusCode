function remove_outliers(obj,zthr,interpMethod)
% remove_outliers(obj,[zthr],[interpMethod])
% 
% Detect and (optionally) replace outliers using interpolation.  
% 
% Inputs:
%   obj     ... fus.Plane object handle
%   zthr    ... [1x1] z-score threshold. Default = 3.29;
%   interpMethod ... interpolation method. See interp1 for details. 
%                    default = 'makima'
%
% DJS 2020


if nargin < 2 || isempty(zthr), zthr = 3.29; end
if nargin < 3 || isempty(interpMethod), interpMethod = 'makima'; end

mustBePositive(zthr);


n = obj.dimSizes;

s = setdiff(1:length(n),obj.timeDim);
pOrder = [s obj.timeDim];
d = permute(obj.Data,pOrder);

n = size(d);
d = reshape(d,[prod(n(1:end-1)) n(end)]);

d = zscore(d,0,2);

ind = abs(d) > zthr;

nind = any(ind,2) & sum(ind,2) < 3;
if any(nind) && ~isempty(interpMethod) && ~isequal(lower(interpMethod),'none')
    di = d(nind,:);
    ind(~nind,:) = [];
    ni = size(di,2);
    for i = 1:size(di,1)
        x = 1:ni;
        x(ind(i,:)) = [];
        di(i,:) = interp1(x,di(i,~ind(i,:)),1:ni,interpMethod);
    end
end

d(nind,:) = di;

d = reshape(d,n);
d = ipermute(d,pOrder);

obj.update_log('Removed %d outliers. interpolation: "%s"',nnz(ind),interpMethod)

obj.set_Data(d);

