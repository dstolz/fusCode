function update_roi(roi,event,Plane,f)

% this can be improved by using plotting primitives instead of high-level
% syntax

I = Plane.I;


ind = createMask(roi);

ind = ind & I.roiMaskInd;

ind = reshape(ind,[I.nPixels,1]);


mROI = squeeze(mean(Plane.Data(ind,:,:,:),[I.dTrials, I.dPixels]));


ivec = 1:0.25:I.nFrames;
if any(isnan(mROI(:)))
    miROI = nan(I.nStim,length(ivec));
else
    for i = 1:I.nStim
        miROI(i,:) = interp1(1:I.nFrames,mROI(i,:),ivec,'makima');
    end
end


ax = findobj(f,'tag','ROITimePlot');
buildFlag = isempty(ax);
if buildFlag
    ax = axes('Units','Normalized','Position',[.2 .1 .7 .3]);

    x = ax.XAxis.TickValues/2.5;
    ax2 = axes(gcf,'units','normalized','position',ax.Position,'color','none', ...
        'ytick',[],'xlim',xlim(ax)/2.5,'xtick',x,'tag','ROITimePlot2');
    grid(ax,'on');
    xlim(ax,[1 I.nFrames]);
    
    ax.XAxisLocation = 'top';
    ax.Tag = 'ROITimePlot'; % for some reason, this needs to be set last???

end


zh = findobj(ax,'tag','zeroline');
if isempty(zh)
    line(ivec([1 end]),[0 0],'parent',ax,'color',[.4 .4 .4],'linewidth',2, ...
        'Tag','zeroline');
end


h = findobj(ax,'tag','stimlines');
if isempty(h)
    h = line(repmat(ivec',1,I.nStim),miROI','parent',ax,'tag','stimlines');
else
    for i = 1:I.nStim
        h(i).YData = miROI(i,:);
    end
end

if ~all(isnan(miROI(:)))
    ylim(ax,[-1.1 1.1]*max(abs(miROI(:))));
end

if buildFlag
    h = legend(ax,h, ...
        'Location','EastOutside','Orientation','vertical');
    h.String = cellstr(num2str((1:I.nStim)'))';
    h.Title.String = 'StimID';
    
    xlabel(ax,'frames','FontSize',14)
    xlabel(ax2,'time (s)','FontSize',14)
    
    ax2.Position = ax.Position;
end
ylabel(ax,{sprintf('Average of %d pixels in ROI',nnz(ind)); 'mean ampl. (arb units)'})




