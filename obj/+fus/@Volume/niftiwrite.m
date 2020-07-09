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

v = obj.cat(field,3,ids);

niftiwrite(v,ffn);
ninfo = niftiinfo(ffn);
ninfo.PixelDimensions = obj.Plane(ids(1)).spatialDims;
ninfo.Transform = obj.spatialTform;
niftiwrite(v,ffn,ninfo);
fprintf('Wrote: <a href = "matlab:system(''start %s'')">%s</a>\n',ffn,ffn)






