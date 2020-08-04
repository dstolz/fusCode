function explorer_update(obj,src,event)
% DJS 2020


% if ~isempty(obj.UserData.roiTime) && etime(clock,obj.UserData.roiTime) < .1, return; end % be nice to the cpu
% 
% obj.UserData.roiTime = clock;



roi = findobj('Tag',strcat("ROI_", obj.FullName));

imAx = roi.Parent;
figH = imAx.Parent;


n = obj.num;

ind = createMask(roi);

d = setdiff(obj.dimOrder,{obj.eventDimName obj.timeDimName});
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
ax2 = findobj(figH,'tag','ROITimePlot2');


h = findobj(ax,'-regexp','tag','stimline*');

[~,idx] = sort({h.Tag});
h = h(idx);
for i = 1:nStim
    h(i).XData = ivec;
    h(i).YData = miROI(:,i);
end


ylabel(ax,{sprintf('%d pixels in ROI',nnz(ind & obj.Mask.mask)); 'mean ampl. (arb units)'})




