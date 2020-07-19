function M = reconstruct_data(obj,data,fillValue)
% M = reconstruct_data(obj,data,[fillValue])
%
% Convenient function that reconstructs masked data in the format of
% [M x ...], where M is the total number of pixels in a Plane and ... is any
% number of additional dimensions.
%
% The returned matrix, M, will have [Y x X x ...] dims.
%
% Inputs:
%   obj       ... fus.Plane object corresponding to data
%   data      ... [M x ...] matrix as described above.
%   fillValue ... if obj.useMask is true, then non-mask pixels are set to
%                 this value. default = nan;

if nargin < 3 || isempty(fillValue), fillValue = nan; end

n = size(data);

M = zeros([prod(obj.nYX) n(2:end)],'like',data);

v = [{obj.Mask.mask} repmat({':'},1,length(n)-1)];
M(v{:}) = data;

if obj.useMask
    v = [{~obj.Mask.mask} repmat({':'},1,length(n)-1)];
    M(v{:}) = fillValue;
end

M = reshape(M,[obj.nYX n(2:end)]);
