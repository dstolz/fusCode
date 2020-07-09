function im = center_crop(im,nYX)
%  im = center_crop(im,nYX)
%
% adapted from centerCropWindow2d.m


n = size(im);

sz = 1 + ceil((n([1 2]) - nYX)/2);

x = [sz(2),sz(2)+nYX(2)-1];
y = [sz(1),sz(1)+nYX(1)-1];


if length(n) > 2
    im = reshape(im,[n([1 2]) prod(n(3:end))]);
    im = im(y(1):y(2),:,:);
    im = im(:,x(1):x(2),:);
    im = reshape(im,[size(im,1) size(im,2) n(3:end)]);
else
    
    im = im(y(1):y(2),:,:);
    im = im(:,x(1):x(2),:);
    
end
