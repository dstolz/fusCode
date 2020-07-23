%% Add fusCode to Matlab's path - only need to do this once per session.
% Alternatively, use the pathtool to permanently add fusCode and
% subdirectories to Matlab's path.
addpath(genpath(fullfile(cd,'\fusCode')))











%% Example 1: Add planes to a new Volume object
filename = 'D:\fUS_Data\Boubenec\Data_Bright_AC\Boubenec_Data_Bright_AC.mat';
load(filename) % loades variable "epoch_bef"

% dims are in the same order as that of the loaded data
% Dims 'Y' and 'X' must come first
dims = {'Y','X','Events','Reps','Time','Planes'};

V = fus.Volume(epoch_bef,dims); % create Volume

[~,V.Name,~] = fileparts(filename); % optionally set the Volume's name


clear epoch_bef % don't need original data anymore


disp(V)















%% Example 2A: Load raw data and stimulus Events into a Volume
pth = 'D:\fUS_Data\Ali_RawData\rum069'; % Root directory with raw Plane data in subfolders


dims = {'Y','X','Time'}; % dims must start with 'Y','X',...

% find all planes stored within the current directory
d = dir(pth);
d([1 2]) = [];
d(~[d.isdir]) = [];


stim = [602 1430 3400 8087 19234]; % stimulus parameters are manually secified
load('D:\fUS_Data\Ali_RawData\rum069\info_Tonotopics_rum069.mat'); % info
% manipulate info -> Plane x event
stim = stim(info(1:2:end,:)); % extract stimulus ids from loaded format
trialOnsetIdx = info(2:2:end,:); % extract onset frames from loaded format
stimDelay    = 10; % sec ??? not specified in file
stimDuration = 3;  % sec ??? not specified in file


clear E

V = fus.Volume; % initialize
for i = 1:length(d)
    % load the acquisition file which is a structure called Acquisition
    lpth = fullfile(d(i).folder,d(i).name);
    f = dir(fullfile(lpth,'*.acq'));
    ffn = fullfile(f.folder,f.name);
    load(ffn,'-mat') 
    
    Fs = 1./Acquisition.Param.dT_Doppler; % sampling rate
    
    data = squeeze(Acquisition.Data); % squeeze out singleton dimension in data
    data = permute(data,[2 1 3]); % transpose each frame
    
    clear Acquisition % discard original data
    
    V.add_plane(data,dims,Fs); % add the new data as a Plane in the Volume

    stimOnsetTime = (trialOnsetIdx(i,:)-1)./Fs+stimDelay;
    V.Plane(i).Event = fus.Event('Freq',stimOnsetTime,stim(i,:),stimDuration,Fs,'Hz');
end

[~,V.Name,~] = fileparts(pth); % optionally set the Volume's name


disp(V)
fprintf('Plane dimOrder: %s\nPlane dimSizes: %s\n', ...
    strjoin(V.Plane(1).dimOrder,' x '), ...
    mat2str(V.Plane(1).dimSizes))


%% Example 2B - Rearrange raw data Volume by the "Freq" Event
eventName = "Freq";
for i = 1:V.nPlanes
    V.Plane(i) = V.Plane(i).arrange_data_by_event(eventName,[],[-10 10],"Plane");
    V.Plane(i).update_log('Rearranged raw data by "%s"',eventName);
end
disp(V)
fprintf('Plane dimOrder: %s\nPlane dimSizes: %s\n', ...
    strjoin(V.Plane(1).dimOrder,' x '), ...
    mat2str(V.Plane(1).dimSizes))











%% View montage of "Structural"
figure
V.montage;









%% Explore averaged trial data for each stimulus for a plane
% This will update as plane data is manipulated if left open
planeID = 4;
V.Plane(planeID).explorer; % defaults to 'Rectangle'
% V.Plane(planeID).explorer('Circle');
% V.Plane(planeID).explorer('Polygon');









%% Rigid alignment of all planes
V.align_planes;











%% Volumetric spatial smoothing
N = [3 3 3]; % Y x X x Time
V.smooth(N);





%% Create data mask. Uncomment one method
thresholdGuess = 2;
for i = 1:V.nPlanes
    % Method 1: Manually draw masks on each Plane
%     V.Plane(i).Mask.create_roi;       

    % Method 2: Threshold based on pixel luminance; Click the histogram to
    % adjust the threshold. Hit any key to move on to the next plane.
    V.Plane(i).Mask.create_threshold(thresholdGuess); 
    pause
end


% TODO: Show montage w/ masks


%% Apply Baseline correction to all planes in the volume
% batch is a convenient function for running the same function on
% all planes.
baselineWindow = [0 8]; % seconds
V.batch(@baseline_correct,baselineWindow);










%% Use the Log associated with each plane to see how the Plane Data has been manipulated so far
planeId = 6;
V.Plane(planeId).print_log




%% Run searchlight classifier
% Use support vector machines to try to classify events from each other. 
% This example uses the fus.Volume.searchlight function which iterates 
% through every valid voxel (within mask) of a volume and submits the
% 3D block of data to some function.  
% 
% Here, classify_ecoc is used to implement multiclass, error-correcting
% output codes model using support-vector machine "one-vs-all" binary
% learners.  classify_ecoc is a custom function that expects to be called
% from the fus.Volume.searchlight function. classify_ecoc ultimately calls
% the Matlab Statistics and Machine Learning toolbox function fitcecoc.
% See classify_ecoc, fitcecoc for details.
%
% The fus.Volume.searchlight function is generalized to analyze all overlapping 
% subvolumes.  This function will optionally use the Parallel Computing Toolbox 
% if it's available to iterate over subvolumes.
% See help fus.Volume.searchlight for more details. 
%
% Note that this example will take a loooong time to compute, even when
% parallelized, on a large volume.  I'll include a quicker example soon.

tmpSVM = templateSVM( ...
    'KernelFunction','rbf', ...
    'KernelScale','auto', ...
    'Standardize',true, ...
    'OutlierFraction',.01, ...
    'IterationLimit',1e8);

f = 15; % define which frames to analyze

% these parameters are passed to classify_ecoc
par = {'foi',f,'template',tmpSVM}; 

[R,n] = V.searchlight(@classify_ecoc,'fncParams',par);









