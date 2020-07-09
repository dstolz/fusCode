classdef Volume < handle & matlab.mixin.Copyable
    
    
    properties        
        UserData
    end
    
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
        
        function obj = Volume(data,dataDims)
            if nargin == 0, return; end
            
            if isempty(data), return; end
            
            obj.add_plane(data,dataDims);
        end
        
        function add_plane(obj,data,dataDims)
          
            if ischar(data) || isstring(data)
                load(data,'-mat'); % may contain dims
            end
            
%             assert(ndims(data) == length(dims), 'fus:Volume:DimMismatch', ...
%                 'ndims(data) ~= length(dims)');
            
            if nargin < 2, dataDims = []; end
            
            
            pidx = find(strcmpi('Planes',dataDims) | strcmpi('Plane',dataDims),1);
            if isempty(pidx) % just one plane
                obj.Plane(end+1) = fus.Plane(data,dataDims,obj.nPlanes+1);
            else % multiple planes
                idx = cell(1,length(dataDims));
                dataDims(pidx) = [];
                for i = 1:size(data,pidx)
                    idx(:) = {':'};
                    idx{pidx} = i;
                    obj.Plane(end+1) = fus.Plane(data(idx{:}),dataDims,obj.nPlanes+1);
                end
            end
        end
        
        
        
        function process_planes(obj,func,varargin)
            for i = 1:obj.nPlanes
                func(obj.Plane(i),varargin{:});
            end
        end
        
        function process_planes_parallel(obj,func,varargin)
            x=ver('parallel');
            if isempty(x)
                fprintf(2,'Parallel Computing Toolbox not available!\n')
                return
            end
            
            parfor i = 1:obj.nPlanes
                func(obj.Plane(i),varargin{:}); %#ok<PFBNS>
            end
        end
        
        
        function data = cat(obj,field,dim,ids)
            % data = cat(obj,field,[dim],[ids])
            % Concatenate fields of all, or a subset of Planes
            
            if nargin < 4 || isempty(ids) || all(ids == 0), ids = 1:obj.nPlanes; end
            
            ids = intersect(1:obj.nPlanes,ids);
            
            P = obj.Plane(ids);
            
            data = [];
            for i = 1:length(ids)
                data = cat(dim,data,P(i).(field));
            end
            
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