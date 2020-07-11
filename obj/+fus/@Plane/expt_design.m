function y = expt_design(obj,HR,eventTimes,display)
% y = expt_design(Plane,HR,eventTimes,[display])
%
% Generate experiment design for GLM
%
% Inputs:
%   Plane       ... handle to Plane object
%   HR          ... Haemodynamic response waveform (see estimate_hr)
%   eventTimes  ... 1x2 times (seconds) bracketing the onset and offset of
%                   the event.
%   display     ... either logical true|false, or handle to an axis
%                   (default = false)
%
% Output:
%   y   ... experiment design after convolution with HR.
%

% DJS 2020


narginchk(3,4);


if nargin < 4 || isempty(display), display = false; end

tvec = obj.Time;

stimInd = tvec >= eventTimes(1) & tvec <= eventTimes(2);

stimVec = zeros(1,obj.nFrames);
stimVec(stimInd) = 1;

y = conv(stimVec,HR,'full');
y = y';

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