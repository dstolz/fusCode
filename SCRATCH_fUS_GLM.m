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
tMap = zeros([I.nY I.nX I.nStim I.nPlanes]);
pMap = tMap;
blankFrame = zeros([I.nY I.nX]);
for pid = 1:length(Plane)
    
    I = Plane(pid).I;
    npx = length(I.roiMaskIdx);
    
    fprintf('Computing GLM for Plane %d, %d voxels, %d stim ...',I.id,npx,I.nStim)
    
    D = mean(Plane(pid).Data(I.roiMaskIdx,:,:,:),I.dTrials);
    
    y = reshape(D,[npx*I.nStim,I.nFrames])';
    mdl = cell(size(y,2),1);
    parfor k = 1:size(y,2)
        m = fitglm(X,y(:,k),'linear','link','identity');
        mdl{k} = compact(m);
    end
    tstat = cellfun(@(a) a.Coefficients.tStat(2),mdl);
    pvals = cellfun(@(a) a.Coefficients.pValue(2),mdl);
    
    tstat = reshape(tstat,[npx I.nStim]);
    pvals = reshape(pvals,[npx I.nStim]);
    
    tm = blankFrame; pm = blankFrame;
    for s = 1:I.nStim
        tm(I.roiMaskIdx) = tstat(:,s);
        pm(I.roiMaskIdx) = pvals(:,s);

        tMap(:,:,s,pid) = tm;
        pMap(:,:,s,pid) = pm;
    end
        
    fprintf(' done\n')
end







