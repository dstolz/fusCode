function explorer_update(obj,src,event,h) % Volume
% DJS 2020


% if ~isempty(obj.UserData.roiTime) && etime(clock,obj.UserData.roiTime) < .1, return; end % be nice to the cpu
% 
% obj.UserData.roiTime = clock;

P = obj.Plane(1);

roi = findobj('Tag',strcat("ROI_", obj.Name));

imAx = roi.Parent;
figH = imAx.Parent;



n = P.num;

rind = createMask(roi);

planesIncl = imAx.UserData.planeIdx(rind);
u = unique(planesIncl);
u(u==0) = [];
vxCount = 0;
M = [];
for i= 1:length(u)
    pind = imAx.UserData.planeIdx==u(i);
    [py(1),px(1)] = find(pind,1,'first');
    [py(2),px(2)] = find(pind,1,'last');
    
    rpind = pind & rind;
    rpind = rpind(py(1):py(2),px(1):px(2));
    
    vxCount = vxCount + nnz(rpind);
    
    M = cat(1,M,plane_subset(obj.Plane(u(i)).Data,rpind));
end


d = setdiff(P.dimOrder,{P.eventDimName P.timeDimName});
mROI = mean(M,P.find_dim(d),'omitnan');

mROI = squeeze(mROI);
if size(mROI,2) == n.(P.eventDimName), mROI = mROI'; end

nStim = size(mROI,1); % use this in case P.dim.(P.eventDimName) does not exist

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


ylabel(ax,{sprintf('%d pixels in ROI',vxCount); 'mean ampl. (arb units)'})

title(imAx,sprintf('%s - Selected Plane(s) %s',obj.Name,mat2str(u')))


