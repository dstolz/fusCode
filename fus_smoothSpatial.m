function Plane = fus_smoothSpatial(Plane,smoothFactor)
% Plane = fus_smoothSpatial(Plane,smoothFactor)
%
% smoothFactor  -  number of pixes for within plane 2d convolution with
%                  gaussian kernel (default = 5)


if nargin < 2 || isempty(smoothFactor), smoothFactor = 5; end

gw = gausswin(smoothFactor);

if isnumeric(Plane) % treat as a matrix
    for i = 1:size(Plane,3)
        Plane(:,:,i) = dothesmooth(Plane(:,:,i),gw);
    end
else
    for i = 1:length(Plane)
        I = Plane(i).I;
        
        X = reshape(Plane(i).Data,I.shapeXYA);
        
        X = dothesmooth(X,gw);
        
        Plane(i).Data = reshape(X,I.shapePSTF);
        Plane(i).Manifest{end+1} = sprintf('In-plane smoothed; smoothFactor = %d',smoothFactor);
    end
end

end


function X = dothesmooth(X,gw)

for j = 1:size(X,3)
    y = X(:,:,j);
    nv = max(abs(y(:)));
    y = conv2(gw,gw',y,'same');
    X(:,:,j) = y ./ max(abs(y(:))) .* nv;
end
end