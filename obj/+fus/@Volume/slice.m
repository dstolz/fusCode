function [s,origIdx,dimOrder] = slice(obj,ind)
% s = slice(Volume,ind)
% [s,origIdx] = slice(Volume,ind)
% [s,origIdx,dimOrder] = slice(Volume,ind)
% 
% Returns all data from indices (voxels) specified in ind.
%
% Inputs:
%   obj     ... fus.Volume object
%   ind     ... [MxN] or [MxNxP] logical matrix, with M rows (y-dim) and N
%               columns (x-dim) equivalent to the plane size.  If the P dim
%               is specified, then it must be the same as then total number
%               of Planes in the Volume (Volume.nPlanes).  If the P dim is
%               not specified, then the 2D input matrix, ind, will be
%               replicated and applied to all Planes.
% 
% Outputs:
%   s       ... [VxA...] numeric matrix, where V is the total number of
%               voxels being returned and is equivalent to nnz(ind), and
%               A... is all remaining dimensions from the Planes.  
%   origIdx ... [Vx3] matrix with the [MxNxP] indicies from ind.  This is
%               equivalent information returned from to a call to
%               ind2sub(obj.volDimSizes,find(ind)).
%   dimOrder... {1xDims} returns the names of the dimensions returned in
%               the output, s.
% 
% DJS 2020

if isnumeric(ind)
    x = false(obj.nYXP);
    x(ind) = true;
    ind = x; clear x
end


assert(any(ndims(ind) == [2 3]), ...
    'fus:Volume:slice:InvalidMatrix', ...
    'ind must be 2 or 3 dimensional');

if ismatrix(ind)
    ind = repmat(ind,[1 1 obj.nPlanes]);
end

[y,x,z] = ind2sub(obj.volDimSizes,find(ind));

uz = unique(z);


s = [];
for i = 1:length(uz)
    pind = uz(i) == z;
    P = obj.Plane(uz(i)); % handle
    
    idx = sub2ind(P.nYX,y(pind),x(pind));
    
    d = reshape(P.Data,[prod(P.nYX) P.dimSizes(3:end)]);
    
    pick = repmat({':'},1,ndims(d));
    pick{1} = idx;    
    
    s = [s; d(pick{:})];
end
s = squeeze(s);

origIdx = [y x z];

dimOrder = [{'Voxels'} P.dimOrder(3:end)];