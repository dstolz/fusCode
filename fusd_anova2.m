function [p,F,stats] = fusd_anova2(data,reps)
% [p,F,stats] = fusd_anova(data)
% data:     Pixels x Stim x Trials
%
%

% DJS 2020


[nPixels,nStim,nTrials] = size(data);

p = zeros(nPixels,3,'single');
F = p;
stats(nPixels,1) = struct('source',[],'sigmasq',[],'colmeans',[],'coln',[],'rowmeans',[],'rown',[],'inter',[],'pval',[],'df',[]);


% trials = (1:nTrials)';

% T = table;
for i = 1:nPixels
    y = squeeze(data(i,:,:))'; % need Trials x Stim
    [p(i,:),tbl,stats(i)] = anova2(y,reps,'off');
    F(i,:) = cell2mat(tbl(2:4,5));
end


