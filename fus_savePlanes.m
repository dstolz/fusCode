function fus_savePlanes(Planes,suffix)
% fus_savePlanes(Plane,[suffix])


if nargin < 2, suffix = ''; end


% if isempty(ffn)
%     [fn,pn] = uiputfile({'*.mat','Matlab File (*.mat)'});
%     if isequal(fn,0)
%         fprintf(2,'User cancelled save\n')
%         return; 
%     end
%     ffn = fullfile(pn,fn);    
% end


for i = 1:length(Planes)
    Plane = Planes(i);
    I = Plane.I;
    [pn,fn,ext] = fileparts(I.fileName);
    fn = [fn suffix ext];
    ffn = fullfile(I.filePath,fn);
    fprintf('Saving "%s" ...',ffn)
    save(ffn,'-struct','Plane','-nocompression','-v7.3');
    fprintf(' done\n')
end

