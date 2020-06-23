function ffns = fus_resaveAsPlanes(ffn)
% Resave massive data matrix into individual files by plane for more 
% efficient memory usage
fprintf('loading massive file "%s"...\n',ffn)

load(ffn,'epoch_bef');

fprintf('resaving by plane to reduce memory load ...\n')

[pn,fnRoot,~] = fileparts(ffn);


epoch_bef = single(epoch_bef);

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
    
    I.nX      = size(epoch_bef,1);
    I.nY      = size(epoch_bef,2);
    
    I.nPixels = size(Data,1);
    I.nStim   = size(Data,2);
    I.nTrials = size(Data,3);
    I.nFrames = size(Data,4);
    
    I.shapePSTF = [I.nPixels I.nStim I.nTrials I.nFrames];
    I.shapeXYA  = [I.nX I.nY I.nStim*I.nTrials*I.nFrames];
    I.shapePA   = [I.nPixels I.nStim*I.nTrials*I.nFrames];
    
    I.dPixels = 1;
    I.dStim   = 2;
    I.dTrials = 3;
    I.dFrames = 4;
        
    I.fileName     = fnNew;
    I.filePath     = pn;
    I.fileRoot     = fnRoot;
    I.fileOriginal = ffn;
    
    I.Fs = 2.5; % Hz
    
    I.voxelSpacing = [.1 .1 .4 1/I.Fs]; % [x,y,plane,time]
    I.voxelDimensions = {'x' 'y' 'plane' 'time'};
    
    I = orderfields(I);
    
    
    
    
    Manifest = {'Resaved data by plane'};
    
    ffns{i} = fullfile(pn,fnNew);
    
    save(ffns{i},'Data','I','Manifest','-nocompression','-v7.3');
    fprintf('done\n')    
end


