function varargout = estimate_hr(obj,eventOnset,maxHRDur,stdThresh)
% hr = estimate_hr(Volume,[eventOnset],[maxHRDur],[stdThresh])
% hr = estimate_hr(Plane,...)
% [hr,stdev] = estimate_hr(...)
% [hr,stdev,n] = estimate_hr(...)
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
%   eventOnset ... 1xN indicating the times at which the impulse event
%                  occurs relative to trial onset (in seconds).
%                  default eventOnset = 0, which is unlikely to be the case!
%   maxHRDur   ... 1x1 indicating the maximum duration of a haemodynamic
%                  response in seconds; default = 10
%   stdThresh  ... standard deviation threshold. default = [3 6];
%                  If 1x1: responses >= stdThresh are included in hr estimate.
%                  If 1x2: responses >= stdThresh(1) & responses < stdThresh(2)
%                          are included in hr estimate.
%
% Output:
%   hr         ... mean estimate of the haemodynamic response.
%   stdev      ... standard deviation of hr estimate.
%   n          ... number of waveforms averaged into haemodynamic response
%                  estimate.
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
    warning('estimate_hr:EventOnsetAt0','Default event onset = 0!')
end
if nargin < 3 || isempty(maxHRDur),  maxHRDur = 10; end
if nargin < 4 || isempty(stdThresh), stdThresh = 3; end

if isa(obj,'fus.Volume')
    P = obj.Plane; % handles
else
    P = obj; % handles
end

if numel(stdThresh) == 1, stdThresh = [stdThresh inf]; end


eventIdx = arrayfun(@(a) find(obj.Time >= a & obj.Time <= a+maxHRDur),eventOnset(:)','uni',0);
eventIdx(cellfun(@(a) lt(length(a),max(cellfun(@length,eventIdx))),eventIdx)) = [];
nEvents = numel(eventIdx);
eventIdx = cell2mat(eventIdx(:))';
nOverlap = sum(eventIdx(1,2:end) < eventIdx(end,1:end-1));
if nOverlap > 0
    warning('estimate_hr:EventsOverlap','%d events overlap!',nOverlap)
end
eventIdx = eventIdx(:);

hr = [];
for i = 1:length(P)
    M = mean(P(i).Data,setdiff(1:P(i).nDims,[1 2 P(i).dim.(P(i).timeDimName)]));
    M = squeeze(reshape(M,[prod(P(i).nYX) P(i).num.(P(i).timeDimName)]));
    M(any(isnan(M),2),:) = [];
    M = zscore(squeeze(M),0,'all');
    M = reshape(M(:,eventIdx),size(M,1)*nEvents,[]);   
    mx = max(M,[],2);
    ind = mx >= stdThresh(1) & mx < stdThresh(2);
    M(~ind,:) = [];
    hr = [hr; M];
end

varargout{1} = mean(hr)';
varargout{2} = std(hr)';
varargout{3} = size(hr,1);





