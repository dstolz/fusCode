classdef Mask < handle

    properties
        roi
        
        planeSize
    end
    
    properties (SetObservable)
        ind     (:,:) logical
    end
    
    
    properties (Dependent)
        idx
        
        coords
        nMaskPixels
    end
    
    
    methods
        function obj = Mask(mask)
            if nargin < 1, mask = []; end
            
            if startsWith(class(mask),'images.roi.')
                obj.roi = mask;
            else
                obj.ind = mask;
            end
        end
        
        function set_mask(obj,mask)
            if issparse(mask) % update underlying representation
                
            elseif ndims == 1 % assume row-col index
               
            elseif ndims == 2
                if size(mask,2) == 2 % assume coordinates [x y]
                
                end
            end % otherwise assume full-frame logical mask
            
            mask = logical(mask);
            
        end
        
    end % methods (Public)


end