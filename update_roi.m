function update_roi(roi,event,Plane,figH)

% DJS 2020


if ~isempty(roi.UserData) && etime(clock,roi.UserData) < .1, return; end % be nice to the cpu

roi.UserData = clock;
    
I = Plane.I;


ind = createMask(roi);

if isfield(I,'roiMaskInd')
    ind = ind & I.roiMaskInd;
end

ind = reshape(ind,[I.nPixels,1]);


mROI = squeeze(mean(Plane.Data(ind,:,:,:),[I.dTrials, I.dPixels],'omitnan'));

xvec = 1:I.nFrames;
ivec = 1:0.25:I.nFrames;
if any(isnan(mROI(:)))
    miROI = nan(I.nStim,length(ivec));
else
    for i = 1:I.nStim
        miROI(i,:) = interp1(xvec,mROI(i,:),ivec,'makima');
    end
end

ivec = ivec';
miROI = miROI';

ax = findobj(figH,'tag','ROITimePlot');
buildFlag = isempty(ax);
if buildFlag
    ax = axes('Units','Normalized','Position',[.2 .1 .7 .3]);

    ax2 = axes(gcf,'units','normalized','position',ax.Position,'color','none', ...
        'ytick',[],'tag','ROITimePlot2');
    grid(ax,'on');
    
    ax.XLim     = [1 I.nFrames];
    ax2.XLim    = [0 (I.nFrames-1)/I.Fs];
    ax.XAxisLocation = 'top';
    
    
    x = (ax.XAxis.TickValues-1)/I.Fs;
    ax2.XAxis.TickValues = x;
    
    box(ax,'on');
    
    ax.Tag = 'ROITimePlot'; % for some reason, this needs to be set last???
end


zh = findobj(ax,'tag','zeroline');
if isempty(zh)
    line(ivec([1 end]),[0 0],'parent',ax,'color',[.4 .4 .4],'linewidth',2, ...
        'Tag','zeroline');
end

cm = lines(I.nStim);

h = findobj(ax,'-regexp','tag','stimline*');
if isempty(h)
    for i = 1:I.nStim
        h(i) = line(ivec,miROI(:,i),'color',cm(i,:),'linewidth',2, ...
            'parent',ax,'tag',sprintf('stimline%d',i));
    end
else
    [~,idx] = sort({h.Tag});
    h = h(idx);
    for i = 1:I.nStim
        h(i).YData = miROI(:,i);
    end
end

% if ~all(isnan(miROI(:)))
%     ylim(ax,[-1.1 1.1]*max(abs(miROI(:))));
% end

if buildFlag
    h = legend(ax,h, ...
        'Location','EastOutside','Orientation','vertical');
    h.String = cellstr(num2str((1:I.nStim)'))';
    h.Title.String = 'StimID';
    
    xlabel(ax,'frames','FontSize',12)
    xlabel(ax2,'time (s)','FontSize',12)
    
    ax2.Position = ax.Position;
end
ylabel(ax,{sprintf('Average of %d pixels in ROI',nnz(ind)); 'mean ampl. (arb units)'})




