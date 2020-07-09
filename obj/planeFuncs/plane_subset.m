function M = plane_subset(M,ind)
% M = plane_subset(M,ind)

n = size(M);

assert(all(size(ind) == n(1:2)), 'plane_subset:DimensionMismatch', ...
    'size(ind) must equal [size(M,1) size(M,2)]')

if length(n) == 2
    M = M(ind);
else    
    M = reshape(M,[prod(n(1:2)) prod(n(3:end))]);
    M = M(ind(:),:);
    M = reshape(M,[nnz(ind) 1 n(3:end)]);
end