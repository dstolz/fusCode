function Plane = fus_smoothVolume(Plane,smoothFactor)
% NEEDS TESTING!!!!!!!!


% Plane = fus_smoothVolume(Plane,smoothFactor)
%
% smoothFactor  -  number of pixes for within plane 3D convolution with
%                  gaussian kernel (default = [5 5 2])


if nargin < 2 || isempty(smoothFactor), smoothFactor = [5 5 2]; end


sz = round(smoothFactor/2);
for i = 1:length(sz)
    idx{i} = -sz(i):sz(i);
end
[X1,X2,X3] = meshgrid(idx{1},idx{2},idx{3});
gw = mvnpdf([X1(:) X2(:) X3(:)],[0 0 0],eye(3));
gw = reshape(gw,[length(gw)/3 3]);


if isnumeric(Plane) % treat as a matrix
    if ndims(Plane) == 3
        nv = max(abs(Plane));
        Plane = convn(Plane,gw,'same');
        Plane = Plane ./ max(abs(Plane(:))) .* nv;
    elseif ndims(Plane) == 4
        Plane = dothesmooth(Plane,gw);
    end
else
    I = Plane(1).I;
    for j = 1:I.nStim*I.nTrials*I.nFrames
        X = [];
        for i = 1:length(Plane)
            I = Plane(i).I;
            X(:,:,i,:) = reshape(Plane(i).Data,I.shapeYXA);           
        end
        
        X = dothesmooth(X,gw);
        
        for i = 1:length(Plane)
            Plane(i).Data = reshape(X(:,:,i,:),I.shapePSTF);
        end
    end
    
    for i = 1:length(Plane)
        Plane(i).Manifest{end+1} = sprintf('Volumetrically smoothed; smoothFactor = %d',smoothFactor);
    end
end

end


function X = dothesmooth(X,gw)

for i = 1:size(X,4)
    y = X(:,:,:,i);
    nv = max(abs(y(:)));
    y = convn(y,gw,'same');
    X(:,:,:,i) = y ./ max(abs(y(:))) .* nv;
end

end