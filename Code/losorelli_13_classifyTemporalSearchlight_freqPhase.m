% losorelli_13_classifyTemporalSearchlight_freqPhase.m
% -------------------------------------------------------
% This script performs temporal searchlight classifications on 500-sweep 
% pseudo-trial averages of data. The pseudo-trials are subset using a 
% 50-msec window which advances in 25-msec increments (50% overlap between 
% windows). For this classification, the data are transformed to the
% frequency domain, and real and imaginary coefficients corresponding to
% positive frequencies up to 1000 Hz are input to the classifier 
% (Supplementary Figure S4). The first part of the script performs the 
% main classification. The second part of the script performs permutation 
% testing. Permutation testing can take one hour or longer to run. Finally, 
% the third part of the script loads the outputs from the previous parts 
% and computes the p-value for each temporal window. Note that multiple 
% comparison correction is not performed here.
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

% Load 500s .mat (data X, labels Y)
cd(inDir)
load('losorelli_500sweep_epoched.mat');

%% Part 1: Classify 500s (intact) and save output

winLenSamp = 400;
winHopSamp = 200;
[nTrial, nTime] = size(X);
nWins = floor((nTime - winLenSamp) / winHopSamp + 1);

% Initialize C as empty struct array with nWins entries
c = struct('CM', NaN, 'accuracy', NaN, 'predY', NaN, 'pVal', NaN, 'classifierInfo', NaN);
C = repmat(c, nWins, 1);

% For visualization, initialize all* variables
allCM = nan(6, 6, nWins); allCP = allCM;
allAcc = nan(nWins, 1); allWins = nan(nWins, winLenSamp);

% Classify the data in each time window
for i = 1:nWins
    
    disp(['****** Classifying window ' num2str(i) ' of ' num2str(nWins) '. ******'])
    
    % Get current time samples
    thisSamp = (i-1) * winHopSamp + (1:winLenSamp);
    allWins(i,:) = thisSamp;
    thisX = X(:, thisSamp); % Temporal subset of data
    
    % Compute frequency-domain features
    thisX_cols = transpose(thisX); % Transpose for FFT
    thisX_fft = fft(thisX_cols);
    fs = 20000;
    fax = linspace(0, fs, size(thisX_fft, 1));
    idx1000 = find(fax <= 1000);
    thisX_1000 = thisX_fft(idx1000, :); % Data points <= 1000 Hz
    
    % Get magnitude
    thisX_phase = angle(thisX_1000);
    
    % Transpose back to trial-by-feature
    thisX_use = transpose(thisX_phase);
    
    % Classify
    C(i) = classifyCrossValidate(thisX_use, Y, 'classify', 'LDA',...
        'NFolds', 10, 'PCA', 0.99);
    
    % Store visualization information
    thisCP = computeRDM(C(i).CM, 'normalize', 'diagonal',...
        'symmetrize', 'geometric', 'distance', 'linear', 'rankdistances', 'none');
    allCM(:, :, i) = C(i).CM;
    allCP(:, :, i) = thisCP;
    allAcc(i) = C(i).accuracy;
    clear this*
    
end

% Save output
cd(outDir)
fnOutIntact = ['losorelli_13_classifyTemporalSearchlight_freqPhase_intact_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutIntact, 'C', 'all*')

%% Part 2: Classify 500s (permuted) and save output

clear C all*
nPerm = 1000;

% Initialize C as empty struct array with nWins x nPerm entries
c = struct('CM', NaN, 'accuracy', NaN, 'predY', NaN, 'pVal', NaN, 'classifierInfo', NaN);
C = repmat(c, nWins, nPerm);

% Outer loop iterates through time windows
for i = 1:nWins
    
    disp(['****** Classifying window ' num2str(i) ' of ' num2str(nWins) '. ******'])
    
    % Get current time samples
    thisSamp = (i-1) * winHopSamp + (1:winLenSamp);
    allWins(i,:) = thisSamp;
    thisX = X(:, thisSamp); % Temporal subset of data
    
    % Compute frequency-domain features
    thisX_cols = transpose(thisX); % Transpose for FFT
    thisX_fft = fft(thisX_cols);
    fs = 20000;
    fax = linspace(0, fs, size(thisX_fft, 1));
    idx1000 = find(fax <= 1000);
    thisX_1000 = thisX_fft(idx1000, :); % Data points <= 1000 Hz
    
    % Get magnitude
    thisX_phase = angle(thisX_1000);
    
    % Transpose back to trial-by-feature
    thisX_use = transpose(thisX_phase);
    
    % Innter loop contains permutation iterations for window i
    for j = 1:nPerm
        
        Y_perm = Y(randperm(length(Y)));
        
        % Classify
        C(i, j) = classifyCrossValidate(thisX_use, Y_perm, 'classify', 'LDA',...
            'NFolds', 10, 'PCA', 0.99);
        C(i, j).classifierInfo = NaN;
        
    end
    
    clear this*
    
end

% Save output
cd(outDir)
fnOutPerm = ['losorelli_13_classifyTemporalSearchlight_freqPhase_permuted_' datestr(now, 'yyyymmdd_HHMM') '.mat']
save(fnOutPerm, 'C')

%% Part 3: Compute the p-value

cd(outDir)
clearvars -except fnOut* nPerm nWins
Intact = load(fnOutIntact);
Permuted = load(fnOutPerm);

%% Compute a separate p-value for each time window

pWins = nan(nWins, 1);

for i = 1:nWins
    thisIntact = Intact.C(i).accuracy;
    thisPerm = [Permuted.C(i,:).accuracy]; % 1 x nPerm vector
    pWins(i) = permTestPVal(thisIntact, thisPerm, 1);
    disp(['Win ' num2str(i) ': intact acc ' num2str(thisIntact) ', max perm ' num2str(max(thisPerm)) '.'])
    clear this*
end