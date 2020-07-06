function varargout = fush_GridSize(Plane)
    

nrow = round(sqrt(length(Plane)));
ncol = ceil(length(Plane)/nrow);

if nargout == 1
    varargout{1} = [nrow,ncol];
else
    varargout{1} = nrow;
    varargout{2} = ncol;
end