function [R,n] = searchlight(obj,fnc,varargin)
% [R,n] = searchlight(obj,fnc,'name','value',...)
%
% Evaluates a function, fnc, for all subvolumes in the fus.Volume object.
% The specified function, fnc, is passed a data matrix with dimensions of
% Voxels x additional dims..., and additional varargin using the 
% cell array specified using the 'fncVarargin' property (see below).
% 
% Example (where V is a valid fus.Volume object with multiple Planes):
%   % specify parameters, par, that are passed to classify_ecoc
%   tmpSVM = templateSVM( ...
%        'KernelFunction','rbf', ...
%        'KernelScale','auto', ...
%        'Standardize',true, ...
%        'OutlierFraction',.01, ...
%        'IterationLimit',1e8);
%
%   par = {'foi',15,'template',tmpSVM};
% 
%   R = V.searchlight(@classify_ecoc, ...
%        'blockSize',[5 5 5], ...
%        'useParallel',true, ...
%        'fncParams',par);
% 
% Inputs:
%   obj     ... fus.Volume object handle
%   fnc     ... function handle.  The called function receives the object
%               handle, followed by the volume data on each iteration.
%
%               example function syntax: R = examplefnc(M,obj,params)
% 
%   'Name','Value' pairs
%    'blockSize'      ... [1x3] integers with the number of voxels included
%                       in each block. Dimension order = [YxXxZ]. Note that
%                       blockSize can be non-square form.  For example,
%                       blockSize of [3 3 1] will process a 3x3 voxel box
%                       within individual planes.  blockSize of [1 3 5]
%                       processes a box of voxels spanning 3 column voxels
%                       and 5 planes and only 1 row voxel at at time.  [1 1
%                       1] will process a single voxel at a time.  Note
%                       that any block with a size greater than [1 1 1]
%                       will overlap with its neighbors in all dimensions.
%                       default = [3 3 3]
%    'minNumVoxels' ... scalar integer indicating the minimum number of
%                       voxels to include when calling fnc.  This handles
%                       edge cases so that voxels on the end planes and
%                       other boundaries can be analyzed.  
%                       Default = floor(prod(blockSize)/2)
%    'useParallel'  ... logical value indcating whether to use the
%                       Parallel Computing Toolbox when looping over each
%                       voxel. default = true if toolbox is available.
%    'fncParams'    ... parameter(s) to pass to the function specified,
%                       fnc.  No validation occurs on the variable.
%    'UniformOutput'... logical value indicating whether a numeric matrix
%                       (true) or a cell matrix (false) is returned.  If
%                       true, then the called function, fnc, must return a
%                       scalar value. default = false
%    'showProgress' ... displays completion percentage in command window.
%                       default = true
% Output:
%   'R'     ... XxYxZ cell matrix with the results from processing fnc for
%               each valid block.
%   'n'     ... XxYxZ matrix with the number of voxels included in each
%               block that was processed.
% 
% 
% DJS 2020

narginchk(2,inf);

assert(isa(fnc,'function_handle'), ...
    'fus:Volume:searchlight:InvalidValue', ...
    'fnc must be a function handle');


par.blockSize = [3 3 3];
par.minNumVoxels = floor(prod(par.blockSize)/2); % [3 3 3] = 27 = complete cube
par.useParallel = ~isempty(ver('parallel'));
par.UniformOutput = false;
par.fncParams = [];
par.showProgress = true;

par = validate_inputs(par,varargin);

par.fnc = fnc;


M = [];
for i = 1:obj.nPlanes
    M = cat(obj.Plane(i).nDims+1,M,obj.Plane(i).Data);
end

P = obj.Plane(1);

% permute to Y x X x Plane x additional dims...
d = setdiff(P.dimOrder,{'Y' 'X'});
M = permute(M,[P.dim.Y P.dim.X P.nDims+1 P.find_dim(d)]);

nM = size(M);

% Y x X x Plane x ... -> AllVoxels x ...
M = reshape(M,[prod(nM(1:3)) nM(4:end)]);

% block center
blkCenter = floor((par.blockSize+1)/2);

% block vectors
blkVec = arrayfun(@(a,b) -a+1:b-a,blkCenter,par.blockSize,'uni',0);


volSize = nM(1:3);

% create a blank volume to assist in indexing
blankVol = false(volSize);

% predetermine all voxel coordinates (primarily for using parfor)
[py,px,pz] = ind2sub(volSize,1:prod(volSize));

numIter = prod(volSize);

fprintf('Running %s on volume "%s", %d Planes with approximately %d voxels\n', ...
    func2str(fnc),obj.Name,obj.nPlanes,numIter)

startTime = tic;

if par.useParallel && obj.check_parallel
    p = gcp;

    if isempty(p), p = gcp; end
    
    update_par_progress; % init
    
    Q = parallel.pool.DataQueue;
    afterEach(Q,@(cnt) update_par_progress(numIter,cnt));

    try
        fprintf('Distributing volume data to workers ...')
        Cx = parallel.pool.Constant(M);
        clear M
        Px = parallel.pool.Constant({py,px,pz});
        clear py px pz
        fprintf(' done\n')

        
        
        fprintf('Submitting jobs to %d workers ...\n',p.NumWorkers)
        f(1:p.NumWorkers) = parallel.FevalFuture;
        for i = 1:p.NumWorkers
            % stratify voxels across workers to try to balance it
            idx = i:p.NumWorkers:numIter;
            f(i) = parfeval(p,@iter_parallel,2,Q,idx,Cx,blkVec,blankVol,volSize,Px,par);
%             f(i) = parfeval(p,@iter_parallel,2,Q,partitions(i),partitions(i+1),Cx,blkVec,blankVol,volSize,Px,par);
        end
        
        wait(f);
        
        R = cell(volSize);
        n = zeros(volSize);
        for i = 1:p.NumWorkers
            idx = i:p.NumWorkers:numIter;
            [R(idx),n(idx)] = fetchOutputs(f(i));
        end
        
%         R = reshape(R,volSize);
%         n = reshape(n,volSize);
        
        cancel(f);
        delete(Cx);
        delete(Px);
    catch me
        cancel(f);
        delete(Cx);
        delete(Px);
        rethrow(me);
    end
    
else
    if par.showProgress, parfor_progress(numIter); end
    R = cell(volSize);
    n = zeros(volSize,'single');
    for i = 1:numIter
        [R{i},n(i)] = iter(M,blkVec,blankVol,volSize,[py(i),px(i),pz(i)],par);
        if par.showProgress, parfor_progress; end
    end
    if par.showProgress, parfor_progress(0); end

end


if par.UniformOutput
    try
        R = cell2mat(R);
    catch me
        fprintf(2,'Try setting UniformOutput to false\n')
        rethrow(me)
    end
end



t = toc(startTime);
if t > 3600
    t = t / 360;
    u = 'hr';
elseif t > 60
    t = t / 60;
    u = 'm';
else
    u = 's';
end

fprintf('completed 100%% in %.2f %s\n',t,u)
end

function [R,n] = iter(M,blkVec,blankVol,volSize,p,par)
R = []; n = 0;

idxy = p(1)+blkVec{1};
idxx = p(2)+blkVec{2};
idxz = p(3)+blkVec{3};

idxy(idxy<1|idxy>volSize(1)) = [];
idxx(idxx<1|idxx>volSize(2)) = [];
idxz(idxz<1|idxz>volSize(3)) = [];

ind = blankVol;
ind(idxy,idxx,idxz) = true;

nPx = sum(ind(:));
if nPx < par.minNumVoxels
    if par.showProgress, parfor_progress; end
    return
end

% slice data
ndM = ndims(M);
s = repmat({':'},1,ndM);
s{1} = ind;

n = nnz(ind);

R = feval(par.fnc,M(s{:}),par.fncParams);

end

% function [R,n] = iter_parallel(Q,first,last,M,blkVec,blankVol,volSize,p,par)
function [R,n] = iter_parallel(Q,idx,M,blkVec,blankVol,volSize,p,par)
nidx = length(idx);
R = cell(nidx,1);
n = zeros(nidx,1,'uint16');
ndM = ndims(M.Value);
s = repmat({':'},1,ndM);
k = 1;
for i = idx
    idxy = p.Value{1}(i)+blkVec{1};
    idxx = p.Value{2}(i)+blkVec{2};
    idxz = p.Value{3}(i)+blkVec{3};
    
    idxy(idxy<1|idxy>volSize(1)) = [];
    idxx(idxx<1|idxx>volSize(2)) = [];
    idxz(idxz<1|idxz>volSize(3)) = [];
    
    ind = blankVol;
    ind(idxy,idxx,idxz) = true;
    
    nPx = sum(ind(:));
    if nPx < par.minNumVoxels
        send(Q,first+i-1);
        continue
    end
    
    s{1} = ind;
    
    n(k) = nnz(ind);
    
    R{k} = feval(par.fnc,M.Value(s{:}),par.fncParams);
    send(Q,k);
    k = k + 1;
end
end


function update_par_progress(n,cnt)
persistent t
if nargin == 0, t = 0; end

t = t + 1;

if mod(t,100)~=0, return; end

v =t/n*100;

fprintf('%s: completed % 3.2f%%\n',datestr(now),v)
end




function par = validate_inputs(par,vin)

fn = fieldnames(par);
for i = 1:2:length(vin)
    ind = strcmpi(vin{i},fn);
    assert(any(ind), ...
        'fus:Volume:searchlight:InvalidParameterName', ...
        sprintf('"%s" is not a valid parameter',vin{i}))
    par.(fn{ind}) = vin{i+1};
end

mustBeInteger(par.minNumVoxels);
mustBeNonempty(par.minNumVoxels);
mustBeNonnegative(par.minNumVoxels);
assert(isscalar(par.minNumVoxels), ...
    'fus:Volume:searchlight:InvalidSize', ...
    'minNumVoxels must be scalar, positive integer');

mustBeInteger(par.blockSize);
mustBeNonempty(par.blockSize);
mustBeNonnegative(par.blockSize);

assert(numel(par.blockSize)==3, ...
    'fus:Volume:searchlight:InvalidSize', ...
    'blockSize must be a 3 element, positive integer array');

% assert(all(mod(par.blockSize,2)), ...
%     'fus:Volume:searchlight:InvalidValue', ...
%     'blockSize values must all be odd');
end




