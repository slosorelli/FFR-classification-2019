% losorelli_03_classifyTimeDomainCV.m
% -------------------------------------
% This script performs the classification analysis of 100-sweep averaged
% trials (described in the body of the manuscript). Loaded data are
% 100-sweep averaged trials, epoched from 5-145 msec relative to stimulus
% onset. Classification is performed across participants using 10-fold
% cross validation, LDA, and dimensionality reduction using PCA (components
% retained to explain 99% of the variance). The first part of the script
% runs the classification and saves out a .mat file. The second part of the
% script conducts the permutation test (1,000 classifications with labels
% shuffled independently of data observations) and saves out a .mat file.
% Permutation testing can take up to several hours to run. In the third and
% final part of the script, the intact and permutation-test classification
% results are loaded, and the p-value is computed.
%
% The script requires the MatClassRSA toolbox to be already installed and
% added to the path: https://github.com/berneezy3/MatClassRSA

% Copyright (c) 2019 Steven Losorelli and Blair Kaneshiro
%
% This work is licensed under the Creative Commons Attribution 4.0 
% International License. To view a copy of this license, visit 
% http://creativecommons.org/licenses/by/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

clear all; close all; clc
rng('shuffle');

inDir = '../Data';
outDir = '../ClassifierOutput';

% Load 100s .mat (data X, labels Y)
cd(inDir)
load('losorelli_100sweep_epoched.mat');

%% Part 1: Classify 100s (intact) and save output

C = classifyCrossValidate(X, Y, 'classify', 'LDA', 'NFolds', 10,...
    'PCA', 0.99);

% Save output
cd(outDir)
fnOutIntact = ['losorelli_03_classifyTimeDomainCV_100s_intact_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutIntact, 'C')

%% Part 2: Classify 100s (permuted) and save output

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
fnOutPerm = ['losorelli_03_classifyTimeDomainCV_100s_permuted_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutPerm, 'C');

%% Part 3: Compute the p-value

cd(outDir)
clearvars -except fnOut*
Intact = load(fnOutIntact);
Permuted = load(fnOutPerm);
pVal = permTestPVal(Intact.C.accuracy, [Permuted.C.accuracy], 1)
