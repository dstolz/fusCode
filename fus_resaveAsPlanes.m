function ffns = fus_resaveAsPlanes(ffn)
% Resave massive data matrix into individual files by plane for more 
% efficient memory usage
fprintf('loading file "%s"...\n',ffn)

load(ffn,'epoch_bef');

fprintf('resaving to individual files for each plane ...\n')

[pn,fnRoot,~] = fileparts(ffn);


epoch_bef = single(epoch_bef);

isBoubenec = startsWith(fnRoot,'Boubenec');

if isBoubenec
    fprintf(2,'This is data from "Boubenec et al, 2018" and may have some different voxel dimensions.\n')
end

n = size(epoch_bef,6);
for i = 1:n
    fnNew = sprintf('%s_Plane_%d.mat',fnRoot,i);
    fprintf('\tSaving plane %d of %d as "%s" ...',i,n,fnNew)
    
    Data = epoch_bef(:,:,:,:,:,i);
    
    % Reshape Data so all pixels are in first dimension to make this easier to process
    
    % Data -> Pixels x Stim x Trials x Frames
    s = size(Data);
    Data = reshape(Data,[s(1)*s(2),s(3:end)]);
    
    
    
    % Information ---------------------------
    I.id = i;
    I.nPlanes = n;
    
    I.nY      = size(epoch_bef,1);
    I.nX      = size(epoch_bef,2);
    
    I.nPixels = size(Data,1);
    I.nStim   = size(Data,2);
    I.nTrials = size(Data,3);
    I.nFrames = size(Data,4);
    
    I.shapePSTF = [I.nPixels I.nStim I.nTrials I.nFrames];
    I.shapeYXA  = [I.nY I.nX I.nStim*I.nTrials*I.nFrames];
    I.shapePA   = [I.nPixels I.nStim*I.nTrials*I.nFrames];
    I.shapeFull = [I.nY I.nX I.nStim I.nTrials I.nFrames];
    
    I.dPixels = 1;
    I.dStim   = 2;
    I.dTrials = 3;
    I.dFrames = 4;
        
    I.fileName     = fnNew;
    I.filePath     = pn;
    I.fileRoot     = fnRoot;
    I.fileOriginal = ffn;
    
    if isBoubenec
        I.Fs = 1;
    else
        I.Fs = 2.5; % Hz
    end
    
    I.voxelSpacing = [.1 .1 .4 1/I.Fs]; % [y,x,plane,time]
    I.voxelDimensions = {'y' 'x' 'plane' 'time'};
    
    I.roiMaskInd = true([I.nY I.nX]);
    I.roiMaskIdx = find(I.roiMaskInd);
    [y,x] = ind2sub([I.nY I.nX],find(bwperim(I.roiMaskInd)));
    I.roiMaskPerimeterXY = [x y];
    
    I.transform = affine2d;
    
    I.useParallel = false;
    
    I = orderfields(I);
    
    
    Structural = mean(Data,[I.dStim I.dTrials I.dFrames]);
    Structural = reshape(Structural,[I.nY I.nX]);
    
    Overlay = [];
    
    Manifest = {'Resaved data by plane'};
    
    ffns{i} = fullfile(pn,fnNew);
    
    save(ffns{i},'Data','Structural','I','Manifest','Overlay','-nocompression','-v7.3');
    fprintf('done\n')    
end


