classdef Plane < handle & matlab.mixin.SetGet & matlab.mixin.Copyable & dynamicprops
    
    properties
        id       (1,1) uint16 = 1;
        
        UserData
    end
    
    properties (SetObservable)
        Name        (1,:) char
        Mask        (1,1) %fus.Mask
        
        Event       (:,1) fus.Event
        
        Structural  (:,:) {mustBeNumeric}
        
        bgPlane     (1,1) % fus.Plane
        fgPlane     (1,1) % fus.Plane
        
        useSpatialTform     (1,1) logical = true;
        
        role        (1,:) char = 'plane';
        
        dataThreshold  (1,1) double = 1;
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
        repsDimName     (1,1) string = "Reps";
    end
    
    properties (Dependent)
        dim
        num
        
        dimSizes
        dimOrder
        
        nDims
        
        Time
        
        nFrames
        
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
        initialized = false;
    end
    
    
    properties (SetAccess = immutable)
        Parent
    end
    
%     methods (Access = ?fus.Volume)         
%         
%     end
    
    methods
        explorer(obj,roiType,logScale)
        remove_outliers(obj,zthr,interpMethod)
        y = expt_design(obj,HR,stimOnOff,display)
        h = image(obj,varargin)
        h = overlay(obj,axBg,thr,varargin)
        M = reconstruct(obj,data,fillValue)
        
        function obj = Plane(parent,data,dataDims,id,Fs)
                        
            if nargin < 2, data = [];     end
            if nargin < 3, dataDims = {'Y' 'X'}; end
            if nargin < 4, id = 1;        end
            if nargin < 5, Fs = 1;        end
            
            if ~isempty(parent)
                obj.Parent = parent;
            end
            
            postsets = {'Fs','spatialTform','useSpatialTform','spatialCoords','spatialDims','useMask'};
            cellfun(@(a) addlistener(obj,a,'PostSet',@obj.update_log),postsets);
            
            obj.update_log('Plane created');
            
            
            obj.id = id;
            obj.Fs = Fs;
            
            obj.set_Data(data,dataDims);
            
        end
        
        
        function set_Data(obj,data,dataDims)
            % set_Data(obj,data,[dataDims])
            
            if isempty(data), return; end
            
            if nargin < 3 || isempty(dataDims)
                assert(~isempty(obj.dataDims),'fus:Plane:set_Data:MissingDataDims', ...
                    'dataDims must be specified')
                dataDims = obj.dataDims;
            end
            
            assert(ndims(data) == numel(dataDims), ...
                'fus:Plane:set_Data:DimMismatch', ...
                'ndims(data) ~= numel(dataDims)')            
            
            if isempty(dataDims)
                dataDims = {'Y' 'X'};
                for i = 3:ndims(data)
                    dataDims{i} = sprintf('Dim_%d',i);
                end
            end
            
            obj.nYX = size(data,[1 2]);
            
            obj.dataDims = dataDims;

            obj.Data = data; clear data            
            
            obj.update_log('Data updated %s; dims: %s',mat2str(obj.dimSizes),obj.dataDimsStr);
            
            if ~obj.initialized
                obj.Mask = fus.Mask(obj);
                obj.update_log('ROI mask initialized');
                
                obj.create_Structural;
                
                if isequal(obj.role,'plane')
                    obj.set_Background(obj.Structural,{'Y' 'X'});
                    obj.set_Foreground(nan(obj.nYX),{'Y' 'X'});
                end
            end
                        
            
            obj.initialized = true;
        end
        
        function set_Background(obj,data,dataDims,name)
            if nargin < 4 || isempty(name), name = ''; end
            obj.bgPlane = fus.Plane(obj);
            obj.bgPlane.role = 'background';
            obj.bgPlane.Name = name;
            obj.bgPlane.set_Data(data,dataDims);
        end
        
        function set_Foreground(obj,data,dataDims,name)
            if nargin < 4 || isempty(name), name = ''; end
            obj.fgPlane = fus.Plane(obj);
            obj.fgPlane.role = 'foreground';
            obj.fgPlane.Name = name;
            obj.fgPlane.set_Data(data,dataDims);
        end
        
        function create_Structural(obj)
            if obj.nDims > 2
                obj.Structural = log10(mean(obj.Data,3:length(obj.dimSizes),'omitnan'));
            else
                obj.Structural = obj.Data;
            end
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
            %
            % Returns data reshaped using the name of dimensions in the
            % data.  Use an asterisk, *, to combine two or more dimensions.
            % See examples below.
            %
            % Note that the Plane's data is not updated. Use the set_Data
            % function to update the Plane's data.
            %
            % ex:
            %   % Return data with all voxels in the first dim,
            %   % additional dimensions in the second dim, and time in the
            %   % third dim.  Note that obj.timeDimName is used here to
            %   % permit different naming schemes by the user.
            %   data = obj.reshape_data({'X*Y','',obj.timeDimName});
            %   
            %
            % ex: 
            %   % Return data with all dims compressed into first dimension
            %   % and time in the second dimension.
            %   data = obj.reshape_data({'',obj.timeDimName});
            
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
        
        function oldDimOrder = permute_data(obj,newDimOrder)
            % permute_data(obj,newDimOrder)
            %
            % Applies dimensional permutation to the data.
            % 
            % Input:
            %   obj         ... Plane object.
            %   newDimOrder ... [1xnDims] new dim order. Can be specified
            %                   as either a numeric vector or a cell/string
            %                   array of dim names in the new order.
            %
            % Output:
            %   oldDimOrder ... data dim order from before permutation
            
            try
                oldDimOrder = obj.dataDims;
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
                if isa(obj.Log(i).message,'MException')
                    msg = [obj.Log(i).message.identifier '; ' obj.Log(i).message.message];
                    fprintf(2,' %02d. %s: %s\n',i,datestr(obj.Log(i).time,21),msg)
                else
                    msg = obj.Log(i).message;
                    fprintf(' %02d. %s: %s\n',i,datestr(obj.Log(i).time,21),msg)
                end
            end
        end
        
        
        
        function ev = get_event(obj,name)
            ev = [];
            ind = string(name) == [obj.Event.Name];
            if any(ind)
                ev = obj.Event(ind);
            end
        end
        
        
        function detrend(obj,varargin)
            origDims = obj.dimSizes;
            d = obj.reshape_data({'',obj.timeDimName});
            for i = 1:size(d,1)
                d(i,:) = detrend(d(i,:),varargin{:});
            end
            obj.set_Data(reshape(d,origDims));
            obj.update_log('Trials detrended');
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
            if isempty(obj.Name)
                n = compose("Plane %d",obj.id);
            else
                n = obj.Name;
            end
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
        
       
        function set.role(obj,r)
            obj.role = r;
            obj.update_log('Role set to "%s"',r)
        end
        
    end % methods (Public); set/get
    
    
    
    
    
    methods (Access = protected)
        function apply_spatial_tform(obj,inv)
            
            if ~obj.initialized, return; end
            
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