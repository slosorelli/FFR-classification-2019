% losorelli_14_analyzePerceptualData.m
% ---------------------------------------
% This script analyzes the perceptual responses (reported in Figure 5 and 
% Supplementary Figure S5). Each participant's perceptual test produced a 
% .csv file containing reported and actual stimulus labels for each trial. 
% The first part of the script converts each .csv to a confusion matrix, 
% and subsequently computes individual-participant and aggregate 
% accuracies. The second part of the script conducts the permutation test 
% (computation of confusion matrices 1,000 times with actual labels 
% shuffled independently of reported labels) and saves out a .mat file. 
% Permutation testing should take seconds to run. In the third and final 
% part of the script, the intact and permutation-test results are loaded, 
% and the p-value is computed.
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

inDir = '../Data/PerceptualData';
outDir = '../../ClassifierOutput';

cd(inDir)
fList = dir('*.csv');
nFiles = length(fList);
fNames = {fList.name}

classOrder = 1:6;
nClass = length(classOrder);

%% Part 1: Compute confusion matrices and accuracies (intact) and save

% Initialize C as empty struct array with nFiles entries
c = struct('CM', NaN, 'accuracy', NaN);
C = repmat(c, nFiles, 1);

for f = 1:nFiles
    
    currFn = fNames{f};
    disp(['File ' num2str(f) ': Loading ' currFn '.']);
    thisData = csvread(currFn, 1, 0);
    thisActualLabels = thisData(:,2);
    thisPredictedLabels = thisData(:,3);
    
    % Remove missing or multiple responses
    badResponses = find(thisPredictedLabels==0);
    thisPredictedLabels(badResponses) = [];
    thisActualLabels(badResponses) = [];
    
    % Compute the CM
    thisCM = confusionmat(thisActualLabels, thisPredictedLabels,...
        'Order', classOrder)
    thisAcc = trace(thisCM) / sum(thisCM(:)) * 100
    
    % Add to struct
    C(f).CM = thisCM;
    C(f).accuracy = thisAcc;
    
    clear this*
end

% Save output
cd(outDir)
fnOutIntact = ['losorelli_14_analyzePerceptualData_intact_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutIntact, 'C')

%% Part 2: Compute confusion matrices and accuracies (permuted) and save

clear C
nPerm = 1000;

% Initialize C as empty struct array with nFiles x nPerm entries
c = struct('CM', NaN, 'accuracy', NaN);
C = repmat(c, nFiles, nPerm);

% Outer loop iterates through participants
permTic = tic;
for f = 1:nFiles
    
    disp(['****** Permutation tests: File ' num2str(f) '. ******'])
    
    cd(inDir)
    currFn = fNames{f};
    disp(['File ' num2str(f) ': Loading ' currFn '.']);
    thisData = csvread(currFn, 1, 0);
    thisActualLabels = thisData(:,2);
    thisPredictedLabels = thisData(:,3);
    
    % Remove missing or multiple responses
    badResponses = find(thisPredictedLabels==0);
    thisPredictedLabels(badResponses) = [];
    thisActualLabels(badResponses) = [];
    
    for j = 1:nPerm
        
        actualPerm = thisActualLabels(randperm(length(thisActualLabels)));
        
        % Compute the CM
        thisCM = confusionmat(actualPerm, thisPredictedLabels,...
            'Order', classOrder);
        thisAcc = trace(thisCM) / sum(thisCM(:)) * 100
        
        % Add to struct
        C(f, j).CM = thisCM;
        C(f, j).accuracy = thisAcc;
        
    end
    
    clear this*
end
toc(permTic)

% Save output
cd(outDir)
fnOutPerm = ['losorelli_14_analyzePerceptualData_permuted_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutPerm, 'C')

%% Part 3: Compute the p-value

cd(outDir)
clearvars -except fnOut* nPerm nFiles
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

pIndividuals = nan(nFiles, 1);

for i = 1:nFiles
   thisIntact = Intact.C(i).accuracy;
   thisPerm = [Permuted.C(i,:).accuracy]; % 1 x nPerm vector
   pIndividuals(i) = permTestPVal(thisIntact, thisPerm, 1);
   clear this*
end
