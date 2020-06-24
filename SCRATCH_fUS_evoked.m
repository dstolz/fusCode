%% Mean evoked response

stimFrames = [20 25];
maxLag = 5;

stimSig = zeros(Plane(1).I.nFrames,1);
stimSig(stimFrames(1):stimFrames(2)) = 1;



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
        
        for i = 1:size(y,2)
%             c = corrcoef(y(:,i),stimSig);
%             R(i,s) = c(2);

            [r,lags] = xcorr(y(:,i),stimSig,maxLag,'unbiased');
            r(lags < 0) = [];
            lags(lags<0) = [];
            [R(i,s),k] = max(abs(r));
            Rlag(i,s) = lags(k);
        end
    end
    
    
    
    Zr{pid} = zeros([I.nPixels I.nStim]);
    Zr{pid}(I.roiMaskIdx,:) = R;
    Zr{pid} = reshape(Zr{pid},[I.nY I.nX I.nStim]);
    
    Zlag{pid} = zeros([I.nPixels I.nStim]);
    Zlag{pid}(I.roiMaskIdx,:) = Rlag;
    Zlag{pid} = reshape(Zlag{pid},[I.nY I.nX I.nStim]);
    
end

%%

X = [];
for pid = 1:length(Zr)
    X = cat(3,X,Zr{pid});
end




clf

r = quantile(X(:),.999);

% montage(X,'displayrange',r*[-1 1]);
montage(X,'displayrange',[0 r]);

xlabel('Stimulus','FontSize',16)
ylabel('Plane','FontSize',16)
title(sprintf('%s | maxLag = %d',I.fileRoot,maxLag),'interpreter','none','FontSize',18)

colormap jet
h = colorbar;
h.FontSize = 14;
h.Label.String = 'correlation coef (\itr)';
h.Label.FontSize = 18;

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
    v = X(:,:,sid:I.nStim:end);
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











