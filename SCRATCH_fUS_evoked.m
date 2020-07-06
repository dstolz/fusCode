%% Cross-Correlation between stimulus frames and mean data.
% Finds the maximum Pearson's cross-correlation between the frames when a
% stimulus is presented and the fUS response.  
%
% The idea behind this is that a consistent haemodynamic response to
% stimlui will have higher correlation with the stimulus at some delay
% (lag) because of the slow dynamics of neurovascular coupling.
%
% Analysis results the magnitude and time lag of the maximum correlation
% coefficient when the stimulus is shifted frame-by-frame until maxLags
% seconds (see parameter below).
%
% Modify stimFrames (1x2) to indicate the frames when the stimulus is
% presented, and maxLag (1x1) to set an upper bound on how long to shift
% the stimulus relative to the data.  Note that negative lags, ie shifting
% the stimulus earlier, is discarded because that wouldn't make sense.  You
% may use rectifyFcn to manipulate the data, for example by making all
% values positive, prior to computing the correlation coefficient (but
% after computing the mean value across trials).  Set rectifyFcn = [] in
% order to not do anything to the data (default rectifyFcn = @(a) a.^2)
%
% This script plots all planes (rows) vs all stimuli (columns) for the
% maximum cross-correlation coefficient (for each pixel) and the lag (in
% seconds) of that value.
%


% stimFrames = [20 25]; % frames when stimulus is presented
stimFrames = [10 13];

maxLag = 6; % seconds
% maxLag = 0; % seconds

% rectifyFcn = [];
% rectifyFcn = @abs;
rectifyFcn = @(a) a.^2;



alpha = .001;



% threshold for ranking each pixel by max stim correlation
rThreshold = .5; 




fprintf('Computing cross-correlation ')
stimSig = zeros(Plane(1).I.nFrames,1);
stimSig(stimFrames(1):stimFrames(2)) = 1;


maxLag = ceil(maxLag.*I.Fs)./I.Fs; % make sure maxLag is an integer

maxLagFrames = maxLag.*I.Fs;

clf
set(gcf,'color','w')

P = nan([I.nY I.nX I.nPlanes]);
F = P;
for pid = 1:length(Plane)
    
    D = Plane(pid).Data;
    I = Plane(pid).I;       

    D = D(I.roiMaskIdx,:,:,:);
    
    if ~isempty(rectifyFcn)
        D = feval(rectifyFcn,D);
    end
    
    
    % find peak xcorr for each trial
    r = zeros(length(I.roiMaskIdx),I.nStim,I.nTrials,'single');
    lag = r;
    for s = 1:I.nStim        
        for i = 1:I.nTrials
            [r(:,s,i),lag(:,s,i)] = fusd_xcorrMax(squeeze(D(:,s,i,:)),stimSig,maxLagFrames);
        end
    end
    
%     % apply Fisher Z-transform to Pearson correlation coefs
%     zr = .5*(log(1+r) - log(1-r));
%     zrm = mean(zr,3);
%     [zrmx,stimID] = max(zrm,[],2);
    
    % compute anova for each pixel across stimuli
    [p,f,stats] = fusd_anova(r);
    
%     [corrected_p, h]=bonf_holm(p,.05);
    
    mp = nan([I.nPixels 1]);
    mp(I.roiMaskIdx) = p;
    
    mf = nan([I.nPixels 1]);
    mf(I.roiMaskIdx) = f;
    
    P(:,:,pid) = reshape(mp,[I.nY I.nX]);
    F(:,:,pid) = reshape(mf,[I.nY I.nX]);
    
    fprintf('.')
end
fprintf(' done\n')

%%
pInd = P < alpha;

montage(P,'Size',[1 size(P,3)],'DisplayRange',[0 .1])
colormap jet
%% Display results
clf

rMax = []; rLag = [];
for pid = 1:length(Zr)
    rMax = cat(3,rMax,Zr{pid});
    rLag = cat(3,rLag,Zlag{pid});
end

rLag = rLag ./ I.Fs; % frames -> seconds

if maxLag > 0
    subplot(121);
end
r = quantile(rMax(:),.999);
rMaxIm = imtile(rMax,'GridSize',[I.nPlanes I.nStim]);
iamgesc(rMaxIm);
axis image

xlabel(sprintf('Stimulus (1\\rightarrow%d)',I.nStim),'FontSize',14)
ylabel({'Plane',sprintf('(%d\\leftarrow1)',I.nPlanes)},'FontSize',14)
title(sprintf('%s | maxLag = %.1f s',I.fileRoot,maxLag),'interpreter','none','FontSize',14)

colormap(gca,jet)
h = colorbar;
h.FontSize = 12;
h.Label.String = 'max corr. coef. (\itr)';
h.Label.FontSize = 14;

if maxLag > 0
    subplot(122);
    montage(rLag,'displayrange',[0 maxLag],'size',[I.nPlanes I.nStim]);
    
    xlabel(sprintf('Stimulus (1\\rightarrow%d)',I.nStim),'FontSize',14)
    title(sprintf('%s | maxLag = %.1f s',I.fileRoot,maxLag),'interpreter','none','FontSize',14)
    
    colormap(gca,parula)
    h = colorbar;
    h.FontSize = 12;
    h.Label.String = '\itr_{lag} (sec)';
    h.Label.FontSize = 14;
end


%% Create a stimulus selectivity index




%% Rank pixels by largest stimulus correlation

figure('color','w');
I = Plane(1).I;
stimRanked = nan([I.nY I.nX I.nStim]);

col = ceil(sqrt(I.nPlanes+1));
row = ceil((I.nPlanes+1)/col);

for i = 1:length(Plane)
    I = Plane(i).I;
    [m,sid] = max(Zr{i},[],3);
    ind = m < rThreshold;
    sid(ind) = 0; % 0 = background
    sid(~I.roiMaskInd) = 0;
    stimRanked(:,:,i) = sid;
   
    ax = subplot(row,col,i);
    imagesc(stimRanked(:,:,i),'parent',ax);
    axis(ax,'image')
    set(ax,'clim',[0 I.nStim],'xtick',[],'ytick',[]);
    
    ax.XAxis.Label.String = sprintf('Plane %d',i);
    ax.XAxis.Label.Color = [0 0 0];
end

% montage(stimRanked,'DisplayRange',[-.5 I.nStim+.5],'Size',[1 I.nPlanes]);
colormap(gcf,[1 1 1; jet(I.nStim)]);

ax = subplot(row,col,I.nPlanes+1);
ax.XAxis.Color = 'none';
ax.YAxis.Color = 'none';
ax.CLim = [-.5 I.nStim+.5];

h = colorbar(ax,'Location','west');
 
h.Ticks = 1:I.nStim;
h.TickDirection = 'out';
h.Label.String = 'Stimulus #';
h.Label.FontSize = 12;




%% Write stimRanked to a NIfTI file
ffn = fullfile(I.filePath,sprintf('%s_stimRanked.nii',I.fileRoot));
niftiwrite(stimRanked,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = I.voxelSpacing(1:3);
niftiwrite(stimRanked,ffn,ninfo);
fprintf('Wrote "%s"\n',ffn)





%% Write a NIfTI for max correlation for each stimuls
I = Plane(1).I;
for sid = 1:I.nStim
    v = rMax(:,:,sid:I.nStim:end);
    fn = sprintf('%s_Stim_%d_rMax.nii',I.fileRoot,sid);
    ffn = fullfile(I.filePath,fn);
    fprintf('Writing "%s" ...',ffn)
    niftiwrite(v,ffn);
    ninfo = niftiinfo(ffn);
    ninfo.PixelDimensions = I.voxelSpacing(1:3);
    niftiwrite(v,ffn,ninfo);
    fprintf(' done\n')
end











