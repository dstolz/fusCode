


addpath('C:\Users\Daniel\src\FastICA_25')


%% Prep data by appending means of stimuli

X = cast([],'like',Plane(1).Data);

for i = 1:length(Plane)
    I = Plane(i).I;
    
    y = squeeze(mean(Plane(i).Data(I.roiMaskIdx,:,:,:),I.dTrials));
    y = reshape(y,[length(I.roiMaskIdx) I.nStim*I.nFrames]);
        
    X = cat(1,X,y);
end
clear y
% X = X';
% X = zscore(X);
% X = X - mean(X);

whos X

%% Prep data one mean stimulus at a time

stimID = 3;


% icaType = 'temporal';
icaType = 'spatial';

X = cast([],'like',Plane(1).Data);

for i = 1:length(Plane)
    I = Plane(i).I;
    
    y = squeeze(mean(Plane(i).Data(I.roiMaskIdx,stimID,:,:),I.dTrials));
    y = reshape(y,[length(I.roiMaskIdx) I.nFrames]);
        
    X = cat(1,X,y);
end
clear y
% X = X';
% X = zscore(X);
% X = X - mean(X);

switch icaType
    case 'spatial'
        X = X';
end

whos X

%% Reduce dimensionality using PCA

[E,S,L,~,~,mu] = pca(X,'economy',false);

ev = cumsum(L)./sum(L);

% plot(ev,'-o');
% grid on

inclComp = max(find(ev>.9,1),10) + 1;

fprintf('PCA dimensionality reduction using %d components containing %.3f%% of var\n',inclComp,ev(inclComp)*100)

Xh = S(:,1:inclComp) * E(:,1:inclComp)';
Xh = bsxfun(@plus,Xh,mu);

%% Run fastica - each row is one observed signal - pixels x samples

q = inclComp - 1; % # ICA components to extract
X = fastica(Xh,'numOfIC',q,'approach', 'symm',  ...
    'g', 'tanh','finetune','tanh','stabilization','on', ...
    'maxFinetune',1000,'epsilon',1e-5, ...
    'displayMode','off');

X = zscore(X,0,'all');

%% Reconstruction from Components
 I = Plane(1).I;

switch icaType
    case 'spatial'
        icaData = zeros([I.nY I.nX I.nPlanes q],'like',X);
        for k = 1:q
            px = 1;
            for i = 1:length(Plane)
                I = Plane(i).I;
                
                y = zeros([I.nPixels 1]);
                
                y(I.roiMaskIdx) = X(k,px:px+length(I.roiMaskIdx)-1);
                
                icaData(:,:,i,k) = reshape(y,[I.nY I.nX]);
                
                px = px + length(I.roiMaskIdx);
            end
        end
        
    case 'temporal'
        % todo
%         icaData = zeros([I.nY I.nX I.nPlanes q],'like',X);
%         for k = 1:q
%             px = 1;
%             for i = 1:length(Plane)
%                 I = Plane(i).I;
%                 
%                 y = zeros([I.nPixels 1]);
%                 
%                 y(I.roiMaskIdx) = X(k,px:px+length(I.roiMaskIdx)-1);
%                 
%                 icaData(:,:,i,k) = reshape(y,[I.nY I.nX]);
%                 
%                 px = px + length(I.roiMaskIdx);
%             end
%         end
end

whos icaData
fprintf('icaData dim order: row x col x plane x component\n')



%% Plot by component for each plane
figure('windowstyle','docked','color','w')

M = [];
for i = 1:q
    M = cat(3,M,icaData(:,:,:,i));
end

% r = quantile(abs(M(:)),.999);
r = 4;
montage(M,'displayrange',[-1 1]*r,'size',[q length(Plane)]);

cm = jet(64);
cm(32:33,:) = [1 1 1; 1 1 1];
colormap(cm)


title(sprintf('%s | Stim # %d',Plane(1).I.fileRoot,stimID), ...
    'FontSize',18,'interpreter','none')

ylabel('ICA Component #','FontSize',14);
xlabel('fUS Planes','FontSize',14);

h = colorbar;

h.Label.String = 'z-score';
h.FontSize = 16;
h.Label.FontSize = 18;

rootPath = 'C:\Users\Daniel\Documents\MATLAB\FigurePopoutData'; % fix this
fn = sprintf('%s-StimID_%d_ICAresults.tif',I.fileOriginal,stimID);
ffn = fullfile(rootPath,fn);
exportgraphics(gca,ffn,'ContentType','image','Resolution',300,'BackgroundColor','current') 



%% Write a NIfTI file for each component

rootPath = 'C:\Users\Daniel\Documents\MATLAB\FigurePopoutData'; % fix this
for i = 1:q
    
    I = Plane(1).I;
    fn = sprintf('%s-StimID_%d_ICA_%d.nii',I.fileOriginal,stimID,i);
    ffn = fullfile(rootPath,fn);
    fprintf('Writing "%s" ...',fn)
    
    v = icaData(:,:,:,i);
    
    niftiwrite(v,ffn);
    ninfo = niftiinfo(ffn);
    ninfo.PixelDimensions = I.voxelSpacing(1:3);
    niftiwrite(v,ffn,ninfo);
    
    fprintf(' done\n')
    
end




























%% NEEDS WORK timecourses of ica components
I = Plane(1).I;
tcData = zeros(I.nPixels,I.nStim,I.nFrames,I.nPlanes,'like',Plane(1).Data);
for k = 1:q
    I = Plane(1).I;

    y = reshape(icaData(:,:,:,k),[I.nPixels,I.nPlanes]);
    
    for i = 1:length(Plane)
        s = y(:,i);
        m = squeeze(mean(Plane(i).Data,I.dTrials));
        m = m ./ max(abs(m));
        tcData(:,:,:,k,i) = m .* s;
    end
end

%%
pid = 2;
sid = 1;

baselineIdx = 1:10;
responseIdx = 20:30;

bData = squeeze(mean(tcData(:,:,baselineIdx,:,pid),3));
rData = squeeze(mean(tcData(:,:,responseIdx,:,pid),3));

rData = (rData - bData) ./ bData;

rData = reshape(rData,[I.nY I.nX I.nStim q]);

m = squeeze(rData(:,:,sid,:));
m(isnan(m)) = 0;

clf

r = quantile(abs(m(:)),.99);

montage(m,'DisplayRange',r*[-1 1]);
colormap jet

