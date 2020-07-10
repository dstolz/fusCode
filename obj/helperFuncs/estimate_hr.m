function hr = estimate_hr(obj,stdThresh)
% hr = estimate_hr(Volume,[zThreshold])
% hr = estimate_hr(Plane,[zThreshold]

if nargin < 3 || isempty(stdThresh), stdThresh = 3; end

if isa(obj,'fus.Volume')
    P = obj.Plane; % handles
else
    P = obj; % handles
end


hr = [];
for i = 1:length(P)
    M = mean(P(i).Data,setdiff(1:P(i).nDims,[1 2 P(i).dim.(P(i).TimeDim)]));
    M = squeeze(reshape(M,[prod(P(i).nYX) P(i).num.(P(i).TimeDim)]));
    M(any(isnan(M),2),:) = [];
    M = zscore(M,0,'all');
    hr = [hr; squeeze(M)];
end

hr = mean(hr(max(hr,[],2) < stdThresh,:));

