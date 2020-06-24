%% Prep for movie

M = cell(Plane(1).I.nPlanes,Plane(1).I.nStim);
for StimID = 1:I.nStim
    fprintf('Stim %d of %d ... Creating sequence ...',StimID,I.nStim)
    v = [];
    for pid = 1:Plane(1).I.nPlanes
        I = Plane(pid).I;
        

        x = reshape(squeeze(Plane(pid).Data(:,StimID,:,:)),I.nY,I.nX,I.nTrials,I.nFrames);
        M{pid,StimID} = squeeze(mean(x,I.dTrials));
        
        
        v(:,:,pid,:) = M{pid,StimID};
        
    end
    
%     v = zscore(v,0,[4 3]);
%     
%     for s = 1:I.nFrames
%         
%         ffn = sprintf('Stim%d\\Sequence\\fUSvolume_Stim%d_Seq_%02d.nii',StimID,StimID,s);
%         if ~isfolder(fileparts(ffn)), mkdir(fileparts(ffn)); end
%         
%         vs = v(:,:,:,s);
%         
%         niftiwrite(vs,ffn);
%         ninfo = niftiinfo(ffn);
%         ninfo.PixelDimensions = I.voxelSpacing(1:3);
%         niftiwrite(vs,ffn,ninfo);
%     end
    fprintf(' done\n')
end
clear x

%% interp

mz = cellfun(@(a) zscore(a,0,3),M,'uni',0);
Z = cell(size(mz));

fvec  = 1:size(M{1},3);
fveci = 1:0.25:fvec(end);

for i = 1:numel(M)
    for p = 1:size(M{i},1)
        for q = 1:size(M{i},2)
            z = squeeze(mz{i}(p,q,:));
            if all(isnan(z))
                Z{i}(p,q,:) = nan(1,length(fveci),'single');
            else
                Z{i}(p,q,:) = interp1(fvec,z,fveci,'makima');
            end
        end
    end
    fprintf('Interpolated %02d of %02d\n',i,numel(M))
end


%% Watch a movie


V = VideoWriter('fUS_movie.avi');
V.FrameRate = 20;
open(V);

colormap jet


clf
k = 1;
for p = 1:size(Z,1)
    for q = 1:size(Z,2)
        subplot(size(Z,1),size(Z,2),k)
        
        
%         im(p,q) = imagesc(Z{p,q}(:,:,1));
        im(p,q) = pcolor(Z{p,q}(:,:,1));
        
        set(gca,'clim',[-3 3],'xtick',[],'ytick',[],'ydir','reverse','color','k');
        axis image
        
        if p == 1
            t = title(sprintf('Stim %d',q));
            t.Color = [1 1 1];
        end
        
        if q == 1
            ylabel(p,'Color','w','FontWeight','bold','Rotation',90);
        end
        
        k = k + 1;
    end
    
end

set(im(:),'LineStyle','none');

set(gcf,'color','k');

for i = 1:size(Z{1},3)
    for p = 1:size(Z,1)
        for q = 1:size(Z,2)
            im(p,q).CData = Z{p,q}(:,:,i);
        end
    end
    
    im(1,1).Parent.Title.String = {sprintf('Frame %.1f',fveci(i)),'Stim 1'};
        
    drawnow
    
    frame = getframe(gcf);
    writeVideo(V,frame);
end

close(V);




%%



for i = 1:numel(M)
    M{i}(isnan(M{i})) = 0;    
end
%%
f = figure('color','k','units','normalized');
ax = axes(f,'Position',[0 0 1 .9]);


fus_viewPlanes(M{1},ax)
colormap jet
%%

for i = 1:size(Z{1},3)
%     montage(
%     for p = 1:size(Z,1)
%         for q = 1:size(Z,2)
%             im(p,q).CData = Z{p,q}(:,:,i);
%         end
%     end
    
    im(1,1).Parent.Title.String = {sprintf('Frame %.1f',fveci(i)),'Stim 1'};
        
    drawnow
    
    frame = getframe(gcf);
    writeVideo(V,frame);
end




