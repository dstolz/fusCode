classdef Volume < handle
    
    properties (SetObservable = true)
        Plane   (:,1) fus.Plane
        
        Name    (1,1) string = "Unnamed Volume"
        
        realworldCoords     (1,3) = [0 0 0];
        spatialTform        (1,1) = affine3d;
        spatialUnits        (1,1) string = "mm";
        useSpatialTform     (1,1) logical = true;
        
        active    (:,1) {mustBeNumeric,mustBeNonnegative,mustBeFinite} = 0;
    end
    
    properties (Dependent)
        nPlanes
    end
    
    methods
        align_planes(obj,display)
        varargout = grid_size(obj)
        
        function obj = Volume(ffn)
            if nargin == 0, return; end
            
            if isempty(ffn), return; end
            
            
        end
    end % methods (Public)
    
    
    methods % set/get
        function n = get.nPlanes(obj)
            n = length(obj.Plane);
        end
        
        function set.active(obj,id)
            mustBeLessThanOrEqual(id,obj.nPlanes)
            obj.active = id;
        end
        
        function id = get.active(obj)
            if obj.active == 0
                id = 1:obj.nPlanes; 
            else
                id= obj.active;
            end
            
        end
    end % methods (Public) % set/get
end