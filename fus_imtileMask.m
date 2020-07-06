function maskTile = fus_imtileMask(Plane,GridSize)

if nargin < 2, GridSize = fush_GridSize(Plane); end

if length(GridSize) == 1, GridSize = [GridSize nan]; end

maskTile = [];
for i = 1:length(Plane)
    I = Plane(i).I;
    maskTile = cat(3,maskTile,~I.roiMaskInd);
end

maskTile = imtile(maskTile,'GridSize',GridSize);
maskTile = 1-maskTile; % invert