function overlay_update(obj,src,event,h)

alpha = getpref('fus_Plane_display','alpha',.75);

h(1).CData = obj.bgPlane.Data;

h(2).CData = obj.fgPlane.Data;
h(2).AlphaData = alpha * single(obj.fgPlane.Data >= obj.fgPlane.dataThreshold);




