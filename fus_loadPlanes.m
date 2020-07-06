function Plane = fus_loadPlanes(fnRoot,planeID,suffix)
% Plane = fus_loadPlanes(fnRoot,[planeID],[suffix])
%
% Load fUS Planes.  Call after running fus_resaveBigData.

if nargin < 2, planeID = []; end
if nargin < 2, suffix = ''; end

if endsWith(fnRoot,'.mat'), fnRoot(end-3:end) = []; end


if isempty(planeID)
    pid = 1;
    while 1
        fnPlane = sprintf('%s_Plane_%d%s.mat',fnRoot,pid,suffix);
        
        fprintf('"%s" Loading ...',fnPlane)
        
        Plane(pid) = load(fnPlane);
                
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