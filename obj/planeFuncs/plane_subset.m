function R = plane_subset(A,ind)
% R = plane_subset(A,ind)
% 
% Returns a subset of n-dimensional matrix A using the 2D logical matrix,
% ind.  Dims of ind must be equal to the first two dims of A, but A can
% have any number of additional dimensions.
%
% The return matrix, R, has ndims(A)-1 dimensions, with the first dimension
% containing all indices from the first two dimensions of A.
% 
% Complementary to reconstruct.m

% DJS 2020

n = size(A);

assert(all(size(ind) == n(1:2)), 'plane_subset:DimensionMismatch', ...
    'size(ind) must equal [size(M,1) size(M,2)]')

  
A = reshape(A,[prod(n(1:2)) prod(n(3:end))]);
A = A(ind(:),:);
R = reshape(A,[nnz(ind) 1 n(3:end)]);
