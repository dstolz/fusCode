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
        nFrames
        Time
    end
    
    methods
        align_planes(obj,display)
        smooth(obj,gwN,gwSD)
        varargout = grid_size(obj)
        
        
        function obj = Volume(data,dataDims)
            % obj = Volume
            % obj = Volume(data,dataDims)
            
            if nargin == 0, return; end
            
            if isempty(data), return; end
           
            narginchk(2,2);
            
            obj.add_plane(data,dataDims);
        end
        
        function add_plane(obj,data,dataDims,Fs)
            % add_plane(obj,data,dataDims,[Fs])
            % add_plane(obj,fullFileName,[dataDims],[Fs])
            
            if ischar(data) || isstring(data)
                load(data,'-mat'); % may contain dataDims
            end
            
%             assert(ndims(data) == length(dims), 'fus:Volume:DimMismatch', ...
%                 'ndims(data) ~= length(dims)');
            
            if nargin < 3, dataDims = []; end
            if nargin < 4, Fs = 1; end
            
            
            pidx = find(strcmpi('Planes',dataDims) | strcmpi('Plane',dataDims),1);
            if isempty(pidx) % just one plane
                obj.Plane(end+1) = fus.Plane(data,dataDims,obj.nPlanes+1,Fs);
            else % multiple planes
                idx = cell(1,length(dataDims));
                dataDims(pidx) = [];
                for i = 1:size(data,pidx)
                    idx(:) = {':'};
                    idx{pidx} = i;
                    obj.Plane(end+1) = fus.Plane(data(idx{:}),dataDims,obj.nPlanes+1,Fs);
                end
            end
        end
        
        
        
        function process_planes(obj,func,varargin)
            for i = 1:obj.nPlanes
                func(obj.Plane(i),varargin{:});
            end
        end
        
        function process_planes_parallel(obj,func,varargin)
            obj.check_parallel;
            parfor i = 1:obj.nPlanes
                func(obj.Plane(i),varargin{:}); %#ok<PFBNS>
            end
        end
        
        
        function data = cat(obj,field,dim,ids)
            % data = cat(obj,field,[dim],[ids])
            % Concatenate fields of all, or a subset of Planes
            
            if nargin < 3, dim = []; end
            if nargin < 4 || isempty(ids) || all(ids == 0), ids = 1:obj.nPlanes; end
            
            
            ids = intersect(1:obj.nPlanes,ids);
            
            P = obj.Plane(ids);
            
            if isempty(dim)
                dim = P(1).nDims+1;
            end
            
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
        
        
        function t = get.Time(obj)
            t = obj.Plane(1).Time;
        end
        
        function n = get.nFrames(obj)
            n = obj.Plane(1).nFrames;
        end
        
    end % methods (Public) % set/get
    
    
    
    
    
    
    
    methods (Static)
        function tf = check_parallel
            x=ver('parallel');
            tf = isempty(x);
            if ~tf
                fprintf(2,'Parallel Computing Toolbox not available!\n')
            end
        end
        
    end % methods (Static)
    
    
    
    
    
    
    
    
    
    
    
end