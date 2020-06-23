
pth = 'C:\Users\Daniel\Documents\MATLAB\FigurePopoutData';
cd(pth)

% fnRoot = 'Kazoo\Kaz046\AllData_Tonotopics_Kaz046';
% fnRoot = 'Kazoo\Kaz052\AllData_Kaz052';

% fnRoot = 'Rumba\Rum074_Tonotopy\AllData_Tonotopics_rum074';

% fnRoot = 'Rumba\Rum074_Streaming\AllData_Streaming_rum074';
% fnRoot = 'Rumba\Rum075_Streaming\AllData_Streaming_rum075';
fnRoot = 'Rumba\Rum078_Streaming\AllData_Streaming_rum078';





%% Only need to resave original data once
% Resave data in an array of Planes with some additional info.

fus_resaveAsPlanes(fnRoot);




%% Load Planes
% Load data that has already been reorganized using fus_resaveAsPlanes
Plane = fus_loadPlanes(fnRoot);

%% View all planes
f = figure('color','k','units','normalized');
ax = axes(f,'color','k','Position',[0 0 1 .95]);
fus_viewPlanes(Plane,ax);
colormap(ax,'hot')
ax.Title.String = Plane(1).I.fileRoot;
ax.Title.Color = 'w';
ax.Title.Interpreter = 'none';

%% Preprocess Data
    
% Preprocessing option defaults -------------
PreOpts.preStimFrames   = []; %1:10; % [] = no baseline correction
PreOpts.maskType        = 'auto'; % options: 'manual','auto','none'
PreOpts.pixelThreshold  = .8; % used for auto only

% Set the following cut* fields to exclude parts of the plane from the
% mask.  This is useful for heavy artifacts that the automatic procedure
% doesn't catch.  This will be applied prior to the masking procedure
% indicated with maskType.  Leave fields empty, [], to not use them.
PreOpts.cutBelowRow     = []; %63;
PreOpts.cutAboveRow     = []; %20;
PreOpts.cutLeftOfCol    = []; %45;
PreOpts.cutRightOfCol   = []; %90;

% Temporal filtering options ----------------
PreOpts.lpFc    = []; % Hz
PreOpts.hpFc    = []; % Hz
% PreOpts.lpFc  = 1.2; % Hz
% PreOpts.hpFc  = 0.1; % Hz
PreOpts.detrendData = false; % applies linear detrend for each pixel on a trial-by-trial basis


% In-Plane Spatial smoothing ----------------
Plane = fus_smoothSpatial(Plane);

for pid = 1:Plane(1).I.nPlanes
    Data = Plane(pid).Data;
    I    = Plane(pid).I;
    
    
    if any(contains(Plane(pid).Manifest,'Completed preprocessing data'))
        warning('Seems that this data has already been processed. Skipping.')
        continue
    end
    
    
    clf
    set(gcf,'Color','k','units','normalized');
    
    
    
    % Temporal filtering
    Data = reshape(Data,I.shapePA)';
    if ~isempty(PreOpts.hpFc)
        Data = highpass(Data,PreOpts.hpFc,I.Fs);
        Plane(pid).Manifest{end+1} = sprintf('Applied low-pass filter at %f Hz',PreOpts.hpFc);
    end
    if ~isempty(PreOpts.lpFc)
        Data = lowpass(Data,PreOpts.lpFc,I.Fs);
        Plane(pid).Manifest{end+1} = sprintf('Applied low-pass filter at %f Hz',PreOpts.lpFc);
    end
    Data = reshape(Data',I.shapePSTF);
    
    
    
    
    % First Detrend Data
    if PreOpts.detrendData
        for j = 1:I.nStim
            for k = 1:I.nTrials
                Data(:,j,k,:) = detrend(squeeze(Data(:,j,k,:)));
            end
        end
        Plane(pid).Manifest{end+1} = 'Linear detrended';
    end
    
    ax = subplot(221);
    fus_viewPlanes(Plane(I.id),ax);
    colormap(ax,'hot');
    ax.Title.String = [I.fileRoot sprintf(' - Plane %d',I.id)];
    ax.Title.Color = 'w';
    ax.Title.Interpreter = 'none';
    drawnow
    
   
    
    preMaskInd = true([I.nX I.nY]);
    
    if ~isempty(PreOpts.cutLeftOfCol)
        preMaskInd(:,1:PreOpts.cutLeftOfCol) = false;
        Plane(pid).Manifest{end+1} = sprintf('Spatial Mask cutLeftOfCol = %d',PreOpts.cutLeftOfCol);
    end
    
    if ~isempty(PreOpts.cutRightOfCol)
        preMaskInd(:,PreOpts.cutRightOfCol:end) = false;
        Plane(pid).Manifest{end+1} = sprintf('Spatial Mask cutRightOfCol = %d',PreOpts.cutRightOfCol);
    end
    
    if ~isempty(PreOpts.cutAboveRow)
        preMaskInd(1:PreOpts.cutAboveRow,:) = false;
        Plane(pid).Manifest{end+1} = sprintf('Spatial Mask cutAboveRow = %d',PreOpts.cutAboveRow);
    end
    
    if ~isempty(PreOpts.cutBelowRow)
        preMaskInd(PreOpts.cutBelowRow:end,:) = false;
        Plane(pid).Manifest{end+1} = sprintf('Spatial Mask cutBelowRow = %d',PreOpts.cutBelowRow);
    end
    
    if any(~preMaskInd(:))
        ind = repmat(reshape(preMaskInd,[I.nPixels 1]),[1 I.nStim I.nTrials I.nFrames]);
        Data(~ind) = nan;
    end
    
    % use std across all data for each pixel to compute mask
    mData = std(Data,0,[I.dFrames, I.dStim, I.dTrials]);
    mData = reshape(mData,[I.nX I.nY]);
        
    ax = subplot(222);
    imagesc(ax,mData);
    colormap(ax,'parula');
    axis(ax,'image');
    ax.Title.String = [I.fileRoot ' - std'];
    ax.Title.Color = 'w';
    ax.Title.Interpreter = 'none';
    drawnow
    
    
    % create 2d logical mask
    switch PreOpts.maskType
        case 'manual'
            fprintf('Draw ROI\n')
            roi = drawpolygon(gca);
            if isempty(roi)
                ind = true(I.nPixels,1);
            else
                ind = createMask(roi);
            end
            I.roiMaskInd = reshape(ind,[I.nX I.nY]);
        case 'auto'
            qthresh = quantile(mData(:),PreOpts.pixelThreshold);
            ind = mData > qthresh;
            ind = bwmorph(ind,'hbreak');
            ind = bwmorph(ind,'spur');
            ind = imfill(ind,'holes');
            ind = bwmorph(ind,'open');
            ind = bwareafilt(ind,1);
            I.roiMaskInd = ind;
        case 'none'
            I.roiMaskInd = true(I.nX,I.nY);
    end
    
    I.roiMaskInd = I.roiMaskInd & preMaskInd;

    I.roiMaskIdx = find(I.roiMaskInd(:));
    
    fprintf('"%s" Preprocessing Plane %d of %d ...',I.fileRoot,I.id,I.nPlanes)
    
    ind = repmat(reshape(I.roiMaskInd,[I.nPixels 1]),[1 I.nStim I.nTrials I.nFrames]);
    
    Data(~ind) = nan;
    
    Plane(pid).Data = Data;
    Plane(pid).Manifest{end+1} = sprintf('Applied %s mask',PreOpts.maskType);
    
    ax = subplot(223);
    fus_viewPlanes(Plane(pid),ax);
    colormap(ax,'hot');
    ax.Title.String = [I.fileRoot '- Mask'];
    ax.Title.Color = 'w';
    ax.Title.Interpreter = 'none';
    drawnow
    
    
    
    
    
    % Normalize to a pre-stim baseline for each trial
    if ~isempty(PreOpts.preStimFrames)
        B = mean(Data(:,:,:,PreOpts.preStimFrames),I.dFrames);
        B = repmat(B,[1 1 1 I.nFrames]);
        Data = (Data - B) ./ B;
        Plane(pid).Manifest{end+1} = 'Baseline normalizaton';
    end
    
    
    
    
    
    
    
%     % Replace artifactual frames with interpolated values
%     mpData = mean(Data,[I.dTrials,I.dPixels],'omitnan');
%     ind = isoutlier(mpData,'median',I.dFrames);
%     
%     fprintf(' %d outlier frames detected ...',nnz(ind))
%     
%     I.Preprocessed.OutlierFrames = ind;
%     
%     ind = repmat(ind,[I.nPixels,1,I.nTrials,1]);
%     
%     Data(ind) = nan;
%     
%     Data = fillmissing(Data,'makima',I.dFrames);
    

    
    fprintf(' done\n')
    

%     fprintf('"%s" Saving with Data ...',fnPlane)
%     save(fnPlane,'-append','-struct','P','Data','I');
%     fprintf(' done\n')
    
    I.PreOpts = PreOpts;

    
    Plane(pid).Data = Data;
    Plane(pid).I = I;
    
    ax = subplot(224);
    fus_viewPlanes(Plane(pid),ax);
    colormap(ax,'jet');
    ax.Title.String = I.fileRoot;
    ax.Title.Color = 'w';
    ax.Title.Interpreter = 'none';
    
    
    Plane(pid).Manifest{end+1} = 'Completed preprocessing data';
    
    pause(.5);
%     pause
end
clear B Data





%% View all planes from square-maksed data
clear D
for pid = 1:length(Plane)
    I = Plane(pid).I;
    d = rms(Plane(pid).Data,[I.dStim I.dFrames I.dTrials]);
    d = reshape(d,[I.nX I.nY]);
    d(:,all(isnan(d),1)) = [];
    d(all(isnan(d),2),:) = [];
    D(:,:,pid) = d;
end

r = quantile(D(:),[.01 .99]);
montage(D,'displayrange',r);
colormap parula
set(gcf,'color','k')
title(Plane(1).I.fileRoot,'color','w','interpreter','none')




%% Create 'structural' NIFTI volume

fn = sprintf('%s-fUS_Mean.nii',I.fileOriginal);
ffn = fullfile(rootPath,fn);

fus_toNifti(Plane,ffn);



























%% Run ROI analysis

figure

planeID = 1;

radius = 3;

% figure('windowstyle','docked')

I = Plane(planeID).I;

subplot(4,1,[1 3])
X = mean(Plane(planeID).Data,[I.dFrames, I.dStim, I.dTrials]);
X = reshape(X,[I.nX I.nY]);
imagesc(X);
axis image
set(gca,'xtick',[],'ytick',[]);
colormap hot
% title(fn,'Interpreter','none')

[x,y] = ginput(1);

% % roi = drawpolygon(gca);
roi = drawcircle('Center',[x y],'Radius',radius);
% if isempty(roi), return; end

ind = createMask(roi);

ind = reshape(ind,[I.nX I.nY]);

mROI = squeeze(mean(Plane(planeID).Data(ind,:,:,:),[I.dTrials, I.dPixels],'omitnan'));
% mROI = squeeze(std(Plane(planeID).Data(ind,:,:,:),0,[I.dTrials, I.dPixels]));

mROI(all(isnan(mROI),2),:) = 0;

ivec = 1:0.25:I.nFrames;
for i = 1:I.nStim
    miROI(i,:) = interp1(1:I.nFrames,mROI(i,:),ivec,'makima');
end

ax = subplot(414);

plot(ax,ivec,miROI')
grid(ax,'on');
xlim(ax,[1 I.nFrames]);

set(ax,'xaxislocation','top');

h = legend(ax,cellstr(num2str((1:I.nStim)')), ...
    'Location','EastOutside','Orientation','vertical');
h.Title.String = 'StimID';

x = ax.XAxis.TickValues/2.5;
ax2 = axes(gcf,'position',ax.Position,'color','none', ...
    'ytick',[],'xlim',xlim(ax)/2.5,'xtick',x);


xlabel(ax,'frames')
xlabel(ax2,'time (s)')









