%% Preprocessing script and some other useful tools

% make sure code is on path
if isempty(which('fus_resaveAsPlanes'))
    fprintf(2,'Make sure you add the fusCode directory to Matlab''s path!\n')
    fprintf(2,'See <a href="matlab:help addpath">help addpath</a> or use the <a href="matlab:pathtool">pathtool</a>\n')
end



%% Set whwere you data lives
pth = 'C:\Users\Daniel\Documents\MATLAB\FigurePopoutData';
cd(pth)

% Specify the "root" of your filename.  Just the mat file downloaded from
% Ali's Google drive.
% fnRoot = 'Rumba\Rum078_Streaming\AllData_Streaming_rum078.mat';
% fnRoot = 'Rumba\Rum074_Streaming\AllData_Streaming_rum074.mat';
fnRoot = 'Rumba\Rum074_Tonotopy\AllData_Tonotopics_rum074.mat';

%% Resave original data
% Resave data in an array of Planes with some additional info.
% Only need to do this once per dataset.

fus_resaveAsPlanes(fnRoot);


% Plane is a structure array with the following fields:
% Plane.Data     ... 5D matrix with dims: Pixels x Stim x Trials x Frames
% Plane.I        ... Structure with information about the dataset
% Plane.Manifest ... Cell array to keep tabs on what manipulations have
%                    been applied to the data.

%% Load Planes
% Load data that has already been reorganized using fus_resaveAsPlanes
Plane = fus_loadPlanes(fnRoot);




%% View all planes in a montage
% This can be run at anypoint during analysis.

f = figure('color','k','units','normalized');
ax = axes(f,'color','k','Position',[0 0 1 .95]);
fus_viewPlanes(Plane,ax);
colormap(ax,'hot')
ax.Title.String = Plane(1).I.fileRoot;
ax.Title.Color = 'w';
ax.Title.Interpreter = 'none';




%% Run ROI Explorer
% Quick and dirty gui to let you draw an ROI on a plane and plot the
% mean pixel timecourses for all stimuli within the roi.  
% This can be run at anypoint during analysis.
% See help fus_PlaneExplorer for more options.

planeID = 2;

roiType = 'rectangle';
% roiType = 'circle';
% roiType = 'ellipse';
% roiType = 'freehand';
% roiType = 'polygon'; 
% roiType = 'assisted';


fus_PlaneExplorer(Plane(planeID),roiType);







%% Preprocess Data

% Uncomment to reload planes each time you preprocess the data
Plane = fus_loadPlanes(fnRoot); 


% Preprocessing option defaults -------------
PreOpts.preStimFrames   = 1:3; %1:10; % [] = no baseline correction
PreOpts.maskType        = 'auto'; % options: 'freehand','assisted','auto','none'
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
%  leave empty to not filter in the time domain
PreOpts.lpFc    = []; % Hz
PreOpts.hpFc    = []; % Hz
% PreOpts.lpFc  = 1.2; % Hz
% PreOpts.hpFc  = 0.1; % Hz
PreOpts.detrendData = true; % applies linear detrend for each pixel on a trial-by-trial basis



% In-Plane Spatial smoothing ----------------
% fus_smoothSpatial convolves each Plane at each timepoint with a 2d
% gaussian.  The default is 5 pixels square (~1.8 FWHM pixels)
% Comment out this line for no spatial smoothing
Plane = fus_smoothSpatial(Plane,5); 





% preprocess each plane at a time
for pid = 1:Plane(1).I.nPlanes
    Data = Plane(pid).Data;
    I    = Plane(pid).I;
    
    
    if any(contains(Plane(pid).Manifest,'Completed preprocessing data'))
        warning('Seems that Plane %d data has already been processed. Skipping.',pid)
        continue
    end
    
    
    clf
    set(gcf,'Color','k','units','normalized');
    
    
    
    % Optional Temporal high/low pass filtering
    if ~isempty(PreOpts.hpFc)
        fprintf('Applying high-pass filter at %f Hz ...',PreOpts.hpFc)
        Data = highpass(Data,PreOpts.hpFc,I.Fs);
        for j = 1:I.nStim
            for k = 1:I.nTrials
                Data(:,j,k,:) = highpass(squeeze(Data(:,j,k,:))',PreOpts.hpFc,I.Fs)';
            end
        end
        Plane(pid).Manifest{end+1} = sprintf('Applied high-pass filter at %f Hz',PreOpts.hpFc);
        fprintf(' done\n')
    end
    if ~isempty(PreOpts.lpFc)
        fprintf('Applying low-pass filter at %f Hz ...',PreOpts.lpFc)
        for j = 1:I.nStim
            for k = 1:I.nTrials
                Data(:,j,k,:) = lowpass(squeeze(Data(:,j,k,:))',PreOpts.lpFc,I.Fs)';
            end
        end
        Plane(pid).Manifest{end+1} = sprintf('Applied low-pass filter at %f Hz',PreOpts.lpFc);
        fprintf(' done\n')
    end
    
    
    
    
    % Optionally Normalize to a pre-stim baseline for each trial
    if ~isempty(PreOpts.preStimFrames)
        B = mean(Data(:,:,:,PreOpts.preStimFrames),I.dFrames);
        B = repmat(B,[1 1 1 I.nFrames]);
        Data = (Data - B) ./ B;
        Plane(pid).Manifest{end+1} = 'Baseline normalizaton';
    end
    
    
    
    
    % Optionally detrend the data for each stimulus trial over time
    if PreOpts.detrendData
        for j = 1:I.nStim
            for k = 1:I.nTrials
                Data(:,j,k,:) = detrend(squeeze(Data(:,j,k,:)));
            end
        end
        Plane(pid).Manifest{end+1} = 'Linear detrended';
    end
    
    ax = subplot(221);
    imagesc(ax,mean(reshape(Plane(pid).Data,I.shapeYXA),3));
    axis image
    colormap(ax,'hot');
    ax.Title.String = [I.fileRoot sprintf(' - Plane %d',I.id)];
    ax.Title.Color = 'w';
    ax.Title.Interpreter = 'none';
    drawnow
    
   
    
    
    
    
    % optionally apply a 'premask' to constrain the std histogram of the
    % plane
    preMaskInd = true([I.nY I.nX]);
    
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
    
    
    
    
    
    
    
    % use std across all data for each pixel to compute or draw the mask
    mData = std(Data,0,[I.dFrames, I.dStim, I.dTrials]);
    mData = reshape(mData,[I.nY I.nX]);
        
    
    
    
    
    
    
    % create 2d binary mask
    switch PreOpts.maskType          
        
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
            I.roiMaskInd = true(I.nY,I.nX);
            
        otherwise
            fprintf('Draw ROI on top right image\n')
            roi = feval(sprintf('draw%s',lower(PreOpts.maskType)),ax,'Color','r');
            if isempty(roi)
                ind = true(I.nPixels,1);
            else
                ind = createMask(roi);
            end
            I.roiMaskInd = reshape(ind,[I.nY I.nX]);
    end
    
    I.roiMaskInd = I.roiMaskInd & preMaskInd;

    [y,x] = find(bwperim(I.roiMaskInd));
    I.roiMaskPerimeterXY = [x y];

    ax = subplot(222);
    imagesc(ax,10*log10(mData));
    colormap(ax,'parula');
    axis(ax,'image');
    ax.Title.String = [I.fileRoot ' - std'];
    ax.Title.Color = 'w';
    ax.Title.Interpreter = 'none';
    hold(ax,'on');
    plot(ax,I.roiMaskPerimeterXY(:,1),I.roiMaskPerimeterXY(:,2),'.r');
    hold(ax,'off');
    drawnow
    
    ax = subplot(221);
    hold(ax,'on');
    plot(ax,I.roiMaskPerimeterXY(:,1),I.roiMaskPerimeterXY(:,2),'.c');
    hold(ax,'off');
    
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




%% Create 'structural' NIfTI volume

fn = sprintf('%s-fUS_Mean.nii',I.fileOriginal);
ffn = fullfile(cd,fn);

fus_toNifti(Plane,ffn);








