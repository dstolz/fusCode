function overlay_update(obj,src,event,h)




data = [];
for i = 1:obj.nPlanes
    if isempty(obj.Plane(i).bgPlane)
        d = nan(obj.Plane(i).nYX);
    else
        d = obj.Plane(i).bgPlane.Data;
    end
    data = cat(3,data,d);
end

data = imtile(data,'GridSize',gridSize);

h(1).CData = data;






data = [];
for i = 1:obj.nPlanes
    if isempty(obj.Plane(i).fgPlane)
        d = nan(obj.Plane(i).nYX);
    else
        d = obj.Plane(i).fgPlane.Data;
    end
    data = cat(3,data,d);
end

data = imtile(data,'GridSize',gridSize);

h(2).CData = data;
h(2).AlphaData = .75 * data >= obj.fgPlane.dataThreshold;



drawnow



