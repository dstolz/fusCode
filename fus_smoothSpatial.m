function Plane = fus_smoothSpatial(Plane,gwN,gwSD)
% Plane = fus_smoothSpatial(Plane,smoothFactor)
%
% gwN  -  number of pixes for within plane 2d convolution with gaussian
%           kernel (default = 3)


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
        Plane(i).Manifest{end+1} = sprintf('In-plane smoothed; smoothFactor = %d',smoothFactor);
    end
end

end