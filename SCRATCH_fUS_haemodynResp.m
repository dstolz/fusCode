%% Approximate haemodynamic response and determine how well each voxel correlates

analysisWin = [13 15]; %sec
% analysisWin = [11 15];

stimOnset = 10; % Boubenec
% stimOnset = 8; % NSL

useOverallMeanHR = true;





I = Plane(1).I;


analysisWinFrames = round(I.Fs*analysisWin);
analysisWinFrames = analysisWinFrames(1):analysisWinFrames(2);

meanHaemoRespByStim = zeros(I.nFrames,length(Plane));
for pid = 1:length(Plane)
    I = Plane(pid).I;
    
    D = mean(Plane(pid).Data(I.roiMaskIdx,:,:,:),I.dTrials);
    
    Z = zscore(D,0,'all');
   
    zM = mean(Z(:,:,:,analysisWinFrames),I.dFrames);
    
    ind = zM >= 2 & zM <= 6;
    fprintf('Plane %d: %d voxels included in haemodynamic response\n',pid,nnz(ind))
    HR = [];
    for i = 1:I.nStim
        r = squeeze(Z(ind(:,i),i,:,:));
        if size(r,2) == 1, r = r'; end
        HR = cat(1,HR,r);
    end
    meanHaemoRespByStim(:,pid) = mean(HR)';
end

tvec = (0:I.nFrames-1)./I.Fs;

meanHaemoRespByStim(tvec<=stimOnset,:) = 0; % ignore pre-stim
meanHaemoResp = mean(meanHaemoRespByStim,2,'omitnan'); % omitnan if no voxels z >= 2

clf
plot(tvec,meanHaemoRespByStim)
hold on
plot(tvec,meanHaemoResp,'-k','linewidth',3);
hold off
grid on

xlabel('time (s)');
ylabel('amplitude (z-score)');
title(sprintf('%s - mean Haemodynamic Response estimate',I.fileRoot),'Interpreter','none')




%% pick voxels that have high correlation with the HR.  
C = zeros([I.nY I.nX I.nStim I.nPlanes]);
for pid = 1:I.nPlanes
    I = Plane(pid).I;
    
    if useOverallMeanHR
        fprintf('Computing correlation wih overall mean haemodynamic response, Plane %d of %d ...',pid,I.nPlanes)
    else
        fprintf('Computing correlation wih stimulus mean haemodynamic response, Plane %d of %d ...',pid,I.nPlanes)
    end
    
    D = squeeze(mean(Plane(pid).Data(I.roiMaskIdx,:,:,:),I.dTrials));
    
    R = zeros([I.nY I.nX I.nStim]);
    [col,row] = ind2sub([I.nY I.nX],I.roiMaskIdx);
    for i = 1:nnz(I.roiMaskInd)
        for j = 1:I.nStim
            if useOverallMeanHR
                R(col(i),row(i),j) = corr(squeeze(D(i,j,:)),meanHaemoResp,'type','Pearson');
            else
                R(col(i),row(i),j) = corr(squeeze(D(i,j,:)),meanHaemoRespByStim(:,pid),'type','Pearson');
            end
        end
    end
        
    C(:,:,:,pid) = R;
    
    fprintf(' done\n')
end

%
sC = C;
for i = 1:I.nStim
    sC(:,:,i,:) = smooth3(squeeze(C(:,:,i,:)),'gaussian',[3 3 3]);
end
%

rsC = reshape(sC,[I.nY I.nX I.nStim*I.nPlanes]);

zsC = atanh(rsC); % Fisher z-transform

zsC(zsC<.5) = 0;

%
clf

im = imtile(zsC,'GridSize',[I.nPlanes I.nStim]);

imagesc(im);
colormap jet
axis image
h = colorbar;
h.Label.String = 'z(\it\rho)';
set(gca,'clim',[0 1.5]);

ylabel('Plane #');
xlabel('Stim #');

n = size(im);
set(gca,'xtick',I.nX/2:I.nX:n(2),'xticklabel',1:I.nStim);
set(gca,'ytick',I.nY/2:I.nY:n(1),'yticklabel',1:I.nPlanes);

%% rank each voxel correlation by stimulus 
zsC = atanh(sC); % Fisher z-transform
% zsC(zsC < 1) = nan;

% zC = C;

[mz,idx] = max(zsC,[],3,'omitnan');

ind = all(zsC<1,3);
idx(ind) = nan;
mz(ind)  = nan;

mz  = squeeze(mz);
idx = squeeze(idx);

for i = 1:length(Plane)
    I = Plane(i).I;
    m = idx(:,:,i);
    m(~I.roiMaskInd) = nan;
    m(m==0) = nan;
    Plane(i).Overlay = m;
end
%

clf

ax = gca;

fus_imtile(Plane,ax,'maskalpha',0.5);

h = fus_imtileOverlay(Plane);
colormap(h.Parent,[0 0 0; jet(5)])

%% Export graphics
ffn = fullfile(I.filePath,[I.fileRoot '-HR_Tonotopy.tif']);
fprintf('Writing %s ...',ffn)
exportgraphics(gcf,ffn,'resolution',300);
fprintf(' done\n')



%% to nifti

v = idx;

ffn = fullfile(I.filePath,[I.fileRoot '-HR_Tonotopy.nii']);
niftiwrite(v,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = [.1 .1 .3];%I.voxelSpacing(1:3);
niftiwrite(v,ffn,ninfo);
fprintf(' done\n')










