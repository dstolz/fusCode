function v = fus_toNifti(Plane,ffn)
% v = fus_toNifti(Plane,ffn)
% 
% ffn           -  output filename

if nargin < 2 || isempty(ffn),          ffn = 'fus_MeanVolume.nii'; end

fprintf('Creating nifti: "%s" ...',ffn)

% create nifti mean volume
v = cast([],'like',Plane(1).Data);
for i = 1:length(Plane)
    I = Plane(i).I;
    v(:,:,i) = reshape(X,[I.nY I.nX]);
end

niftiwrite(v,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = I.voxelSpacing(1:3);
niftiwrite(v,ffn,ninfo);
fprintf(' done\n')
