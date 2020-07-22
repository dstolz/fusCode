function AUC = classify_ecoc(x,vin)
% AUC = classify_ecoc(x,...)

par.kfold = 10;
par.coding = 'onevsall';
par.template = 'svm';
par.foi = 1;

par = validate_inputs(par,vin);


fpick = repmat({':'},1,ndims(x));
fpick{ndims(x)} = par.foi;
x = x(fpick{:});

n = size(x); % Voxels x Events x Reps

% event classes
y = ones(n(2),1)*(1:n(3));
y = y(:);

% Voxels x Events x Reps -> Voxels x Events*Reps
x = reshape(x,[n(1) n(2)*n(3)]);
x = x'; % -> Events*Reps x Voxels | Observations x Predictors(Features)


AUC = nan(1,n(2));

if any(all(isnan(x))), return; end


warning('off','stats:fitSVMPosterior:PerfectSeparation');
warning('off','stats:cvpartition:KFoldMissingGrp');

mdlECOC = fitcecoc(x,y,'Learners',par.template, ...
    'kfold',par.kfold,'Coding',par.coding);

warning('on','stats:fitSVMPosterior:PerfectSeparation');
warning('on','stats:cvpartition:KFoldMissingGrp');

[~,score_svm] = kfoldPredict(mdlECOC); % score_svm: posterior probability of the classification

for j = 1:size(score_svm,2)
    [~,~,~,AUC(j)] = perfcurve(y,score_svm(:,j),j);
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

mustBeInteger(par.foi);
mustBeNonempty(par.foi);
mustBeNonnegative(par.foi);
assert(isscalar(par.foi), ...
    'fus:Volume:searchlight:InvalidSize', ...
    'foi must be scalar, positive integer');


end