%% Add fusCode to Matlab's path
addpath(genpath('c:\src\fusCode'))


%% Add planes to a new Volume object
load('D:\fUS_Data\Boubenec\Data_Bright_AC\Boubenec_Data_Bright_AC.mat')


% dims are in the same order as that of the loaded data
% Dims 'Y' and 'X' must come first
dims = {'Y','X','Stim','Trials','Frames','Planes'};

V = fus.Volume(epoch_bef,dims);

disp(V)

clear epoch_bef % don't need original data anymore


%% View montage of "Structural"
figure
V.montage;


%% Explore averaged trial data for each stimulus for a plane
% This will update as plane data is manipulated if left open
planeID = 1;
V.Plane(planeID).explorer('Circle');



%% Rigid alignment of all planes
V.align_planes;


%% Draw masks on each Plane
for i = 1:V.nPlanes
    V.Plane(i).Mask.create_roi;
end



%% Volumetric spatial smoothing
N = [3 3 3];
V.smooth(N);


%% Apply Baseline correction to all planes in the volume
% process_planes is a convenient function for running the same function on
% all planes.
baselineWindow = [0 8]; % seconds
V.process_planes(@baseline_correct,baselineWindow);


%% Use the Log associated with each plane to see how the Plane Data has been manipulated so far
V.Plane(1).print_log




