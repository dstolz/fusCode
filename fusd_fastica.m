function X = fusd_fastica(X,q)

% Reduce dimensionality using PCA

% [E,S,L,~,exv,mu] = pca(X);
% 
% inclComp = find(cumsum(exv)>90,1);
% 
% fprintf('PCA dimensionality reduction using %d components containing %.3f%% of var\n',inclComp,sum(exv(1:inclComp)))
% 
% X = S(:,1:inclComp) * E(:,1:inclComp)';
% X = bsxfun(@plus,X,mu);

% Run fastica - each row is one observed signal 
%       - spatial:  pixels x samples
%       - temporal: samples x pixels

% q = inclComp; % # ICA components to extract
% q = 7;
X = fastica(X','numOfIC',q,'approach', 'defl', ... %'symm',  ...
    'g','tanh','finetune','tanh','stabilization','on', ...
    'displayMode','off');

% X = zscore(X,0,'all');

