function [p,F,stats] = fusd_anova(data)
% [p,F,stats] = fusd_anova(data)
% data:     Pixels x Stim x Trials
%
%

% DJS 2020


[nPixels,nStim,nTrials] = size(data);

p = zeros(nPixels,1,'single');
F = p;
stats(nPixels,1) = struct('gnames',[],'n',[],'source',[],'means',[],'df',[],'s',[]);


for i = 1:nPixels
    y = squeeze(data(i,:,:));
    y = y'; % need Trials x Stim
    [p(i),tbl,stats(i)] = anova1(y,[],'off');
    F(i) = tbl{2,5};
end


