%% Add fusCode to Matlab's path
addpath(genpath('c:\src\fusCode'))


%% Add planes to a new Volume object
load('D:\fUS_Data\Boubenec\Data_Bright_AC\Boubenec_Data_Bright_AC.mat')


% dims are in the same order as that of the loaded data
% Dims 'Y' and 'X' must come first
dims = {'Y','X','Stim','Trials','Frames','Planes'};

V = fus.Volume(epoch_bef,dims);

disp(V)

clear epoch_bef



%% Rigid alignment of all planes
V.align_planes;

%% Apply Baseline correction to all planes in the volume
% process_planes is a convenient function for running the same function on
% all planes.

tic
baselineWindow = [0 8]; % seconds
V.process_planes(@baseline_correct,baselineWindow);
toc

%%

V.Plane(5).explorer;