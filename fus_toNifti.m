function v = fus_toNifti(Plane,ffn,smoothFactor)
% v = fus_toNifti(Plane,ffn,smoothFactor)
% 
% ffn           -  output filename
% smoothFactor  -  number of pixes for within plane 2d convolution with
%                  gaussian kernel (default = 5)

if nargin < 2 || isempty(ffn),          ffn = 'fus_MeanVolume.nii'; end
if nargin < 3 || isempty(smoothFactor), smoothFactor = 5; end

fprintf('Creating nifti: "%s" ...',ffn)

% create nifti mean volume
v = cast([],'like',Plane(1).Data);
gw = gausswin(smoothFactor);
for i = 1:length(Plane)
    I = Plane(i).I;
    X = sqrt(mean(Plane(i).Data.^2,[I.dFrames, I.dTrials, I.dStim]));
    nv = max(abs(X(:)));
    X = conv2(gw,gw',X,'same');
    X = X ./ max(abs(X(:))) .* nv;
    v(:,:,i) = reshape(X,[I.nX I.nY]);
end

niftiwrite(v,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = I.voxelSpacing(1:3);
niftiwrite(v,ffn,ninfo);
fprintf(' done\n')
