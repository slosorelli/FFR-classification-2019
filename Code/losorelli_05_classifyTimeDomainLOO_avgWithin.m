% losorelli_05_classifyTimeDomainLOO_avgWithin.m
% -------------------------------------------------
% This script performs the leave-one-(participant)-out classification of
% 500-sweep averaged pseudotrials, where pseudotrial averaging of both
% training and test data has been performed within-participant (reported in 
% Figure 2B). Loaded data are 500-sweep averaged pseudotrials, epoched 
% from 5-145 msec relative to stimulus onset. With 13 participants, 
% classification is performed using 13-fold cross validation, LDA, and 
% dimensionality reduction using PCA (components retained explain 99% of 
% the variance). The first part of the script runs the classification and 
% saves out a .mat file. The second part of the script conducts the 
% permutation test (1,000 classification with training labels and test 
% labels shuffled independently of their respective data observations), 
% and saves out a .mat file. Permutation testing can take over one hour to 
% run. In the third and final part of the script, the intact and 
% permutation-test classification results are loaded, and the p-value is 
% computed.
%
% The script requires the MatClassRSA toolbox to be already  installed and
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

% Load 500s (data X, labels Y, participants P)
cd(inDir)
load('losorelli_500sweep_epoched.mat');

%% Part 1: Classify 500s (intact) and save output

nParticipants = 13;

% Initialize C as empty struct array with nParticipants entries
c = struct('CM', NaN, 'accuracy', NaN, 'predY', NaN, 'predictionInfo', NaN);
C = repmat(c, nParticipants, 1);

for i = 1:nParticipants
    
    % Subset training data and labels (all participants except i)
    thisTrainX = X; thisTrainY = Y;
    thisTrainX(P == i, :) = []; % Remove data rows for participant i
    thisTrainY(P == i) = []; % Remove label elements for participant i
    
    % Subset test data and labels (participant i only)
    thisTestX = X(P == i, :); % Retain data rows for participant i
    thisTestY = Y(P == i); % Retain label elements for participant i
    
    M = classifyTrain(thisTrainX, thisTrainY, 'classify', 'LDA',...
        'PCA', 0.99, 'shuffleData', 1);
    
    C(i) = classifyPredict(M, thisTestX, 'actualLabels', thisTestY);
    C(i).predictionInfo = NaN; % Remove value of this field (bulky)
    
    clear this*
end

% Save output
cd(outDir)
fnOutIntact = ['losorelli_05_classifyTimeDomainLOO_avgWithin_intact_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutIntact, 'C')

%% Part 2: Classify 500s (permuted) and save output

clear C
nPerm = 1000;

% Initialize C as empty struct array with nParticipants x nPerm entries
c = struct('CM', NaN, 'accuracy', NaN, 'predY', NaN, 'predictionInfo', NaN);
C = repmat(c, nParticipants, nPerm);

% Outer loop iterates through participants
permTic = tic;
for i = 1:nParticipants
    
    disp(['****** Permutation tests: Participant ' num2str(i) '. ******'])
    
    % Subset training data and labels (all participants except i)
    thisTrainX = X; thisTrainY = Y;
    thisTrainX(P == i, :) = []; % Remove data rows for participant i
    thisTrainY(P == i) = []; % Remove label elements for participant i
    
    % Subset test data and labels (participant i only)
    thisTestX = X(P == i, :); % Retain data rows for participant i
    thisTestY = Y(P == i); % Retain label elements for participant i
    
    % Inner loop contains permutation iterations for test participant i
    for j = 1:nPerm
        
        yTrainPerm = thisTrainY(randperm(length(thisTrainY)));
        yTestPerm = thisTestY(randperm(length(thisTestY)));
        
        M = classifyTrain(thisTrainX, yTrainPerm, 'classify', 'LDA',...
            'PCA', 0.99, 'shuffleData', 1);
        
        C(i, j) = classifyPredict(M, thisTestX, 'actualLabels', yTestPerm);
        C(i, j).predictionInfo = NaN; % Remove value of this field (bulky)
        
    end
    
    clear this*
end
toc(permTic)

% Save output
cd(outDir)
fnOutPerm = ['losorelli_05_classifyTimeDomainLOO_avgWithin_permuted_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutPerm, 'C')

%% Part 3: Compute the p-value

cd(outDir)
clearvars -except fnOut* nPerm nParticipants
Intact = load(fnOutIntact);
Permuted = load(fnOutPerm);

%% P-value based on mean across participants

% To compute the p-value, we are comparing mean accuracy (combined across
% cross-validation folds). While this was returned automatically for
% previous analyses, here we have to extract and store them manually.

intactAccuracy = mean([Intact.C.accuracy])

% Iterate through the permutation iterations and store the mean accuracy
% across participants (cross-validation folds)
permutedAccuracy = nan(nPerm, 1);
for i = 1:nPerm
   temp = [Permuted.C(:, i).accuracy]; % 1 x nParticipants vector
   permutedAccuracy(i) = mean(temp); % Store the mean for this perm iter
   clear temp
end

pAll = permTestPVal(intactAccuracy, permutedAccuracy, 1)

%% P-value for individual participants

% For further elaboration, we can compute p-values on a per-participant
% basis. 

pIndividuals = nan(nParticipants, 1);

for i = 1:nParticipants
   thisIntact = Intact.C(i).accuracy;
   thisPerm = [Permuted.C(i,:).accuracy]; % 1 x nPerm vector
   pIndividuals(i) = permTestPVal(thisIntact, thisPerm, 1);
   clear this*
end
