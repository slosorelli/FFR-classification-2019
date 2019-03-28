% losorelli_01_preprocessFFRs.m
% -------------------------------
% This script loads IHS .txt files from each participant and stimulus, 
% parses the content, and writes each file out into a single .mat file. It
% then aggregates these individual .mat files into a single .mat file and 
% saves. Next, files are epoched to retain data from 5-145 msec
% following stimulus onset, each epoch is centered (DC corrected), and the
% aggregated data are saved.
%
% To run this script, the raw .txt files need to be downloaded from full
% data deposit hosted at the Stanford Digital Repository: 
%   Steven Losorelli, Blair Kaneshiro, Gabriella A. Musacchia, Karanvir 
%   Singh, Nikolas H. Blevins, and Matthew B. Fitzgerald (2019). Stanford 
%   Translational Auditory Research Laboratory - Frequency-Following 
%   Response Dataset 1 (STAR-FFR1). Stanford Digital Repository. 
%   Available at: https://purl.stanford.edu/cp051gh0103

% Copyright (c) 2019 Steven Losorelli and Blair Kaneshiro
%
% This work is licensed under the Creative Commons Attribution 4.0 
% International License. To view a copy of this license, visit 
% http://creativecommons.org/licenses/by/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

clear all; close all; clc

%%%%%%%%%%%%%%%%%%%%%%%% Edit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inDir = '' % ADD PATH TO INPUT RAW .TXT FILES
outDir = '' % ADD PATH TO OUTPUT INDIVIDUAL .MAT FILES
timeDir = '' % ADD PATH TO INPUT TIME .MAT FILE 
dataDir = '' % ADD PATH TO AGGREGATED .MAT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load individual .txt and output individual .mat
cd(timeDir)
load alltime.mat %timing information from IHS system

cd(inDir)
fList = dir('*.TXT'); % Note that the search for '.TXT' is case sensitive.
if isempty(fList), error('No files found.'); end
fNames = {fList.name}; % Cell array of filenames
 

% requires function 'extractSubAvgIHSExportFromFile'
for f = 1:length(fList)
   extractSubAvgIHSExportFromFile(inDir, outDir, fNames{f})
end

%% Load individual .mat and aggregate

inDir = outDir; 

stimNames = {'Ba', 'Da', 'Di', 'Piano', 'Bassoon', 'Tuba'};
nStims = length(stimNames);


X = [];
Y = [];
P0 = [];
varToLoad = 'subAvg_uV';
t = allTime;


for i = 1:nStims
    disp(['loading stimulus file ' stimNames{i}])
    flist = dir([ inDir '*' '_' stimNames{i} '.mat']);
    
    for f = 1:length(flist)
        disp(['loading data from file ' flist(f).name])
        currFile = load(flist(f).name, varToLoad);
        currData = currFile.(varToLoad);
        currParticipant = str2num(flist(f).name(10:11));
        X = horzcat(X, currData);
        Y = [Y repmat(i,1,size(currData,2))];
        P0 = [P0 repmat(currParticipant,1,size(currData,2))];
        clear curr*
    end   
end

clear f flist i nStims stimNames varToLoad

% rename participants (for continuous numbering convention)
p = [1 2 3 4 5 6 0 7 8 0 9 10 11 12 0 13];
P = p(P0);

% ensure Y is a vector of integers
Y = round(Y,0);

%% [optional] Save out data for all time (non-epoched data, ~ -20-msec to 180-msec; X, Y, P, t)

cd(dataDir)
save('losorelli_100sweep_alltime.mat', 'X', 'Y', 'P', 't');

%% Epoch data from 5- to 145-msec

msStart= 5; 
msEnd = 145;
idxUse = find(allTime >= msStart & allTime <= msEnd);  
respUse = X(idxUse, :);
X = respUse;
t = allTime(idxUse);

% center the data
X = dcCorrect(X');

%% [optional] Save out epoched data (5- to 145-msec; X, Y, P, t)

cd(dataDir)
save('losorelli_100sweep_epoched.mat', 'X', 'Y', 'P', 't');


