function h = fus_viewPlanes(Plane,parent,logTransform)
% h = fus_viewPlanes(Plane,parent,logTransform)
%
% View planes from current data
%
% parent     -   handle to parent container (default = gca)

if nargin < 2 || isempty(parent), parent = gca; end
if nargin < 3 || isempty(logTransform), logTransform = true; end

if isstruct(Plane)
    I = Plane(1).I;
    X = arrayfun(@(a) rms(a.Data,[a.I.dTrials a.I.dFrames a.I.dStim]),Plane,'uni',0);
    X = cell2mat(X);
    X = reshape(X,[I.nY I.nX length(Plane)]);
else
    X = single(Plane);
end


if logTransform
    X = sign(X) .* log10(abs(X)) * 10;
end

X(isnan(X)) = 0; % otherwise montage will create artifacts

warning('off','images:imshow:magnificationMustBeFitForDockedFigure');

[a,b] = bounds(X(:));
h = montage(X,'parent',parent,'displayrange',[a b]);


warning('on','images:imshow:magnificationMustBeFitForDockedFigure');

