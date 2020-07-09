function baseline_correct(obj,timeWin,bcFcn)
% baseline_correct(obj,timeWin,bcFcn)

narginchk(2,3)

if isscalar(timeWin), timeWin = [0 timeWin]; end
if nargin < 3 || isempty(bcFcn), bcFcn = @(a,b) (a-b)./b; end

fidx = obj.Time >= timeWin(1) & obj.Time <= timeWin(2);

data = obj.reshape_data({'Y*X*Stim*Trials','Frames'});

data = bcFcn(data,mean(data(:,fidx),2));

obj.set_Data(reshape(data,obj.dimSizes));

obj.update_log('Baseline correction, timeWin = %s',mat2str(timeWin));


