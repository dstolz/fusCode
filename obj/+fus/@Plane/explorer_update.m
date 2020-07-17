function explorer_update(obj,src,event)

% DJS 2020


% if ~isempty(obj.UserData.roiTime) && etime(clock,obj.UserData.roiTime) < .1, return; end % be nice to the cpu
% 
% obj.UserData.roiTime = clock;



roi = findobj('Tag',['ROI_' obj.Name]);

imAx = roi.Parent;
figH = imAx.Parent;


n = obj.num;

ind = createMask(roi);

d = setdiff(obj.dimOrder,[obj.eventDimName obj.timeDimName]);
mROI = mean(plane_subset(obj.Data,ind),obj.find_dim(d),'omitnan');

mROI = squeeze(mROI);
if size(mROI,2) == n.(obj.eventDimName), mROI = mROI'; end

nStim = size(mROI,1); % use this in case obj.dim.(obj.eventDimName) does not exist

xvec = 1:size(mROI,2);
ivec = 1:0.25:xvec(end);
if any(isnan(mROI(:)))
    miROI = nan(nStim,length(ivec));
else
    miROI = zeros(size(mROI,1),length(ivec));
    for i = 1:size(mROI,1)
        miROI(i,:) = interp1(xvec,mROI(i,:),ivec,'makima');
    end
end
clear mROI

ivec = ivec';
miROI = miROI';


ax = findobj(figH,'tag','ROITimePlot');
buildFlag = isempty(ax);
if buildFlag
    ax = axes(figH,'Units','Normalized','Position',[.2 .1 .7 .3]);

    ax2 = axes(figH,'units','normalized','position',ax.Position,'color','none', ...
        'ytick',[],'tag','ROITimePlot2');
    grid(ax,'on');
    
    ax.XLim     = [1 n.(obj.timeDimName)];
    ax2.XLim    = [0 (n.(obj.timeDimName)-1)/obj.Fs];
    ax.XAxisLocation = 'top';
    
    
    x = (ax.XAxis.TickValues-1)/obj.Fs;
    ax2.XAxis.TickValues = x;
    
    box(ax,'on');
    
    ax.Tag = 'ROITimePlot'; % for some reason, this needs to be set last???
end


zh = findobj(ax,'tag','zeroline');
if isempty(zh)
    line(ivec([1 end]),[0 0],'parent',ax,'color',[.4 .4 .4],'linewidth',2, ...
        'Tag','zeroline');
end

if nStim == 1
    cm = [0 0 0];
else
    cm = parula(nStim);
end


h = findobj(ax,'-regexp','tag','stimline*');
if isempty(h)
    for i = 1:nStim
        h(i) = line(ivec,miROI(:,i),'color',cm(i,:),'linewidth',2, ...
            'parent',ax,'tag',sprintf('stimline%d',i));
    end
else
    [~,idx] = sort({h.Tag});
    h = h(idx);
    for i = 1:nStim
        h(i).YData = miROI(:,i);
    end
end

if buildFlag
    if isfield(n,obj.eventDimName)
        h = legend(ax,h, ...
            'Location','EastOutside','Orientation','vertical');
        
        if isempty(obj.Event)
            h.String = string(1:size(miROI,2));
            h.Title.String = 'EventID';
        else
            h.String = obj.Event.uValueStr;
            h.Title.String = obj.Event.Name;
        end
    end
    xlabel(ax,'frames','FontSize',12)
    xlabel(ax2,'time (s)','FontSize',12)
    
    ax2.Position = ax.Position;
end
ylabel(ax,{sprintf('%d pixels in ROI',nnz(ind & obj.Mask.mask)); 'mean ampl. (arb units)'})




