function overlay_update(obj,src,event,h)




fgH = h(ismember({h.Tag},'foreground'));
bgH = h(ismember({h.Tag},'background'));

fgAx = ancestor(fgH,'axes');
bgAx = ancestor(bgH,'axes');

figH = ancestor(fgH,'figure');



% background
data = [];
for i = 1:obj.nPlanes
    if isempty(obj.Plane(i).bgPlane)
        d = nan(obj.Plane(i).nYX);
    else
        d = obj.Plane(i).bgPlane.Data;
    end
    data = cat(3,data,d);
end

data = imtile(data,'GridSize',bgAx.UserData.gridSize);

bgH.CData = data;





% foreground
data = [];
for i = 1:obj.nPlanes
    if isempty(obj.Plane(i).fgPlane)
        d = nan(obj.Plane(i).nYX);
    else
        d = obj.Plane(i).fgPlane.Data;
    end
    data = cat(3,data,d);
end

data = imtile(data,'GridSize',fgAx.UserData.gridSize);

fgH.CData = data;
fgH.AlphaData = .75 * data >= obj.Plane(1).fgPlane.dataThreshold;



drawnow



