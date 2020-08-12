function v = get_volume_data(obj)

v = [];
n = obj.nDims;
for i = 1:obj.nPlanes
    v = cat(n,v,obj.Plane(i).Data);
end

v = permute(v,[1 2 obj.nDims 3:obj.Plane(1).nDims]);
