function v = get_volume_data(obj)

v = [];
for i = 1:obj.nPlanes
    v = cat(obj.nDims,v,obj.Plane(i).Data);
end

v = permute(v,[1 2 obj.nDims 3:obj.Plane(1).nDims]);
