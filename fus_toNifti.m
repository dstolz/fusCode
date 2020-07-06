function v = fus_toNifti(Plane,ffn)
% v = fus_toNifti(Plane,ffn)
% 
% ffn           -  output filename

if nargin < 2 || isempty(ffn), ffn = 'fus_MeanVolume.nii'; end

fprintf('Creating nifti: "%s" ...',ffn)

% create nifti mean volume
I = Plane(1).I;
v = ones([I.nY I.nX I.nPlanes],'like',Plane(1).Data)*-9999;
for i = 1:length(Plane)
    I = Plane(i).I;
    X = mean(Plane(i).Data,[I.dStim I.dTrials I.dFrames]);
    v(:,:,i) = reshape(X,[I.nY I.nX]);
end
v = log10(v);
niftiwrite(v,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = I.voxelSpacing(1:3);
niftiwrite(v,ffn,ninfo);
fprintf(' done\n')
