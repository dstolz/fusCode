function y = expt_design(obj,HR,stimTimings,display)
% y = expt_design(Plane,HR,stimTimings,[display])
%
% Generate experiment design for GLM
%
% Inputs:
%   Plane       ... handle to Plane object
%   HR          ... Haemodynamic response waveform (see estimate_hr)
%   stimTimings ... 1x2 times (seconds) bracketing the onset and offset of
%                   the stimulus.
%   display     ... either logical true|false, or handle to an axis
%                   (default = false)
%
% Output:
%   y   ... experiment design after convolution with HR.
%

% DJS 2020

% TODO: allow for Nx2 timings and some sort of labeling scheme

narginchk(3,4);


if nargin < 4 || isempty(display), display = false; end

tvec = obj.Time;
% for i = 1:size(stimTimings,1)
    stimInd = tvec >= stimTimings(1) & tvec <= stimTimings(2);
    
    stimVec = zeros(1,obj.nFrames);
    stimVec(stimInd) = 1;
    
    y = conv(stimVec,HR,'full');
% end

isAx = isa(display,'matlab.graphics.axis.Axes');
if isAx || display    
    if isAx
        ax = display;
    else
        f = figure;
        ax = axes(f);
    end
    stairs(ax,tvec,stimVec,'linewidth',2,'DisplayName','Design');
    hold(ax,'on');
    t = obj.Time(1):1/obj.Fs:length(y)/obj.Fs-1/obj.Fs;
    plot(t,y,'linewidth',2,'DisplayName','Conv Design');
    hold(ax,'off');
    grid(ax,'on');
    ax.XAxis.Label.String = 'time (s)';
    ax.XAxis.Limits = t([1 end]);
    legend(ax);
end