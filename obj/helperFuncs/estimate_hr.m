function hr = estimate_hr(obj,stdThresh)
% hr = estimate_hr(Volume,[zThreshold])
% hr = estimate_hr(Plane,[zThreshold]
%
% Estimate of the mean haemodynamic response function (Boubenec et al,
% 2018):
% Convert all within-mask samples of each plane to z-score, threshold for
% peak responses greater than or equal to stdThresh standard deviations, 
% compute the average of these responses.
%
% Note that the returned waveform is the entire timecourse which likely
% includes pre-response fluctuations that should be removed prior to
% convolution with experiment design.
%
%
% Inputs:
%   obj        ... either one fus.Volume or one or more fus.Plane objects
%   stdThresh  ... standard deviation threshold (default = 3);
%
% Output:
%   hr         ... mean estimate of the haemodynamic response.

% DJS 2020



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

