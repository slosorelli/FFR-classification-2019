% losorelli_11_classifyTemporalSearchlight_freqComplex.m
% -------------------------------------------------------
% This script blah blah
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
    
    % Get real and imaginary coefficients
    thisX_im = imag(thisX_1000);
    thisX_re = real(thisX_1000);
    
    % Concatenate along the feature (row) dimension
    thisX_reIm = [thisX_re; thisX_im];
    
    % Transpose back to trial-by-feature
    thisX_use = transpose(thisX_reIm);
    
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
fnOutIntact = ['losorelli_11_classifyTemporalSearchlight_freqComplex_intact_' datestr(now, 'yyyymmdd_HHMM') '.mat']
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
    
    % Get real and imaginary coefficients
    thisX_im = imag(thisX_1000);
    thisX_re = real(thisX_1000);
    
    % Concatenate along the feature (row) dimension
    thisX_reIm = [thisX_re; thisX_im];
    
    % Transpose back to trial-by-feature
    thisX_use = transpose(thisX_reIm);
    
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
fnOutPerm = ['losorelli_11_classifyTemporalSearchlight_freqComplex_permuted_' datestr(now, 'yyyymmdd_HHMM') '.mat']
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