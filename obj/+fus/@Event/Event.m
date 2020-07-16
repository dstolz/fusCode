classdef Event < handle & matlab.mixin.SetGet & matlab.mixin.Copyable & dynamicprops
    
    properties
        Name        (1,:) string = "";
        Description (1,:) string = "";
        Onset       (:,1) double {mustBeNumeric} = 0;
        Duration    (:,1) double {mustBeNonnegative,mustBeFinite}= 1;
        Value       (:,1) {mustBeNumeric} = nan;
        Unit        (1,:) string = "";
        ScaleFactor (1,1) double {mustBeFinite} = 1;
        
        Format      (1,1) string {mustBeMember(Format,["cell" "struct" "table"])} = "struct";
        Conversion  (1,1) string {mustBeMember(Conversion,["time" "samples"])}    = "time";
    end
    
    
    properties (Dependent)
        OnOffTime
        OnOffSample
        uValue
    end
    
    properties (SetAccess = immutable)
        Fs (1,1) double {mustBeNonempty,mustBePositive,mustBeFinite} = 1;
    end
    
    methods
        function obj = Event(Name,Onset,Value,Duration,Fs,Unit)
            if nargin == 0, return; end
            if nargin < 5 || isempty(Fs), Fs = 1; end
            if nargin < 6 || isempty(Unit), Unit = ""; end
            
            narginchk(2,6);
            
            obj.Name = Name;
            obj.Fs = Fs;
            obj.Value = Value;
            obj.Onset = Onset;
            obj.Duration = Duration;
            obj.Unit = Unit;
        end
        
        
        
        function d = get_Data(obj,vals,format,conversion,trim)
            if nargin < 2 || isempty(vals),       vals = obj.uValue;           end
            if nargin < 3 || isempty(format),     format = obj.Format;         end
            if nargin < 4 || isempty(conversion), conversion = obj.Conversion; end
            if nargin < 5 || isempty(trim),       trim = false;                end
            
            vals = vals(:)';
            
            d(size(vals)) = struct('Onset',[],'Offset',[]);
                                                  
            switch conversion
                case "time"
                    onoff = obj.OnOffTime;
                case "samples"
                    onoff = obj.OnOffSample;
            end
            
            for i = 1:numel(vals)
                ind = obj.Value == vals(i);
                if ~trim
                    d(i).Name     = obj.Name;
                    d(i).Unit     = obj.Unit;
                    d(i).Description = obj.Description;
                end
                d(i).Value    = vals(i);
                d(i).Onset    = onoff(ind,1);
                d(i).Offset   = onoff(ind,2);
                d(i).Duration = diff(onoff(ind,:),1,2);
                d(i).Index    = find(ind);
                d(i).N        = nnz(ind);
            end
            
            switch format
                case "table"
                    d = struct2table(d);
                   
                case "cell"
                    d = struct2cell(d);
            end
            d = squeeze(d);
        end
        
        
        
        
        
        
        
        function t = get.OnOffTime(obj)
            t = obj.Onset + [0 obj.Duration];
        end
        
        function s = get.OnOffSample(obj)
            s = 1+round(obj.OnOffTime*obj.Fs);
        end
        
        function u = get.uValue(obj)
            u = unique(obj.Value);
        end
        
        
        
    end % method (Public)
    
    
    methods (Access = private)
        
    end
end