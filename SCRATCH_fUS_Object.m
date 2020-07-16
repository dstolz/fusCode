%% Add fusCode to Matlab's path
addpath(genpath('c:\src\fusCode'))




%% Example 1: Add planes to a new Volume object
load('D:\fUS_Data\Boubenec\Data_Bright_AC\Boubenec_Data_Bright_AC.mat')

% dims are in the same order as that of the loaded data
% Dims 'Y' and 'X' must come first
dims = {'Y','X','Stim','Trials','Frames','Planes'};

V = fus.Volume(epoch_bef,dims); % create Volume

clear epoch_bef % don't need original data anymore

disp(V)



%% Example 2: Load raw data and stimulus Events into a Volume
pth = 'D:\fUS_Data\Ali_RawData\rum069'; % Root directory

dims = {'Y','X','Frames'}; % dims must start with 'Y','X',...

% find all planes stored within the current directory
d = dir(pth);
d([1 2]) = [];
d(~[d.isdir]) = [];




stim = [602 1430 3400 8087 19234];
load('D:\fUS_Data\Ali_RawData\rum069\info_Tonotopics_rum069.mat'); % info
% manipulate info -> Plane x event
stim = stim(info(1:2:end,:));
trialOnsetIdx = info(2:2:end,:);
stimDelay    = 10; % sec ??? not specified in file
stimDuration = 3;  % sec ??? not specified in file


clear E

V = fus.Volume; % initialize
for i = 1:length(d)
    % load the acquisition file
    lpth = fullfile(d(i).folder,d(i).name);
    f = dir(fullfile(lpth,'*.acq'));
    ffn = fullfile(f.folder,f.name);
    load(ffn,'-mat') 
    
    Fs = 1./Acquisition.Param.dT_Doppler; % sampling rate
    
    data = squeeze(Acquisition.Data); % squeeze out singleton dimension in data
    data = permute(data,[2 1 3]); % transpose each frame
    
    clear Acquisition % discard original data
    
    V.add_plane(data,dims,Fs);
    

    stimOnsetTime = (trialOnsetIdx(i,:)-1)./Fs+stimDelay;
    V.Plane(i).Event = fus.Event('Freq',stimOnsetTime,stim(i,:),stimDuration,Fs,'Hz');
end

[~,n] = fileparts(pth);
V.Name = n;

disp(V)
fprintf('Plane dimOrder: %s\nPlane dimSizes: %s\n', ...
    strjoin(V.Plane(1).dimOrder,' x '), ...
    mat2str(V.Plane(1).dimSizes))

%% Rearrange raw data Volume by the "Freq" Event
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
N = [3 3 3];
V.smooth(N);

%% Create data mask. Uncomment one method
thresholdGuess = 2;
for i = 1:V.nPlanes
    % Method 1: Manually draw masks on each Plane
    % V.Plane(i).Mask.create_roi;       

    % Method 2: Threshold based on pixel luminance; Click the histogram to
    % adjust the threshold. Hit any key to move on to the next plane.
    V.Plane(i).Mask.create_threshold(thresholdGuess); 
    pause
end


% TODO: Show montage w/ masks


%% Apply Baseline correction to all planes in the volume
% process_planes is a convenient function for running the same function on
% all planes.
baselineWindow = [0 8]; % seconds
V.process_planes(@baseline_correct,baselineWindow);


%% Use the Log associated with each plane to see how the Plane Data has been manipulated so far
planeId = 6;
V.Plane(planeId).print_log




