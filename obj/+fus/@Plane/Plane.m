classdef Plane < handle & matlab.mixin.SetGet
    
    properties
        id       (1,1) uint8 = 1;
        Name     (1,1) string = "Plane_1";        
        
    end
    
    properties (SetObservable)
       
        
        Mask        (1,1) fus.Mask
        
                
        Structural  (:,:) {mustBeNumeric}
        
        bgPlane     (1,1) % fus.Plane
        fgPlane     (1,1) % fus.Plane
            
    end
    
    properties (SetObservable,AbortSet)
        Fs          (1,1) {mustBePositive,mustBeFinite,mustBeNonempty} = 1; %Hz
        applyMask   (1,1) logical = true
        
        dispTransparency double {mustBeNonnegative,mustBeLessThanOrEqual(dispTransparency,1)} = 0; % alpha = 1-dispTransparency
        
        colormap            (:,3) = parula;
        spatialDims         (1,3) {mustBePositive,mustBeFinite,mustBeNonempty} = [.1 .1 .3];
        spatialCoords       (1,3) {mustBeFinite,mustBeNonempty} = [0 0 0];
        spatialUnits        (1,1) string = "mm";
        spatialTform        (1,1) affine2d = affine2d;
        useSpatialTform     (1,1) logical = true;
    end
    
    properties (Dependent)
        dim
        num
        
        dimSizes
        dimOrder
        
        Time
    end
    
    properties (Dependent, Hidden)
        dataDimsStr
    end
    
    
    properties (SetAccess = protected,SetObservable)
        Data
        dataDims
        
        Log
        
        nYX         (1,2)
        
        TimeDim     (1,1) string = "Frames"
    end
    
    properties (SetAccess = private)
        previousShape
    end
    
    
    methods
        explorer(obj,roiType,logScale)
        explorer_update(obj,roi,event,imAx)

        function obj = Plane(data,dataDims,id)
            if nargin < 1, data = [];     end
            if nargin < 2, dataDims = ""; end
            if nargin < 3, id = 1;        end
           
            postsets = {'Fs','spatialTform','useSpatialTform','spatialCoords','spatialDims'};
            cellfun(@(a) addlistener(obj,a,'PostSet',@obj.update_log),postsets);
            
            obj.update_log('Plane created');

            obj.set_Data(data,dataDims);
            
            obj.create_Structural;

            obj.id = id;
        end
        
        function set_Data(obj,data,dataDims)
            if isempty(data), return; end
            
            assert(ndims(data) > 2, ...
                'fus:Plane:set_Data:InvalidDims', ...
                'ndims(data) must be >= 2') %#ok<ISMAT>
            
            assert(ndims(data) == numel(dataDims), ...
                'fus:Plane:set_Data:DimMismatch', ...
                'ndims(data) ~= numel(dataDims)')
            
            
            
            if isempty(dataDims)
                dataDims = {'Y' 'X'};
                for i = 3:ndims(data)
                    dataDims{i} = sprintf('Dim_%d',i);
                end
            end
                
            obj.Data     = data; clear data
            
            obj.dataDims = dataDims;
            
            obj.nYX = [size(obj.Data,1) size(obj.Data,2)];
            
            
            obj.update_log('Data updated %s; dims: %s',mat2str(obj.dimSizes),obj.dataDimsStr);
        end
        
        function create_Structural(obj)
            obj.Structural = log10(mean(obj.Data,3:length(obj.dimSizes),'omitnan'));
        end
        
        
        function d = find_dim(obj,dimStr)
            dimStr = lower(string(dimStr));
            dimOrd = lower(string(obj.dataDims));
            d = zeros(size(dimStr));
            for i = 1:numel(dimStr)
                d(i) = find(ismember(dimOrd,dimStr(i)));
            end
        end
        
        
        function newNum = reshape_data(obj,newShape)
            try
                oldShape = obj.dataDims;
                newShape = cellstr(newShape);
                newNum = ones(size(newShape));
                n = obj.num;
                for i = 1:length(newShape)
                    c = textscan(newShape{i},'%s','delimiter','*');
                    c = c{1};
                    for j = 1:length(c)
                        newNum(i) = newNum(i)*n.(c{j});
                    end
                end
                obj.Data = reshape(obj.Data,newNum);
                obj.dataDims      = newShape;
                obj.previousShape = oldShape;
                obj.update_log('Reshaped data dims -> %s %s',obj.dataDimsStr,mat2str(obj.dimSizes));
            catch me
                obj.update_log(me);
                fprintf(2,'---> Current data shape: %s <---\n\n',obj.dataDimsStr)
                rethrow(me)
            end
            
            if nargout == 0, clear newNum; end
        end
        
        function permute_data(obj,newDimOrder)
            try
                if isnumeric(newDimOrder)
                    newDimIdx = newDimOrder;
                else
                    newDimIdx = obj.find_dim(newDimOrder); 
                end
                obj.Data = permute(obj.Data,newDimIdx);
                
                obj.dataDims = newDimOrder;
                obj.update_log('Permuted data dims -> %s',obj.dataDimsStr);
            catch me
                obj.update_log(me);
                rethrow(me)
            end
        end
        
        
        function update_log(obj,msg,varargin)
            if isempty(obj.Log)
                obj.Log = struct('time',[],'message','','stack',[]);
                idx = 1;
            else
                idx = length(obj.Log)+1;
            end
            
            obj.Log(idx,1).time    = now;
            obj.Log(idx,1).stack   = dbstack(1);
            
            switch class(msg)
                case 'meta.property' % Observed property
                    if islogical(obj.(msg.Name)) || isnumeric(obj.(msg.Name))
                        n = min(length(obj.(msg.Name)),5);
                        vstr = mat2str(obj.(msg.Name)(1:n),'class');
                        if n < length(obj.(msg.Name)), vstr = [vstr ' ...']; end
                        obj.Log(idx).message = sprintf('Updated property "%s" to %s',msg.Name,vstr);
                    else
                        obj.Log(idx).message = sprintf('Updated property "%s" value(s)',msg.Name);
                    end
                case 'MException'
                    obj.Log(idx).message = msg;
                otherwise
                    obj.Log(idx).message = sprintf(msg,varargin{:});
            end
            
        end
        
    end % methods (Public); functions
        
        
        
        
        
        
        
    methods % set/get
        
        
        function n = get.dimSizes(obj)
            n = size(obj.Data);
        end

        function n = get.num(obj)
            x = obj.dimSizes;
            d = matlab.lang.makeValidName(obj.dataDims);
            for i = 1:length(x)
                n.(d{i}) = x(i);
            end
        end

        function d = get.dimOrder(obj)
            d = matlab.lang.makeValidName(obj.dataDims);
        end
        
        function d = get.dim(obj)
            x = obj.dimOrder;
            for i = 1:length(x)
                d.(x{i}) = i;
            end
        end
        
        
        function s = get.dataDimsStr(obj)
            s = '';
            for i = 1:length(obj.dataDims)
                s = sprintf('%s,%s',s,obj.dataDims{i});
            end
            s(1) = [];
        end
        
       
        function t = get.Time(obj)
            t = 0:obj.num.(obj.TimeDim)-1;
            t = t ./ obj.Fs;
        end
        
        function d = get.Structural(obj)
            if obj.useSpatialTform
                d = imwarp(obj.Structural,obj.spatialTform,'FillValues',nan);
                d = center_crop(d,obj.nYX);
            else
                d = obj.Structural;
            end
        end
        
        function d = get.Data(obj)
            if obj.useSpatialTform
                d = imwarp(obj.Data,obj.spatialTform,'FillValues',nan);
                d = center_crop(d,obj.nYX);
            else
                d = obj.Data;
            end
        end
        
        
        
        
        
        
        
%         function set.spatialTform(obj,tform)
%             obj.spatialTform = tform;
%             obj.update_log('
%         end
        
        
        
%         function set.useSpatialTform(obj,tf)
%             obj.useSpatialTform = tf;
%             obj.update_log('Set useSpatialTform = %g',tf)
%         end
    end % methods (Public); set/get
    
    
    
    
    
    
    
    
    
end