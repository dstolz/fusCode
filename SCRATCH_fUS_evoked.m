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
% I have not seen any characterization of the fUS haemodynamic function.
% If we had this, then we could convolve it with the stimulus vector to
% extract a more accurate expectation of the brain's response.  This has
% been done with the haemodynamic response function for the BOLD response
% in fMRI, but it's not certain this is the same for fUS imaging.

stimFrames = [20 25]; % frames when stimulus is presented

maxLag = 5; % seconds

% rectifyFcn = [];
% rectifyFcn = @abs;
rectifyFcn = @(a) a.^2;










fprintf('Computing cross-correlation ')
stimSig = zeros(Plane(1).I.nFrames,1);
stimSig(stimFrames(1):stimFrames(2)) = 1;


maxLag = ceil(maxLag.*I.Fs)./I.Fs; % make sure maxLag is an integer

clf
set(gcf,'color','w')

Zr = cell(size(Plane));
Zlag = Zr;
for pid = 1:length(Plane)
    
    D = Plane(pid).Data;
    I = Plane(pid).I;       

    R = zeros([length(I.roiMaskIdx) I.nStim]);
    Rlag = R;

    for s = 1:I.nStim
        y = squeeze(mean(D(:,s,:,:),I.dTrials));
        
        y = y(I.roiMaskIdx,:)';
                
        if ~isempty(rectifyFcn)
            y = feval(rectifyFcn,y);
        end
        
        for i = 1:size(y,2)
            [r,lags] = xcorr(y(:,i),stimSig,maxLag.*I.Fs,'coeff');
            r(lags < 0)  = [];
            lags(lags<0) = [];
            [R(i,s),k]   = max(abs(r));
            Rlag(i,s)    = lags(k);
        end
    end
    
    
    
    Zr{pid} = zeros([I.nPixels I.nStim]);
    Zr{pid}(I.roiMaskIdx,:) = R;
    Zr{pid} = reshape(Zr{pid},[I.nY I.nX I.nStim]);
    
    Zlag{pid} = zeros([I.nPixels I.nStim]);
    Zlag{pid}(I.roiMaskIdx,:) = Rlag;
    Zlag{pid} = reshape(Zlag{pid},[I.nY I.nX I.nStim]);
    
    fprintf('.')
end
fprintf(' done\n')

% Display results
clf

Xr = []; Xlag = [];
for pid = 1:length(Zr)
    Xr = cat(3,Xr,Zr{pid});
    Xlag = cat(3,Xlag,Zlag{pid});
end

Xlag = Xlag ./ I.Fs; % frames -> seconds

subplot(121);

r = quantile(Xr(:),.999);
montage(Xr,'displayrange',[0 r],'size',[I.nPlanes I.nStim]);

xlabel(sprintf('Stimulus (1\\rightarrow%d)',I.nStim),'FontSize',14)
ylabel({'Plane',sprintf('(%d\\leftarrow1)',I.nPlanes)},'FontSize',14)
title(sprintf('%s | maxLag = %.1f s',I.fileRoot,maxLag),'interpreter','none','FontSize',14)

colormap(gca,jet)
h = colorbar;
h.FontSize = 12;
h.Label.String = 'max corr. coef. (\itr)';
h.Label.FontSize = 14;


subplot(122);
montage(Xlag,'displayrange',[0 maxLag],'size',[I.nPlanes I.nStim]);

xlabel(sprintf('Stimulus (1\\rightarrow%d)',I.nStim),'FontSize',14)
title(sprintf('%s | maxLag = %.1f s',I.fileRoot,maxLag),'interpreter','none','FontSize',14)

colormap(gca,parula(7))
h = colorbar;
h.FontSize = 12;
h.Label.String = '\itr_{lag} (sec)';
h.Label.FontSize = 14;





%% rank pixels by largest stimulus correlation?

rThreshold = .01;

I = Plane(1).I;
stimRanked = nan([I.nY I.nX I.nStim]);
for i = 1:length(Plane)
    I = Plane(i).I;
    [m,sid] = max(Zr{i},[],3);
    ind = m < rThreshold;
    sid(ind) = 0; % 0 = background
    sid(~I.roiMaskInd) = 0;
    stimRanked(:,:,i) = sid;
    
    subplot(2,3,i)
    imagesc(sid);
    axis image
    title(sprintf('Plane %d',I.id))
    drawnow
end
colormap([1 1 1; prism(I.nStim)]);

%%
ffn = fullfile(I.filePath,sprintf('%s_stimRanked.nii',I.fileRoot));
niftiwrite(stimRanked,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = I.voxelSpacing(1:3);
niftiwrite(stimRanked,ffn,ninfo);
fprintf('Wrote "%s"\n',ffn)

%% 
I = Plane(1).I;
for sid = 1:I.nStim
    v = Xr(:,:,sid:I.nStim:end);
    fn = sprintf('%s_Stim_%d_rMax.nii',I.fileRoot,sid);
    ffn = fullfile(I.filePath,fn);
    niftiwrite(v,ffn);
    ninfo = niftiinfo(ffn);
    ninfo.PixelDimensions = I.voxelSpacing(1:3);
    niftiwrite(v,ffn,ninfo);
end
fprintf(' done\n')


%%
    subplot(2,3,pid)
    
    mR = cellfun(@(a,b) mean(a(b,:)),R,Rind,'uni',0);
    mR = cell2mat(mR)';
    
    xl = [1 size(mR,1)];
    yl = [-1.1 1.1] .* max(abs(mR(:)));
    
    plot(xl,[0 0],'-k','linewidth',2);
    grid on
    hold on
    patch(stimFrames([1 2 2 1 1]),yl([1 1 2 2 1]),[.4 1 .4],'linestyle','none');
    h = plot(mR,'linewidth',2);
    hold off
    xlim(xl);
    ylim(yl);
    
    title(sprintf('Plane %d',pid));
    
    if pid == 1
        lgd = legend(h,cellstr(num2str((1:I.nStim)','stim %d\n'))','location','best');
        lgd.Orientation = 'horizontal';
    end
   
    [c,r]=ind2sub([3 2],pid);
    if c == 1
        ylabel('z-score');
    end
    if r == 2
        xlabel('frames');
    end
% end




%% maximum evoked spatial response











