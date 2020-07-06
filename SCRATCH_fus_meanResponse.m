%% Mean evoked response


analysisWin = [13 15]; %sec

preAnalysisWin = analysisWin-diff(analysisWin)-1; %sec


responseMetric = @mean;
% responseMetric = @trapz;
% responseMetric = @max;

% responseType = 'selectivity';
responseType = 'activation';
% responseType = 'amplitude';

alpha = .01;




I = Plane(1).I;
analysisWinFrames    = round(I.Fs*analysisWin);
preAnalysisWinFrames = round(I.Fs*preAnalysisWin);

P = nan([I.nY I.nX I.nPlanes]);
S = P;
for pid = 1:I.nPlanes
    
    I = Plane(pid).I;    
    
    
    if ismember(func2str(responseMetric),{'max','min'})
        X = feval(responseMetric,Plane(pid).Data(I.roiMaskIdx,:,:,analysisWinFrames(1):analysisWinFrames(end)),[],I.dFrames);
    else
        X = feval(responseMetric,Plane(pid).Data(I.roiMaskIdx,:,:,analysisWinFrames(1):analysisWinFrames(end)),I.dFrames); %#ok<*FVAL>
    end
    
    
    
    
    
    % run ANOVA on each voxel
    switch lower(responseType)
        case 'activation'
            if ismember(func2str(responseMetric),{'max','min'})
                Xp = feval(responseMetric,Plane(pid).Data(I.roiMaskIdx,:,:,preAnalysisWinFrames(1):preAnalysisWinFrames(end)),[],I.dFrames);
            else
                Xp = feval(responseMetric,Plane(pid).Data(I.roiMaskIdx,:,:,preAnalysisWinFrames(1):preAnalysisWinFrames(end)),I.dFrames);
            end
            [p,f] = fusd_anova2(cat(3,Xp,X),I.nTrials);
            p = p(:,2);
        case 'response'
            [p,f,stats] = fusd_anova(X);
        case 'amplitude'
            
    end
    
%     [~,~,~,p] = fdr_bh(p,alpha,'dep','no');
    
    [p,selIdx] = min(p,[],2);

    pt = zeros([I.nY I.nX]);
    pt(I.roiMaskIdx) = p;

    st = zeros([I.nY I.nX]);
    st(I.roiMaskIdx) = selIdx;
    
    P(:,:,pid) = pt;
    S(:,:,pid) = st;
    
    fprintf('Plane % 2d of % 2d: ANOVA % 4d (of %4d) voxels < %g\n', ...
        pid,I.nPlanes,nnz(p<alpha),length(I.roiMaskIdx),alpha)
    
    
end

%
clf

Pim = imtile(P);
Pim = log10(Pim);
Pim(isinf(Pim)) = 0;
imagesc(Pim);
set(gca,'clim',log10([1e-5 1]))
axis image
colormap parula
h = colorbar;
h.Label.String = 'log10(adj. p-value)';
set(gca,'xtick',[],'ytick',[]);
title(I.fileRoot,'Interpreter','none')
drawnow
fprintf(' done\n')

%% postprocess probability maps

alpha = .01;

fprintf('Post-processing p-value maps ...')
sP = P;
sP(isnan(sP)) = 1;
% smooth later
% sP = fus_smooth(sP);
% sP = medfilt3(sP,[3 3 3]); %sP = medfilt3(sP,[3 3 3]);

sPsigInd = false([I.nY I.nX I.nPlanes]);
for pid = 1:I.nPlanes
    I = Plane(pid).I;
    x = false([I.nY I.nX]);
    y = sP(:,:,pid);
    x(I.roiMaskIdx) = logical(y(I.roiMaskIdx) < alpha);
    x = bwmorph(x,'clean');
    x = bwmorph(x,'fill');
    sPsigInd(:,:,pid) = x;
    Plane(pid).Overlay = log10(y);
end
clf
fus_imtile(Plane);
h = fus_imtileOverlay(Plane);
h.Parent.CLim = [-5 0];

ch = findobj(gcf,'type','colorbar');
ch.Label.String = '\it{log_{10}(p)}';
fprintf(' done\n')

%% run posthoc tests

disp('Post-hoc analysis')
M = nan([I.nY I.nX I.nPlanes]);
for pid = 1:I.nPlanes
    fprintf('\tPlane %d of %d\n',pid,I.nPlanes)
    
    if nnz(sPsigInd(:,:,pid)) == 0, continue; end % nothing to process

    I = Plane(pid).I;
        
    sigIdx = find(sPsigInd(:,:,pid));
    
    if ismember(func2str(responseMetric),{'max','min'})
        X = feval(responseMetric,Plane(pid).Data(sigIdx,:,:,analysisWinFrames),[],I.dFrames);
    else
        X = feval(responseMetric,Plane(pid).Data(sigIdx,:,:,analysisWinFrames),I.dFrames); %#ok<*FVAL>
    end
    
    
    % run Wilcoxon rank sum posthoc on significant voxels
    idx = zeros(size(sigIdx));
    for i = 1:size(X,1)
        tst = squeeze(X(i,:,:))';
        pr = [];
        r = 1;
        for j = 1:I.nStim
            for k = 1:I.nStim
                pr(r,1) = j;
                pr(r,2) = k;
                pr(r,3) = ranksum(tst(:,j),tst(:,k),'tail','right'); % right: med(j) > med(k)
                r = r + 1;
            end
        end
        % choose the smallest post-hoc p-value (?)
        [~,r] = min(pr);
        idx(i) = pr(r(3),1);
    end
    
    m = zeros([I.nY I.nX]);
    m(sigIdx)  = idx;
    M(:,:,pid) = m;
end


%%
fprintf('smoothing stim map ..')
sM = interp3(M,3,'linear');
sM = smooth3(sM,'gaussian',[5 5 3],.5);
sM = sM(round(linspace(1,size(sM,1),size(M,1))),round(linspace(1,size(sM,2),size(M,2))),round(linspace(1,size(sM,3),size(M,3))));
fprintf(' done\n')

%%

clf
set(gcf,'color','w');

fus_imtile(Plane);

M(~sPsigInd) = nan;
for i = 1:length(Plane)
    Plane(i).Overlay = M(:,:,i);
end

h = fus_imtileOverlay(Plane);

h.Parent.CLim = [-.5 I.nStim+.5];

cm = [  0   0   0;
        0 124 193;
       30 217 227;
      238 226  77;
      255 107   0;
      197  18   0];
  
      
colormap(h.Parent,cm./255)

h = findobj(gcf,'type','colorbar');
h.Limits = [0.5 I.nStim+.5];
h.Ticks  = 1:I.nStim;
h.TickLabels = {'602Hz','1430Hz','3400Hz','8087Hz','19234Hz'};
h.TickDirection = 'out';



%% Write current graphic to file
ffn = fullfile(I.filePath,[I.fileRoot '-Tonotopy.tif']);
link = sprintf('''START "" "%s"''',ffn);
fprintf('Writing %s ...',ffn)
exportgraphics(gcf,ffn,'resolution',300);
fprintf(' done\n')


%% nifti
% V = smooth3(V,'gaussian',[5 5 3]);

I = Plane(1).I;

% stimValues = [602 1430 3400 8087 19234];
% for i = 1:length(stimValues)
%     V(V==i) = stimValues(i);
% end



% 
I.voxelSpacing(3) = .3; % Boubenec

ffn = fullfile(I.filePath,[I.fileRoot '-Tonotopy.nii']);
niftiwrite(M,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = I.voxelSpacing(1:3);
niftiwrite(M,ffn,ninfo);
fprintf('Wrote "%s"\n',ffn)












