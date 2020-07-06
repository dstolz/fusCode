%% Build HRF (rough) estimate for GLM


stimOnOff = [10 13]; % sec


I = Plane(1).I;

stimIdx = floor(stimOnOff(1)*I.Fs):ceil(stimOnOff(2)*I.Fs);

stimVec = zeros(1,I.nFrames);
stimVec(stimIdx) = 1;

HR = meanHaemoResp;
HR(1:stimIdx(1)) = [];
X = conv(stimVec,HR,'full');
X = X ./ max(X);

X(I.nFrames+1:end) = []; % truncate

plot(stimVec);
hold on
plot(X);
plot(meanHaemoResp);
hold off
grid on

%% Run GLM
I = Plane(1).I;

tStat = cell(I.nPlanes,1);
pVals = tStat;
tic;
parfor pid = 1:length(Plane)
    I = Plane(pid).I;
    npx = length(I.roiMaskIdx);
    
    fprintf('Computing GLM for Plane %d, %d voxels, %d stim\n',I.id,npx,I.nStim)
    
    D = mean(Plane(pid).Data(I.roiMaskIdx,:,:,:),I.dTrials);
    
    y = reshape(D,[npx*I.nStim,I.nFrames])';
    tStat{pid} = zeros(size(y,2),1);
    pVals{pid} = tStat{pid};
    for k = 1:size(y,2)
%         m = fitglm(X,y(:,k),'linear','link','identity');
%         mdl{pid}{k} = compact(m);
        [~,~,stats] = glmfit(X,y(:,k),'normal','link','identity');
        tStat{pid}(k) = stats.t(2);
        pVals{pid}(k) = stats.p(2);
    end
end
fprintf('Completed in %.3f minutes\n',toc/60)


%% Convert GLM results to t-statistic and p-value maps - Y x X x Stim x Plane
I = Plane(1).I;
    
tMap = zeros([I.nY I.nX I.nStim I.nPlanes]);
pMap = tMap;
blankFrame = zeros([I.nY I.nX]);

fprintf('Converting GLM results into t-stat and p-value maps ...')
for pid = 1:length(Plane)
    I = Plane(pid).I;
    npx = length(I.roiMaskIdx);
    
    t = reshape(tStat{pid},[npx I.nStim]);
    p = reshape(pVals{pid},[npx I.nStim]);
    
    tm = blankFrame; pm = blankFrame;
    for s = 1:I.nStim
        tm(I.roiMaskIdx) = t(:,s);
        pm(I.roiMaskIdx) = p(:,s);

        tMap(:,:,s,pid) = tm;
        pMap(:,:,s,pid) = pm;
    end
        
end
fprintf(' done\n')


%% View t-stat maps
M = imtile(reshape(tMap,[I.nY I.nX I.nStim*I.nPlanes]),'GridSize',[I.nPlanes I.nStim]);

ax = subplot(121);

imagesc(ax,M);

axis(ax,'image');
colormap(ax,parula);

ax.CLim = [0 10];

ax.XAxis.Label.String = 'Stim';
ax.XAxis.TickValues = I.nX/2:I.nX:size(M,2);
ax.XAxis.TickLabels = 1:I.nStim;

ax.YAxis.Label.String = 'Planes';
ax.YAxis.TickValues = I.nY/2:I.nY:size(M,1);
ax.YAxis.TickLabels = 1:I.nPlanes;

ax.Title.String = I.fileRoot;
ax.Title.Interpreter = 'none';

h = colorbar(ax);
h.Label.String = 't-stat';








% View p-value maps
M = imtile(reshape(pMap,[I.nY I.nX I.nStim*I.nPlanes]),'GridSize',[I.nPlanes I.nStim]);
M = log10(M);

ax = subplot(122);
imagesc(ax,M);

axis(ax,'image');
colormap(ax,flipud(hot));

ax.CLim = [-5 0];

ax.XAxis.Label.String = 'Stim';
ax.XAxis.TickValues = I.nX/2:I.nX:size(M,2);
ax.XAxis.TickLabels = 1:I.nStim;

ax.YAxis.Label.String = 'Planes';
ax.YAxis.TickValues = I.nY/2:I.nY:size(M,1);
ax.YAxis.TickLabels = 1:I.nPlanes;

ax.Title.String = I.fileRoot;
ax.Title.Interpreter = 'none';

h = colorbar(ax);
h.Label.String = '\itlog_{10}(p)';



%% Export graphics
ffn = fullfile(I.filePath,[I.fileRoot '-GLM_Tonotopy.tif']);
fprintf('Writing %s ...',ffn)
if verLessThan('matlab','9.8')
    saveas(gcf,ffn,'tiff');
else
    exportgraphics(gcf,ffn,'resolution',300);
end
fprintf(' done\n')














