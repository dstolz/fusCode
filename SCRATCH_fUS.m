%% Preprocessing script and some other useful tools

% addpath c:\Users\Daniel\src\fusCode\
addpath c:\src\fusCode

% make sure code is on path
if isempty(which('fus_resaveAsPlanes'))
    fprintf(2,'Make sure you add the fusCode directory to Matlab''s path!\n')
    fprintf(2,'See <a href="matlab:help addpath">help addpath</a> or use the <a href="matlab:pathtool">pathtool</a>\n')
end



%% Set where you data lives
% pth = 'C:\Users\Daniel\Documents\MATLAB\FigurePopoutData';
pth = 'D:\fUS_Data';
cd(pth)


% fnRoot = 'Rumba\Rum078_Streaming\AllData_Streaming_rum078.mat';
% fnRoot = 'Rumba\Rum074_Streaming\AllData_Streaming_rum074.mat';
% fnRoot = 'Rumba\Rum074_Tonotopy\AllData_Tonotopics_rum074.mat';

% fnRoot = 'Boubenec\Data_Sright_AC\Boubenec_Data_Sright_AC.mat';
fnRoot = 'Boubenec\Data_Bright_AC\Boubenec_Data_Bright_AC.mat';
% fnRoot = 'Boubenec\Data_Vleft_AC\Boubenec_Data_Vleft_AC.mat';

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
% also see: fus_savePlanes
Plane = fus_loadPlanes(fnRoot);
% Plane = fus_loadPlanes(fnRoot,[],'-Preprocessed');


%% Optimize plane orientations
Plane = fus_align(Plane,true);


%% View all planes in a montage
% This can be run at anypoint during analysis.

f = figure('color','k','units','normalized');
ax = axes(f,'color','none','Position',[0 0 1 .95]);
fus_imtile(Plane,ax);
ax.Title.Color = 'w';



% %% Create 'structural' NIfTI volume
% 
% fn = sprintf('%s-fUS_Mean.nii',I.fileRoot);
% ffn = fullfile(I.filePath,fn);
% fus_toNifti(Plane,ffn);

%% Nifti w/ mask
v = [];
for i = 1:length(Plane)
    m = Plane(i).Structural;
    m(~Plane(i).I.roiMaskInd) = 0;
    v = cat(3,v,m);
end
v = v - min(v(:))+eps(class(v));
v = log10(v);
fn = sprintf('%s-fUS_Mean.nii',I.fileRoot);
ffn = fullfile(I.filePath,fn);
niftiwrite(v,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = [.1 .1 .3];%Plane(1).I.voxelSpacing(1:3);
niftiwrite(v,ffn,ninfo);
fprintf(' done\n')





%% Run ROI Explorer
% Quick and dirty gui to let you draw an ROI on a plane and plot the
% mean pixel timecourses for all stimuli within the roi.  
% This can be run at anypoint during analysis.
% See help fus_PlaneExplorer for more options.

planeID = 1;

roiType = 'rectangle';
% roiType = 'circle';
% roiType = 'ellipse';
% roiType = 'freehand';
% roiType = 'polygon'; 
% roiType = 'assisted';


fus_PlaneExplorer(Plane(planeID),roiType);

%% Create Data Mask

Plane = fus_loadPlanes(fnRoot); % reload data
Plane = fus_align(Plane,true);  % align planes


PreOpts.maskType        = 'graph'; % options: 'graph','freehand','assisted','rectangle','auto','none'
PreOpts.pixelThreshold  = .5; % used for auto only

% Set the following cut* fields to exclude parts of the plane from the
% mask.  This is useful for heavy artifacts that the automatic procedure
% doesn't catch.  This will be applied prior to the masking procedure
% indicated with maskType.  Leave fields empty, [], to not use them.
PreOpts.cutBelowRow     = []; %63;
PreOpts.cutAboveRow     = []; %5; %20;
PreOpts.cutLeftOfCol    = []; %20; %45;
PreOpts.cutRightOfCol   = []; %100; %90;


f = figure;

ax = axes(f);

% preprocess each plane at a time
for pid = 1:length(Plane)
    Data = Plane(pid).Data;
    I    = Plane(pid).I;
    
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
        
    tstr = sprintf('%s - Plane %d of %d',I.fileRoot,pid,I.nPlanes);

    % create 2d binary mask
    switch PreOpts.maskType          
        case 'graph'
            
            mData = Plane(pid).Structural;
            mData = log10(mData);
            mData = (mData - min(mData(:))) ./ (max(mData(:)) - min(mData(:))); % -> [0 1]
            
            imagesc(mData,'parent',ax);
            colormap(ax,bone(256));
            axis(ax,'image');
            title(ax,{tstr,'Draw over foreground (brain)'},'Color','b','interpreter','none')
            roiFg = drawfreehand(ax,'color','b');
            title(ax,{tstr,'Draw over background (not brain)'},'Color','r','interpreter','none')
            roiBg = drawfreehand(ax,'color','r');
            maskFg = createMask(roiFg);
            maskBg = createMask(roiBg);
            L = superpixels(mData,250);
            ind = lazysnapping(mData,L,maskFg,maskBg,'EdgeWeightScaleFactor',1000);
            
            ind = bwmorph(ind,'clean');
            ind = bwmorph(ind,'spur');
            
            I.roiMaskInd = ind;

        case 'auto'
            % use std across all data for each pixel to compute or draw the mask
            s = std(Data,0,[I.dFrames, I.dStim, I.dTrials]);
            s = reshape(s,[I.nY I.nX]);
            qthresh = quantile(s(:),PreOpts.pixelThreshold);
            ind = s < qthresh;
            ind = bwmorph(ind,'hbreak');
            ind = bwmorph(ind,'spur');
            ind = imfill(ind,'holes');
            ind = bwmorph(ind,'open');
            ind = bwareafilt(ind,1);
            I.roiMaskInd = ind;
            
        case 'auto2'
            
            
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

    hold(ax,'on');
    plot(ax,x,y,'.c');
    hold(ax,'off');
    
        
    I.roiMaskIdx = find(I.roiMaskInd(:));
    
    ind = repmat(reshape(I.roiMaskInd,[I.nPixels 1]),[1 I.nStim I.nTrials I.nFrames]);
    
    Plane(pid).I = I;
    
    
    pause(1);
end


cla(ax)
fus_imtile(Plane,ax);
maskTile = fus_imtileMask(Plane);
title(ax,sprintf('%s with Masks',I.fileRoot),'Color','k')



%% Preprocess Data

% Uncomment to reload planes each time you preprocess the data
% Plane = fus_loadPlanes(fnRoot); 
% Plane = fus_align(Plane,true);


% Preprocessing option defaults -------------
PreOpts.preStimFrames   = 1:10; % [] = no baseline correction


% Temporal filtering options ----------------
%  leave empty to not filter in the time domain
PreOpts.lpFc    = []; % Hz
PreOpts.hpFc    = []; % Hz
% PreOpts.lpFc  = 1.2; % Hz
% PreOpts.hpFc  = 0.1; % Hz
PreOpts.detrendData = true; % applies linear detrend for each pixel on a trial-by-trial basis




% Optional additional preprocessing ===========
PreOpts.preprocFcn = [];
% PreOpts.preprocFcn = 'halfWaveRectify'; % set [] to ignore
% PreOpts.preprocFcn = @abs;


% Volumetric or In-Plane Spatial smoothing ----------------
% fus_smoothSpatial convolves each Plane at each timepoint with a 3D
% gaussian. Default is [3 3 1] gaussian.
% Comment out the following line for no spatial smoothing
Plane = fus_smooth(Plane); 


% Apply spatial transform to all time frames --------------
PreOpts.applyTransform = true;


% preprocess each plane at a time
for pid = 1:Plane(1).I.nPlanes
    Data = Plane(pid).Data;
    I    = Plane(pid).I;
    
    fprintf('Preprocessing "%s" Plane %d of %d ...\n',I.fileRoot,pid,length(Plane))
    
    if any(contains(Plane(pid).Manifest,'Completed preprocessing data'))
        warning('Seems that Plane %d data has already been processed. Skipping.',pid)
        continue
    end
    
    
    
    
    % Optionally apply spatial transform to each plane
    if PreOpts.applyTransform
        fprintf('\tApplying spatial transform ...')
        Data = reshape(Data,I.shapeYXA);
        tD = [];
        for i = 1:size(Data,3)
            tD(:,:,i) = imwarp(Data(:,:,i),I.transform,'FillValues',eps);
        end
        n = size(tD);
        win = centerCropWindow2d(n([1 2]),[I.nY I.nX]);
        tD = tD(win.YLimits(1):win.YLimits(2),:,:);
        tD = tD(:,win.XLimits(1):win.XLimits(2),:);
        Data = reshape(tD,I.shapePSTF);
        clear tD
        Plane(pid).Data = Data;
        Plane(pid).Manifest{end+1} = 'Applied spatial transform';
        fprintf(' done\n')
    end
    
    
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
        fprintf('\tBaseline normalizing ...')
        B = mean(Data(:,:,:,PreOpts.preStimFrames),I.dFrames);
        Data = (Data - B) ./ B;
        Plane(pid).Data = Data;
        Plane(pid).Manifest{end+1} = 'Baseline normalizaton';
        fprintf(' done\n')
    end
    
    
    
    
    % Optionally detrend the data for each stimulus trial over time
    if PreOpts.detrendData
        fprintf('\tDetrending data by trial ...')
        for j = 1:I.nStim
            for k = 1:I.nTrials
                Data(:,j,k,:) = detrend(squeeze(Data(:,j,k,:)));
            end
        end
        Plane(pid).Manifest{end+1} = 'Linear detrended';
        fprintf(' done\n')
    end
    
   
    
    
    
    % Optional additional preprocessing functions
    if ~isempty(PreOpts.preprocFcn)
        
        if isa(PreOpts.preprocFcn,'function_handle')
            str = func2str(PreOpts.preprocFcn);
        else
            str = PreOpts.preprocFcn;
        end
        fprintf('\tApplying preprocessing function: %s\n',str)
        if isa(PreOpts.preprocFcn,'function_handle')
            Data = PreOpts.preprocFcn(Data);
        else
            switch lower(PreOpts.preprocFcn)
                case 'dcshift'
                    Data = Data + abs(min(D,[],I.dFrames));
                case 'halfwaverectify'
                    Data(Data < 0) = 0;
            end
        end
        Plane(pid).Manifest{end+1} = sprintf('Ran function "%s" on data',str);
        fprintf(' done\n')
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
    

    
    I.PreOpts = PreOpts;

    
    Plane(pid).Data = Data;
    Plane(pid).I = I;
    
    
    Plane(pid).Manifest{end+1} = 'Completed preprocessing data';
    
end
clear B Data




%% Save preprocessed data
fus_savePlanes(Plane,'-Preprocessed')


