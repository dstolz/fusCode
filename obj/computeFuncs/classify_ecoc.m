function [R,mdl] = classify_ecoc(x,vin)
% R = classify_ecoc(x,'Name',Value,...)
% [R,mdl] = classify_ecoc(x,'Name',Value,...)
%
% Use an error-correcting output codes classifier for multiclass classification.
% This is done using fitcecoc from the Statistics and Machine Learning toolbox.
% This is basically the same as running support-vector machine classifier comparing
% each class against all others (Coding = 'onevsall'). Alternative classifiers
% can be used as well.
%
% Inputs:
%   x   ... [MxNxP] or [MxNxPxT] matrix with:
%               M = Predictors (Voxels)
%               N = Events
%               P = Repetitions of events
%               T = Time (Frames)
%           The classifier is fed N*P observations for M predictors for one timepoint
%           which is specified using the 'Name',Value pair: 'foi',frameNumber
%
%  'Name',Value options:
%       'foi'       ... frame-of-interest. A 1xN value indicating which frame(s) to use
%                       from the data. Appends multiple frames as observations. default = 1
%       'Coding'    ... default = 'onevsall'. See fitcecoc documentation for more options.
%       'KFold'     ... scalar value indicating the number of folds to use for
%                       cross-validating the model. default = 10
%       'Template'  ... defines a template to use for the classifier learners.
%                       default = 'svm'. See fitcecoc documentation for more options.
%                       Also see templateSVM for details.
%
% Outputs:
%   AUC     ... [1xQ], where Q is number of comparisons. Area under the receiver
%               operating characteristic curve computed for each comparison.  If
%               Coding = 'onevsall', then Q will be the same as the number of
%               Events.  Other Coding schemes will result in different numbers
%               of results.
%   mdl     ... Returns a ClassificationECOC model object.
%
% DJS 2020


% defaults
par.kfold = 10;
par.coding = 'onevsall';
par.template = 'svm';
par.result = 'auc';
par.weights = 'uniform';
par.foi = 1;

par = validate_inputs(par,vin);

% Voxels x Events x Reps x Time -> Voxels x Events x Reps*Time
fpick = repmat({':'},1,ndims(x));
fpick{ndims(x)} = par.foi;
x = x(fpick{:});
n = size(x,1:4);
x = reshape(x,[n(1) n(2) n(3)*n(4)]);


n = size(x,1:3); % Voxels x Events x Reps

% event classes
y = ones(n(3),1)*(1:n(2));
y = y(:);


% Voxels x Events x Reps -> Voxels x Events*Reps
x = reshape(x,[n(1) n(2)*n(3)]);
x = x'; % -> Events*Reps x Voxels | Observations x Predictors(Features)


if isa(par.weights,'function_handle')
    w = feval(par.weights,n);
else
    switch par.weights
        case 'uniform'
            w = ones(n(2)*n(3),1);

        case {'gaussian','uniform'}
            w = repmat(gausswin(n(2)),n(3),1);
    end
end

% preallocate result
switch lower(par.result)
    case 'auc'
        R = nan(1,n(2));
    case 'scores'
        R = nan;
    case 'model'
        
    case 'posteriors'
        error('posteriors result is not yet implemented')
        
end



if any(all(isnan(x))), return; end


warning('off','stats:fitSVMPosterior:PerfectSeparation');
warning('off','stats:cvpartition:KFoldMissingGrp');

mdl = fitcecoc(x,y,'Learners',par.template, ...
    'kfold',par.kfold,'Coding',par.coding, ...
    'Weights',w);

warning('on','stats:fitSVMPosterior:PerfectSeparation');
warning('on','stats:cvpartition:KFoldMissingGrp');


switch lower(par.result)
    case 'auc'
        [~,score_svm] = kfoldPredict(mdl); % score_svm: posterior probability of the classification

        for j = 1:size(score_svm,2)
            [~,~,~,R(j)] = perfcurve(y,score_svm(:,j),j);
        end
    case 'scores'
        [~,score_svm] = kfoldPredict(mdl); % score_svm: posterior probability of the classification

        R = score_svm;

    case 'model'
        R = mdl;

    case 'posteriors'
        error('posteriors result is not yet implemented')
        
end
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

mustBeMember(par.result,{'auc','scores','posteriors','model'})

if isstring(par.weights) || ischar(par.weights)
    mustBeMember(par.weights,{'uniform','gaussian','normal'})
else
    assert(isa(par.weights,'function_handle'), ...
        'fus:Volume:searchlight:InvalidValue', ...
        'weights must be followed by a string or function handle.')
end

mustBeInteger(par.foi);
mustBeNonempty(par.foi);
mustBeNonnegative(par.foi);
% assert(isscalar(par.foi), ...
%     'fus:Volume:searchlight:InvalidSize', ...
%     'foi must be scalar, positive integer');


end