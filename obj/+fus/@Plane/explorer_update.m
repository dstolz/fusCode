function explorer_update(obj,roi,event,imAx)

% DJS 2020


if ~isempty(roi.UserData) && etime(clock,roi.UserData) < .1, return; end % be nice to the cpu

roi.UserData = clock;


figH = imAx.Parent;


d = obj.dim;
n = obj.num;

ind = createMask(roi);


% ind = ind & obj.Mask.ind;
% ind = reshape(ind,[I.nPixels,1]);


mROI = mean(plane_subset(obj.Data,ind),[d.Y d.X d.Trials],'omitnan');
mROI = squeeze(mROI);
xvec = 1:size(mROI,2);
ivec = 1:0.25:xvec(end);
if any(isnan(mROI(:)))
    miROI = nan(n.Stim,length(ivec));
else
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
    
    ax.XLim     = [1 n.Frames];
    ax2.XLim    = [0 (n.Frames-1)/obj.Fs];
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

cm = parula(n.Stim);

h = findobj(ax,'-regexp','tag','stimline*');
if isempty(h)
    for i = 1:n.Stim
        h(i) = line(ivec,miROI(:,i),'color',cm(i,:),'linewidth',2, ...
            'parent',ax,'tag',sprintf('stimline%d',i));
    end
else
    [~,idx] = sort({h.Tag});
    h = h(idx);
    for i = 1:n.Stim
        h(i).YData = miROI(:,i);
    end
end

% if ~all(isnan(miROI(:)))
%     ylim(ax,[-1.1 1.1]*max(abs(miROI(:))));
% end

if buildFlag
    h = legend(ax,h, ...
        'Location','EastOutside','Orientation','vertical');
    h.String = cellstr(num2str((1:size(miROI,2))'))';
    h.Title.String = 'StimID';
    
    xlabel(ax,'frames','FontSize',12)
    xlabel(ax2,'time (s)','FontSize',12)
    
    ax2.Position = ax.Position;
end
ylabel(ax,{sprintf('Average of %d pixels in ROI',nnz(ind)); 'mean ampl. (arb units)'})




