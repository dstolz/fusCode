function niftiwrite(obj,ffn,field,ids)
% niftiwrite(obj,[ffn],[field],[ids])

if nargin < 2, ffn = []; end
if nargin < 3 || isempty(field), field = 'Structural'; end
if nargin < 4, ids = []; end

if isempty(ffn)
    [fn,pn] = uiputfile({'*.nii','NIfTI volume'},'niftiwrite');
    if isequal(fn,0), return; end
    ffn = fullfile(pn,fn);
end

if isempty(ids), ids = 1:obj.nPlanes; end

dim = ndims(obj.Plane(ids(1)).(field)) + 1;
v = obj.cat(field,dim,ids);

if dim >= 3
    spc = obj.Plane(ids(1)).spatialDims;
end

if dim >= 4
    v = permute(v,[1 2 4 3]);
    spc = [spc 1/obj.Plane(ids(1)).Fs];
end
    
if dim >= 5
    spc = [spc ones(1,dim-4)];
end

niftiwrite(v,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = spc;
ninfo.Transform = obj.spatialTform;
niftiwrite(v,ffn,ninfo);
fprintf('Wrote: <a href = "matlab:system(''start %s'')">%s</a>\n',ffn,ffn)






