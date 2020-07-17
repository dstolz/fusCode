classdef Plane < handle & matlab.mixin.SetGet & matlab.mixin.Copyable & dynamicprops
    
    properties
        id       (1,1) uint16 = 1;
        
        UserData
    end
    
    properties (SetObservable)
        Mask        (1,1) %fus.Mask
        
        Event       (:,1) fus.Event
        
        Structural  (:,:) {mustBeNumeric}
        
        bgPlane     (1,1) % fus.Plane
        fgPlane     (1,1) % fus.Plane
        
        useSpatialTform     (1,1) logical = true;
    end
    
    properties (SetObservable,AbortSet)
        Fs          (1,1) {mustBePositive,mustBeFinite,mustBeNonempty} = 1; %Hz
        
        dispTransparency double {mustBeNonnegative,mustBeLessThanOrEqual(dispTransparency,1)} = 0; % alpha = 1-dispTransparency
        
        colormap           (:,3) = parula;
        spatialDims        (1,3) {mustBePositive,mustBeFinite,mustBeNonempty} = [.1 .1 .3];
        spatialCoords      (1,3) {mustBeFinite,mustBeNonempty} = [0 0 0];
        spatialUnits       (1,1) string = "mm";
        spatialTform       (1,1) affine2d = affine2d;
        
        useMask            (1,1) logical = true;
        
        
        timeDimName     (1,1) string = "Time";
        eventDimName    (1,1) string = "Events";
        repDimName      (1,1) string = "Reps";
    end
    
    properties (Dependent)
        dim
        num
        
        dimSizes
        dimOrder
        
        nDims
        
        Time
        
        nFrames
        
        Name
        FullName
        
        timeDim
        eventDim
        repsDim
    end
    
    properties (Dependent, Hidden)
        dataDimsStr
    end
    
    
    properties (SetAccess = protected, SetObservable)
        Data
        dataDims
        
        Log
        
        nYX         (1,2)
    end
    
    properties (SetAccess = private)
        transformState  = 0; % 0: none applied; 1: applied; -1: applied inverted
    end
    
    properties (SetAccess = private, Hidden)
        initialized     = false;
    end
    
    
    properties (SetAccess = immutable)
        Parent
    end
    
    methods (Access = ?fus.Volume)         
        function obj = Plane(V,data,dataDims,id,Fs)
            obj.Parent = V;
            if nargin < 2, data = [];     end
            if nargin < 3, dataDims = ""; end
            if nargin < 4, id = 1;        end
            if nargin < 5, Fs = 1;        end
            
            postsets = {'Fs','spatialTform','useSpatialTform','spatialCoords','spatialDims','useMask'};
            cellfun(@(a) addlistener(obj,a,'PostSet',@obj.update_log),postsets);
            
            obj.update_log('Plane created');
            
            obj.set_Data(data,dataDims);
            
            obj.create_Structural;
            
            obj.id = id;
            obj.Fs = Fs;
        end
    end
    
    methods
        explorer(obj,roiType,logScale)
        explorer_update(obj,roi,event,imAx)
        y = expt_design(obj,HR,stimOnOff,display)
        h = image(obj,varargin)
         
        
        function set_Data(obj,data,dataDims)
            % set_Data(obj,data,[dataDims])
            
            if isempty(data), return; end
            
            if nargin < 3 || isempty(dataDims)
                assert(~isempty(obj.dataDims),'fus:Plane:set_Data:MissingDataDims', ...
                    'dataDims must be specified')
                dataDims = obj.dataDims;
            end
            
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
            
            obj.nYX = [size(data,1) size(data,2)];
            
            obj.Data = data; clear data
            
            obj.dataDims = dataDims;
            
            obj.update_log('Data updated %s; dims: %s',mat2str(obj.dimSizes),obj.dataDimsStr);
            
            if ~obj.initialized
                obj.Mask = fus.Mask(obj);
                obj.update_log('ROI mask initialized');
            end
                        
            
            obj.initialized = true;
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
        
        
        function data = reshape_data(obj,newShape)
            % data = reshape_data(obj,newShape)            
            
            try
                rind = cellfun(@isempty,newShape); % '' == remaining dims
                assert(nnz(rind)<=1,'fus:Plane:reshape_data:InvalidShape', ...
                    '[] can only be used zero or one times');
                
                newShape(rind) = {''};
                
                newShape = cellstr(newShape);

                
                newNum = repmat({1},size(newShape));
                n = obj.num;
                for i = 1:length(newShape)
                    if isempty(newShape{i})
                        newNum{i} = [];
                    else
                        c = textscan(newShape{i},'%s','delimiter','*');
                        c = c{1};
                        for j = 1:length(c)
                            newNum{i} = newNum{i}*n.(c{j});
                        end
                    end
                end
                data = reshape(obj.Data,newNum{:});
                % obj.dataDims      = newShape;
                % obj.previousShape = oldShape;
                % obj.update_log('Reshaped data dims -> %s %s',obj.dataDimsStr,mat2str(obj.dimSizes));
                
                
            catch me
                obj.update_log(me);
                fprintf(2,'---> Current data shape: %s <---\n\n',obj.dataDimsStr)
                rethrow(me)
            end
            
            if nargout == 0, clear newNum; end
        end
        
        function permute_data(obj,newDimOrder)
            % permute_data(obj,newDimOrder)
            
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
        
        function ipermute_data(obj)
            % ipermute_data(obj)
            %
            % Restore original dim order
            
            try
                obj.Data = ipermute(obj.Data,obj.dimOrder);
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
        
        
        
        
        function print_log(obj,nRecent)
            if nargin < 2 || isempty(nRecent), nRecent = 0; end
            fprintf('\n%s - Log\n',obj.Name)
            
            if nRecent <= 0 || isinf(nRecent), nRecent = length(obj.Log); end
            n = length(obj.Log)-nRecent+1;
            for i = n:length(obj.Log)
                fprintf(' %02d. %s: %s\n',i,datestr(obj.Log(i).time,21),obj.Log(i).message)
            end
        end
        
        
        
        function ev = get_event(obj,name)
            ev = [];
            ind = string(name) == [obj.Event.Name];
            if any(ind)
                ev = obj.Event(ind);
            end
        end
        
    end % methods (Public); functions
    
    
    
    
    
    
    methods % set/get
        
        
        function data = get.Data(obj)
            data = obj.Data;
            if obj.useMask && obj.initialized
                n = size(data);
                data(repmat(~obj.Mask.mask,[1 1 n(3:end)])) = nan;
            end
        end
        
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
        
        function n = get.nDims(obj)
            n = length(obj.dimOrder);
        end
        
        function s = get.dataDimsStr(obj)
            s = '';
            for i = 1:length(obj.dataDims)
                s = sprintf('%s,%s',s,obj.dataDims{i});
            end
            s(1) = [];
        end
        
        function t = get.Time(obj)
            t = 0:obj.num.(obj.timeDimName)-1;
            t = t ./ obj.Fs;
        end
        
        function n = get.nFrames(obj)
            n = obj.num.(obj.timeDimName);
        end
        
        function n = get.Name(obj)
             n = compose("Plane %d",obj.id);
        end
        
        function n = get.FullName(obj)
             n = compose("%s - Plane %d",obj.Parent.Name,obj.id);
        end
        
        function set.useSpatialTform(obj,tf)
            inv = ~tf;
            apply_spatial_tform(obj,inv);
        end
        
        function d = get.timeDim(obj)
            d = obj.find_dim(obj.timeDimName);
        end
        
        function d = get.eventDim(obj)
            d = obj.find_dim(obj.eventDimName);
        end
        
        function d = get.repsDim(obj)
            d = obj.find_dim(obj.repsDimName);
        end
        
    end % methods (Public); set/get
    
    
    
    
    
    methods (Access = protected)
        function apply_spatial_tform(obj,inv)
            if inv
                if obj.transformState == 0, return; end % don't do anything
                tform = invert(obj.spatialTform);
                obj.transformState = -1;
            else
                tform = obj.spatialTform;
                obj.transformState = 1;
            end
            d = imwarp(obj.Data,tform,'FillValues',nan);
            obj.Data = center_crop(d,obj.nYX);
            
            d = imwarp(obj.Structural,tform,'FillValues',nan);
            obj.Structural = center_crop(d,obj.nYX);
            
            d = imwarp(obj.Mask.mask,tform,'FillValues',0);
            obj.Mask.mask = center_crop(d,obj.nYX);
        end
    end % methods (Access = protected)
    
end