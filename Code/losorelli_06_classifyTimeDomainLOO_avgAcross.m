% losorelli_06_classifyTimeDomainLOO_avgAcross.m
% -------------------------------------------------
% This script performs the leave-one-(participant)-out classification of
% 500-sweep averaged pseudotrials, where pseudotrial averaging of training
% data is performed across participant, and pseudotrial averaging of test
% data is performed within-participant (reported in Figure 2C). Loaded 
% data are 100-sweep averaged
% trials (for training partitions) and 500-sweep averaged pseudotrials (for
% test partitions). All data are epoched from 5-145 msec relative to
% stimulus onset. With 13 participants, classification is performed using
% 13-fold cross validation, LDA, and dimensionality reduction using PCA
% (components retained explain 99% of the variance). The first part of the
% script runs the classification and  saves out a .mat file. The second
% part of the script conducts the permutation test (1,000 classification
% with training labels and test labels shuffled independently of their
% respective data observations), and saves out a .mat file. Permutation
% testing can take over one hour to run. In the third and final part of
% the script, the intact and permutation-test classification results are
% loaded, and the p-value is computed.
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

%% Load 100s .mat (X, Y, P) -- used for training partitions
cd(inDir)
load('losorelli_100sweep_epoched.mat');

Xtrain = X; Ytrain = Y; Ptrain = P;

clear X Y P

%% load 500s .mat (X, Y, P) -- used for test partitions

cd(inDir)
load('losorelli_500sweep_epoched.mat');

Xtest = X; Ytest = Y; Ptest = P;

clear X Y P

%% Classify (intact) and save output

% Here, 100-sweep trials are averaged into 500-sweep pseudotrials *across
% participants*, meaning that data from different participants can be
% combined into a single 500-sweep pseudotrial. To do this, we call the
% MatClassRSA 'averageTrials' function on the 100-sweep data that has been
% aggregated across training participants. For testing, however, we pass in
% the 500-sweep precomputed within-participant pseudotrials.

nParticipants = 13;

% Initialize C as empty struct array with nParticipants entries
c = struct('CM', NaN, 'accuracy', NaN, 'predY', NaN, 'predictionInfo', NaN);
C = repmat(c, nParticipants, 1);


for i=1:nParticipants
    
    % Subset training data and labels
    thisTrainX = Xtrain; thisTrainY = Ytrain;
    thisTrainX(Ptrain == i, :) = []; % Remove data rows for participant i
    thisTrainY(Ptrain==i) = []; % Remove label elements for participant i
    
    % Subset test data and labels
    thisTestX = Xtest; thisTestY = Ytest;
    thisTestX = thisTestX(Ptest == i, :); % Retain data rows for participant i
    thisTestY = thisTestY(Ptest == i); % Retain label elements for participant i
    
    % Average training data into 500-sweep averages
    [thisAveragedTrainX, thisAveragedTrainY] = averageTrials(...
        thisTrainX, thisTrainY, 5);
    
    M = classifyTrain(thisAveragedTrainX, thisAveragedTrainY, ...
        'classify', 'LDA', 'PCA', 0.99);
    
    C(i) = classifyPredict(M, thisTestX, 'actualLabels', thisTestY);
    C(i).predictionInfo = NaN; % Remove value of this field (bulky)
    
    clear this*
end

% Save output
cd(outDir)
fnOutIntact = ['losorelli_06_classifyTimeDomainLOO_avgAcross_intact_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutIntact, 'C')

%% Part 2: Classify (permuted) and save output

clear C
nPerm = 1000;

% Initialize C as empty struct array with nParticipants x nPerm entries
c = struct('CM', NaN, 'accuracy', NaN, 'predY', NaN, 'predictionInfo', NaN);
C = repmat(c, nParticipants, nPerm);

% Outer loop iterates through participants
permTic = tic;
for i=1:nParticipants
    
    disp(['****** Permutation tests: Participant ' num2str(i) '. ******'])
    
    % Subset training data and labels
    thisTrainX = Xtrain; thisTrainY = Ytrain;
    thisTrainX(Ptrain == i, :) = []; % Remove data rows for participant i
    thisTrainY(Ptrain==i) = []; % Remove label elements for participant i
    
    % Subset test data and labels
    thisTestX = Xtest; thisTestY = Ytest;
    thisTestX = thisTestX(Ptest == i, :); % Retain data rows for participant i
    thisTestY = thisTestY(Ptest == i); % Retain label elements for participant i
    
    % Average training data into 500-sweep averages
    [thisAveragedTrainX, thisAveragedTrainY] = averageTrials(...
        thisTrainX, thisTrainY, 5);
    
    % Inner loop contains permutation iterations for test participant i
    for j = 1:nPerm
        
        yTrainPerm = thisAveragedTrainY(randperm(length(thisAveragedTrainY)));
        yTestPerm = thisTestY(randperm(length(thisTestY)));
        
        M = classifyTrain(thisAveragedTrainX, yTrainPerm, ...
            'classify', 'LDA', 'PCA', 0.99);
        
        C(i, j) = classifyPredict(M, thisTestX, 'actualLabels', yTestPerm);
        C(i, j).predictionInfo = NaN; % Remove value of this field (bulky)
        
    end
    
    clear this*
end
toc(permTic)

% Save output
cd(outDir)
fnOutPerm = ['losorelli_06_classifyTimeDomainLOO_avgAcross_permuted_' datestr(now, 'yyyymmdd_HHMM') '.mat']
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



