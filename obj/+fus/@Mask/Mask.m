classdef Mask < handle

    properties       
        
        
    end
    
    properties (SetObservable)
        mask     (:,:) logical
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
        uniqueTag = sprintf('Mask%09d',randi(1e9));
    end
    
    methods
        function obj = Mask(Parent)
            obj.Parent = Parent; 
            obj.mask = true(Parent.nYX);
        end
        
        function create_roi(obj,tool)
            if nargin < 2 || isempty(tool), tool = 'Freehand'; end
            
            mustBeMember(tool,{'Assisted','Circle','Ellipse','Freehand','Polygon','Rectangle'});
            
            f = figure('color','w','name','Mask');
            ax = axes(f);
            imagesc(ax,obj.Parent.Structural);
            axis(ax,'image');
            ax.XAxis.TickValues = [];
            ax.YAxis.TickValues = [];
            ax.Title.String = obj.Parent.Name;
            colormap(ax,bone(512));
            
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
                        
        end
        
        function create_graph(obj)
            
        end
        
        function create_auto(obj)
            
        end
        
        function ax = show(obj,ax)
            
            if nargin < 2 || isempty(ax), ax = gca; end
            
            cla(ax);

            imagesc(ax,obj.Parent.Structural);
            axis(ax,'image');
            ax.XAxis.TickValues = [];
            ax.YAxis.TickValues = [];
            ax.Title.String = obj.Parent.Name;
            colormap(ax,bone(512));
  
            obj.draw_overlay(ax);
            
            
            if nargout == 0, clear ax; end
        end
        
        function h = draw_overlay(obj,ax)
            if nargin < 2, ax = gca; end
            
            hold(ax,'on');
            c = obj.coords;
            h = patch(ax,c(:,2),c(:,1),[0 1 1]);
            h.EdgeColor = [0 1 1];
            h.FaceAlpha = .2;
            h.EdgeAlpha = .8;
            h.LineWidth = 2;
            hold(ax,'off');
            
        end
        
        function b = get.coords(obj)
            
            [r,c] = find(obj.mask,1);
            b = bwtraceboundary(obj.mask,[r c],'N');
            
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
    end
end