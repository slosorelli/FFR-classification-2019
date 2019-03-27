% losorelli_04_classifyTimeDomainCV_500s.m
% -------------------------------------------
% This script performs the classification analysis of 500-sweep averaged
% pseudotrials (reported in Figure 2A). Loaded data are 500-sweep averaged
% pseudotrials, epoched from 5-145 msec relative to stimulus onset.
% Classification is performed across participants using 10-fold cross
% validation, LDA, and dimensionality reduction using PCA (components
% retained explain 99% of the variance). The first part of the script
% runs the classification and saves out a .mat file. The second part of the
% script conducts the permutation test (1,000 classifications with labels
% shuffled independently of data observations) and saves out a .mat file.
% Permutation testing can take over one hour to run. In the third and
% final part of the script, the intact and permutation-test classification
% results are loaded, and the p-value is computed.
%
% The script requires the MatClassRSA toolbox to be already  installed and
% added to the path: https://github.com/berneezy3/MatClassRSA

% TODO: Re-add license info

clear all; close all; clc
rng('shuffle');

% TODO: Update inDir, outDir; delete addpath statement
inDir = '/usr/ccrma/media/projects/jordan/Experiments/ACLS1.2_manuscript/Data';
outDir = '/usr/ccrma/media/projects/jordan/Experiments/ACLS1.2_manuscript/ClassifierOutput';
addpath(genpath( '/usr/ccrma/media/projects/jordan/Experiments/ACLS1.2_manuscript/MatClassRSA-development'))

% Load 500s .mat (data X, labels Y)
cd(inDir)
load('losorelli_500sweep_epoched.mat');

%% Part 1: Classify 500s (intact) and save output

C = classifyCrossValidate(X, Y, 'classify', 'LDA', 'NFolds', 10,...
    'PCA', 0.99);

% Save output
cd(outDir)
fnOutIntact = ['losorelli_04_classifyTimeDomainCV_500s_intact_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutIntact, 'C')

%% Part 2: Classify 500s (permuted) and save output

clear C
nPerm = 1000;

% Initialize C as empty struct array with nPerm entries
c = struct('CM', NaN, 'accuracy', NaN, 'predY', NaN, 'pVal', NaN, 'classifierInfo', NaN);
C = repmat(c, nPerm, 1);

permTic = tic;
for i = 1:nPerm
    
    disp(['****** Permutation iteration ' num2str(i) ' of ' num2str(nPerm) '. ******'])
    
    Y_perm = Y(randperm(length(Y)));
    
    C(i) = classifyCrossValidate(X, Y_perm, 'classify', 'LDA', 'NFolds', 10,...
        'PCA', 0.99);
end
toc(permTic)

% Save output
cd(outDir)
fnOutPerm = ['losorelli_04_classifyTimeDomainCV_500s_permuted_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutPerm, 'C');


%% Part 3: Compute the p-value

cd(outDir)
clearvars -except fnOut*
Intact = load(fnOutIntact);
Permuted = load(fnOutPerm);
pVal = permTestPVal(Intact.C.accuracy, [Permuted.C.accuracy], 1)
