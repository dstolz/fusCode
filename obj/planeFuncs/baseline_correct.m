function baseline_correct(obj,baselineWindow,bcFcn)
% baseline_correct(obj,baselineWindow,[bcFcn])
%
% Run baseline correction using baselineWindow for the baseline period.
%
% Inputs:
%   obj             ... fus.Plane object
%   baselineWindow  ... 1x1 indicating the baseline window duration from
%                       the beginning of the trial (in seconds).
%                        or
%                       1x2 indicating the baseline window onset and offset
%                       from the beginning of the trial (in seconds).
%   bcFcn           ... handle to the baseline correction function to apply
%                       to the data.  The bcFcn must accept two inputs:
%                       The first input is an MxN matrix with 
%                       M = Pixels*Reps*Events and N = Time.  The second
%                       input is the mean of the baseline window of the
%                       data and is an MxP matrix where M is same as the
%                       first input and P = baseline samples.
%                       Default = @(a,b) ((a-mean(b,2))./mean(b,2))
%

% DJS 2020

narginchk(2,3)

if isscalar(baselineWindow), baselineWindow = [0 baselineWindow]; end
if nargin < 3 || isempty(bcFcn), bcFcn = @(a,b) ((a-mean(b,2))./mean(b,2)); end

fidx = obj.Time >= baselineWindow(1) & obj.Time <= baselineWindow(2);

data = obj.reshape_data([join(["Y" "X" obj.repDimName obj.eventDimName],"*"),obj.timeDimName]);

data = bcFcn(data,data(:,fidx));

obj.set_Data(reshape(data,obj.dimSizes));

obj.update_log('Baseline correction, baselineWindow = %s',mat2str(baselineWindow));


