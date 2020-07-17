function [A,time] = arrange_data_by_event(obj,name,values,win,retType)
% A = arrange_data_by_event(obj,[name],[values],[win],[retType])
% [A,time] = arrange_data_by_event(obj,...)
%
% Return data arranged by a time window around an Event onset.
%
% Inputs:
%   obj     ... handle to fus.Plane object
%   name    ... 1x1 string of an Event included in the fus.Plane object.
%               Default = obj.Event(1).Name
%   values  ... 1xN specifies which values to use when arranging the data.
%               Default = all values in the Event
%   win     ... 1x2 specifies window (in seconds) around the Event onset to
%               extract the data.  Default = [-1 1]
%   retType ... 1x1 string specifying how to return data in A, see outputs
%               below. Default = "struct"
% Outputs:
%   A       ... If retType == "struct" (default):
%                   > Nx1 structure with Data and Samples subfields.  
%                       A.Data    ... [Y x X x Reps x Samples]
%                       A.Samples ... [Reps x Samples] with indices from
%                                     the original data.
%               If retType == "matrix":
%                   > Returns A as a 4D matrix: [Y x X x Reps x Samples x Event]
%               if retTYpe == "Plane":
%                   > Returns a fus.Plane object with the new data arrangement.
%
%   time    ... Times for each sample returned as [1 x #Samples]
%

% DJS 2020

if nargin < 2, name = [];   end
if nargin < 3, values = []; end
if nargin < 4 || isempty(win), win = [-1 1]; end
if nargin < 5 || isempty(retType), retType = "struct"; end

mustBeMember(retType,["struct" "matrix" "Plane"]);

assert(~isempty(obj.Event), ...
    'fus:Plane:arrange_data_by_event:NoEvents', ...
    'No Events are specfied in the object.');

assert(obj.nDims == 2 || obj.nDims == 3, ...
    'fus:Plane:arrange_data_by_event:InvalidDims', ...
    'Data must have 2 or 3 dims');

if isempty(name)
    name = obj.Event(1).Name;
end

Ev = obj.get_event(name);

if isempty(values)
    values = Ev.uValue;
end

S = Ev.get_Data(values,"struct","samples");


if obj.nDims == 3 % X x Y x Time -> X*Y x Time
    data = obj.reshape_data(["X*Y" obj.timeDimName]);
else
    data = obj.Data;
end

npx = prod(obj.nYX);

swin  = floor(win(1)*obj.Fs):ceil(win(2)*obj.Fs);
smp   = swin(1):swin(end);
nsmps = length(smp);
time  = smp./obj.Fs;

A(size(S)) = struct('Data',[],'Samples',[]);
for i = 1:length(S)
    idx = S(i).Onset + smp;
    d = nan(npx,nsmps,S(i).N,'like',data);
    idx(idx<1|idx>npx) = nan;
    for j = 1:S(i).N
        d(:,~isnan(idx(j,:)),j) = data(:,idx(j,:));
    end
    A(i).Data    = d;
    A(i).Samples = idx;
end

if obj.nDims == 3 % X*Y x Time -> X x Y x Time
    for i = 1:length(A)
        A(i).Data = reshape(A(i).Data,[obj.nYX S(i).N nsmps]);
    end
end

if any(retType == ["matrix" "Plane"]) % use matrix form for Plane too
    M = [];
    n = ndims(A(1).Data)+1;
    for i = 1:length(A)
        M = cat(n,M,A(i).Data);
    end
    A = M; clear M
end

if retType == "Plane"
    P = copy(obj);
    if ndims(A) == 4
        dataDims = ["Y_X" "Reps" "Frames" "Events"];
    else
        dataDims = ["Y" "X" "Reps" "Frames" "Events"];
    end
    
    P.set_Data(A,dataDims);
    P.timeDimName  = "Frames";
    P.eventDimName = "Events";
    P.repsDimName  = "Reps";
    A = P;
end



