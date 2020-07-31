function overlay_update(obj,src,event,h)


h(1).CData = obj.bgPlane.Data;

h(2).CData = obj.fgPlane.Data;
h(2).AlphaData = .75 * obj.fgPlane.Data >= obj.fgPlane.dataThreshold;


drawnow



