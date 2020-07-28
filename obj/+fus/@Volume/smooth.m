function smooth(obj,gwN,gwSD)
% smooth(obj,[gwN],[gwSD)

if nargin < 2 || isempty(gwN),  gwN = 3;    end
if nargin < 3 || isempty(gwSD), gwSD = 0.5; end

switch length(gwN) 
    case 1
        gwN = [gwN gwN 1];
    case 2
        gwN = [gwN 1];        
end

P = obj.Plane; % handles

% data -> {Plane} [Y x X x AllOtherDims]
X = arrayfun(@(a) a.reshape_data({'Y' 'X' ''}),P,'uni',0);


% data -> [Y x X x Plane x AllOtherDims]
Y = [];
for i = 1:length(X)
    n = size(X{i});
    Y = cat(3,Y,reshape(X{i},[n(1:2) 1 n(3)]));
end
clear X

% smooth volume for each frame
for i = 1:size(Y,4)
    Y(:,:,:,i) = smooth3(Y(:,:,:,i),'gaussian',gwN,gwSD); %#ok<AGROW>
end

% data -> {Plane} [original dims]
for i = 1:size(Y,3)
    P(i).set_Data(reshape(squeeze(Y(:,:,i,:)),P(i).dimSizes));
    P(i).update_log('Volumetric smoothing: gwN = %s; gwSD = %g',mat2str(gwN),gwSD);
end
