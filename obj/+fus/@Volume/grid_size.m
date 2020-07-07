function [nrow, ncol] = grid_size(obj)
    
nrow = round(sqrt(length(obj.active)));
ncol = ceil(length(obj.active)/nrow);
