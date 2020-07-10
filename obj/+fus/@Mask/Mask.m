classdef Mask < handle

    properties       
        UserData
    end
    
    properties (SetObservable)
        mask            (:,:) logical
        minSatellitePx  (1,1) double {mustBeNonnegative,mustBeFinite,mustBeInteger} = 10;
    end
    
    
    properties (Dependent)
        idx
        coords
        nMaskPixels
    end
    
    properties (Access = private)
        initialized = false;
    end
    
    properties (SetAccess = immutable)
        Parent % fus.Plane handle
    end
    
    properties (Constant)
        uniqueTag = sprintf('Mask%09d',round(now*1e9));
    end
    
    methods
        function obj = Mask(Parent)            
            obj.Parent = Parent; 
            obj.mask = true(Parent.nYX); % set default mask
        end
        
        function create_roi(obj,tool)
            if nargin < 2 || isempty(tool), tool = 'Freehand'; end
            
            mustBeMember(tool,{'Assisted','Circle','Ellipse','Freehand','Polygon','Rectangle'});
            
            f = figure('color','w','name','Mask');
            ax = axes(f);
            
            ax.Parent.WindowKeyPressFcn = @obj.exit_roi;
            
            
            roi = images.roi.(tool)('linewidth',3,'color','c', ...
                'deletable',false,'Parent',ax,'FaceSelectable',false, ...
                'InteractionsAllowed','reshape','Multiclick',true, ...
                'Tag',obj.uniqueTag);
            
            if obj.initialized
                c = obj.coords;
                roi.Position = fliplr(c);
                roi.Waypoints = ismember(1:size(c,1),round(linspace(1,size(c,1),10)))';
            else
                draw(roi);
            end
               
            obj.Parent.update_log('Mask adjusted using manual ROI')
        end
        
        function create_threshold(obj,thr)
            if nargin < 2, thr = []; end
            
            f = findobj('Tag',['MaskThrFig_' obj.uniqueTag]);
            if isempty(f)
                f = figure('Tag',['MaskThrFig_' obj.uniqueTag],'color','w');
            end
            figure(f);
            
            ax = subplot(4,1,[1 3]);
            obj.show_mask(ax);
            ch = colorbar(ax);
            ch.Label.String = 'pixel value';
            
            if isempty(thr), thr = median(obj.Parent.Structural(:),'omitnan'); end

            obj.mask = obj.Parent.Structural >= thr;
            
            
            ax = subplot(414);
            histogram(ax,obj.Parent.Structural(:), ...
                'linestyle','none','HitTest','off');
            grid(ax,'on');
            ax.YAxis.Label.String = 'pixel count';
            ax.XAxis.Label.String = 'pixel value';
            ax.Title.String = sprintf('Threshold = %.3f',thr);
            line(ax,[1 1]*thr,ylim(ax),'color','r','linestyle','-','linewidth',2, ...
                'Tag',['MaskThr_' obj.uniqueTag],'HitTest','off'); % updatefcn
            ax.ButtonDownFcn = @obj.update_threshold;
            
            obj.Parent.update_log('Mask adjusted using threshold = %.f',thr)
        end
        
        
        function create_graph(obj)
            
        end
        
        
        
        
        
        
        function h = show_mask(obj,ax,varargin)
            if nargin < 2, ax = gca; end
            h(1) = obj.show_structural(ax);
            h(2) = obj.draw_overlay(ax);
        end
        
        
        
        function h = show_structural(obj,ax)
            if nargin < 2, ax = gca; end
            h = imagesc(ax,obj.Parent.Structural);
            h.Tag = ['Structural_' obj.uniqueTag];
            axis(ax,'image');
            ax.XAxis.TickValues = [];
            ax.YAxis.TickValues = [];
            ax.Title.String = obj.Parent.Name;
            colormap(ax,bone(512));
        end
        
        function h = draw_overlay(obj,ax)
            if nargin < 2, ax = gca; end
            
            hold(ax,'on');
            c = obj.coords;
            h = patch(ax,c(:,1),c(:,2),[0 1 1]);
            h.Tag = ['Patch_' obj.uniqueTag];
            h.EdgeColor = [0 1 1];
            h.FaceAlpha = .2;
            h.EdgeAlpha = .8;
            h.LineWidth = 2;
            hold(ax,'off');
            
            obj.update_overlay([],[],h)
            addlistener(obj,'mask','PostSet', @(src,evnt) obj.update_overlay(src,evnt,h));
        end
        
        function set.mask(obj,ind)
            if obj.minSatellitePx ~= inf
                ind = bwpropfilt(ind,'Area',[obj.minSatellitePx inf]);
            end
            obj.mask = ind;
        end
        
        function c = get.coords(obj)
            [r,c] = find(obj.mask,1);
            if isempty(r)
                c = [];
            else
                c = bwtraceboundary(obj.mask,[r c],'N');
                c = c(:,[2 1]);
            end
        end
        
        function n = get.nMaskPixels(obj)
            n = nnz(obj.mask);
        end
        
    end % methods (Public)

    methods (Access = private)
        function exit_roi(obj,src,event)

            switch event.Key
                case 'escape'
                    close(src);
                    
                case 'return'
                    roi = findobj(src,'tag',obj.uniqueTag);
                    obj.mask = createMask(roi);
                    obj.initialized = true;
                    close(src);
                    fprintf('Created mask for %s\n',obj.Parent.Name)
                    obj.Parent.update_log('Created mask');
                    
                case 'slash'
                    fprintf('%s\nHelp on Mask creation:\n',repmat('~',1,50))
                    fprintf('\t> Draw a rough mask using the left mouse button.\n')
                    fprintf('\t> Use the left mouse button to adjust the waypoints.\n')
                    fprintf('\t> Add waypoints by double-clicking the line.\n')
                    fprintf('\t> Remove waypoints by right-clicking it.\n')
                    fprintf('\t> Press the Enter key when done.\n')
                    fprintf('\t> Cancel mask creation using the Esc key.\n')
            end
        end
        
        function update_overlay(obj,src,event,h)

            if ~isvalid(h), return; end
            c = obj.coords;
            if isempty(c)
                h.XData = nan; h.YData = nan;
            else
                h.XData = c(:,1);
                h.YData = c(:,2);
            end
        end
        
        function update_threshold(obj,src,event)
            thr = event.IntersectionPoint(1);
            
            obj.mask = obj.Parent.Structural >= thr;
            
            h = findobj(src,'tag',['MaskThr_' obj.uniqueTag]);
            h.XData = [1 1]*thr;
            
            h.Parent.Title.String = sprintf('Threshold \\geq %.3f',thr);
            
            obj.Parent.update_log('Mask adjusted using threshold = %g',thr);
        end
    end
end