% losorelli_02_computePseudotrials.m
% -----------------------------------
% This script loads the .mat file containing aggregated 100-sweep averaged
% trials, epoched from 5-145 msec relative to stimulus onset. The data are
% averaged in groups of 5 trials on a per-participant, per-stimulus basis,
% resulting in 500-sweep averaged pseudo-trials. Pseudo-trials are then 
% saved in a single .mat file. 
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

addpath(genpath('.'))
dataDir = '../Data';
fnIn = 'losorelli_100sweep_epoched.mat';
fnOut = 'losorelli_500sweep_epoched.mat';
cd(dataDir); load(fnIn)

if size(X,1) ~= length(Y) % Make sure data matrix is correct orientation
    disp('transposing X')
    X=X';
end
Y = Y(:); % Make labels vector a column

XIn = X; YIn = Y; PIn = P; 
clear X Y P

%% Perform within-participant averaging

% We average groups of 5 trials to create pseudo-trials. Trials are 
% averaged on a per-stimulus, per-participant basis. In each averaging 
% operation we randomize trial order prior to averaging to remove ordering 
% effects from the data.

nTrials = 5; % How many trials in each pseudo-trial
shuffleBeforeAveraging = 1; % Whether to shuffle data before averaging

% This function averages the trials on a per-stimulus, per-participant
% basis. It outputs the data averaged in pseudo-trials and the
% corresponding labels and participants vectors.
[X, Y, P] = averageTrialsByParticipant(...
    XIn, YIn, PIn, nTrials, shuffleBeforeAveraging);

%% [optional] Save the output in the same directory

save(fnOut, 'X', 'Y', 'P', 't')

