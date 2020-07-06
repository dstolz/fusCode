function Plane = fus_smooth(Plane,gwN,gwSD)
% Plane = fus_smoothSpatial(Plane,[gwN],[gwSD])
% Data = fus_smoothSpatial(Data,[gwN],[gwSD])
%
% Plane ... Plane structure or array of Plane structures.  Smooths all
%           Plane.Data (shapeYXA).  Appends a note to the Plane manifest.
%
% Data  ..  Smooth 3D Data
%
% gwN   ... number of pixels for smoothing with gaussian kernel
%           (default = [3 3 1])
% gwSD  ... standard deviation of gaussian kernel (default = .5)

% DJS 2020

if nargin < 2 || isempty(gwN),  gwN = 3;    end
if nargin < 3 || isempty(gwSD), gwSD = 0.5; end

switch length(gwN) 
    case 1
        gwN = [gwN gwN 1];
    case 2
        gwN = [gwN 1];        
end


if isnumeric(Plane) % treat as a matrix
    Plane = smooth3(Plane,'gaussian',gwN,gwSD);
else
    for i = 1:length(Plane)
        I = Plane(i).I;
        
        X = reshape(Plane(i).Data,I.shapeYXA);
        
        X = smooth3(X,'gaussian',gwN,gwSD);
        
        Plane(i).Data = reshape(X,I.shapePSTF);
        Plane(i).Manifest{end+1} = sprintf('In-plane smoothed; gwN = [%d %d %d]',gwN);
    end
end

