function Plane = fus_loadPlanes(fnRoot,planeID)
% Plane = fus_loadPlanes(fnRoot,[planeID])
%
% Load fUS Planes.  Call after running fus_resaveBigData.

if nargin < 2, planeID = []; end

if endsWith(fnRoot,'.mat'), fnRoot(end-3:end) = []; end


if isempty(planeID)
    pid = 1;
    while 1
        fnPlane = sprintf('%s_Plane_%d.mat',fnRoot,pid);
        
        fprintf('"%s" Loading ...',fnPlane)
        
        Plane(pid) = load(fnPlane);
        
        Plane(pid).Manifest{end+1} = 'Loaded Data';
        
        fprintf(' done\n')
        
        if pid == Plane(pid).I.nPlanes, break; end
        pid = pid + 1;
    end
else
    k = 1;
    for pid = planeID
        fnPlane = sprintf('%s_Plane_%d.mat',fnRoot,pid);
        
        fprintf('"%s" Loading ...',fnPlane)
        
        Plane(k) = load(fnPlane);
        Plane(k).Manifest{end+1} = 'Loaded Data';

        fprintf(' done\n')

        k = k + 1;
    end
end