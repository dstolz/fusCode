function varargout = estimate_hr(obj,eventOnset,stdThresh)
% hr = estimate_hr(Volume,[eventOnset],[stdThresh])
% hr = estimate_hr(Plane,...)
% [hr,stdev] = estimate_hr(...)
%
% Estimate of the mean haemodynamic response function (Boubenec et al,
% 2018):
% Convert all within-mask samples of each plane to z-score, threshold for
% peak responses greater than or equal to stdThresh standard deviations, 
% compute the average of these responses.
%
%
% Inputs:
%   obj        ... either one fus.Volume or one or more fus.Plane objects
%   eventOnset ... 1x1 indicating the time at which the impulse event
%                  occurs relative to trial onset.   
%                  default eventOnset = 0, which is unlikely the case!
%   stdThresh  ... standard deviation threshold. default = [3 6];
%                  If 1x1: responses >= stdThresh are included in hr estimate.
%                  If 1x2: responses >= stdThresh(1) & responses < stdThresh(2)
%                          are included in hr estimate.
%
% Output:
%   hr         ... mean estimate of the haemodynamic response.
%   stdev      ... standard deviation of hr estimate.
%
% Note that the returned waveform is the entire timecourse which likely
% includes pre-response fluctuations that should be removed prior to
% convolution with experiment design.
%
% Note that the threshold is only of the maximum response, not the
% abs(max), so large negative fluctuations are ignored.

% DJS 2020


if nargin < 2 || isempty(eventOnset)
    eventOnset = 0;
    warning('Default event onset = 0!')
end
if nargin < 3 || isempty(stdThresh), stdThresh = 3; end

if isa(obj,'fus.Volume')
    P = obj.Plane; % handles
else
    P = obj; % handles
end

eventIdx = find(obj.Time >= eventOnset,1);

hr = [];
for i = 1:length(P)
    M = mean(P(i).Data,setdiff(1:P(i).nDims,[1 2 P(i).dim.(P(i).TimeDim)]));
    M = squeeze(reshape(M,[prod(P(i).nYX) P(i).num.(P(i).TimeDim)]));
    M(any(isnan(M),2),:) = [];
    M = zscore(squeeze(M),0,'all');
    hr = [hr; M(:,eventIdx:end)];
end

mx = max(hr,[],2);
if numel(stdThresh) == 1
    ind = mx >= stdThresh;
else
    ind = mx >= stdThresh(1) & mx < stdThresh(2);
end

hr = hr(ind,:);
varargout{1} = mean(hr)';
varargout{2} = std(hr)';






