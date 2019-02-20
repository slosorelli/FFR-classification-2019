% classify FFR data
% Steven Losorelli
% ACLS1_2

clear all; close all; clc

inDir = '/Users/slosorelli/Desktop/SEI/ACLS1_2/ABRdata/manuscriptCode/code/data'
cd(inDir) 

%load('aggrResp500_time_FFT_13subs_5to145ms_4096zeroPad_12172018');
load('aggrResp500_time_FFT_lessThan1000Hz_nozeropad_13subs_5to145ms_02052019');

%% load the X matrix (time, FFT, etc.) to classify

currX = X;

Y = round(Y,0);

%% ensure X and Y match along the trial dimension

if ~any(length(Y) == size(currX)) 
    error('length of Y does not correspond to any length of X')
end 


if size(currX,1) ~= length(Y)
    disp('transposing X!')
    currX=currX';
end

%% [CM, accuracy, predY, pVal, classifierInfo, varargout]


[CM, accuracy, ~, pVal, classifierInfo] = crossValidateEEG(currX, Y, 'classify', 'LDA', 'averageTrials', 0, 'NFolds', 10,...
        'PCA', 0.99);% 'shuffleData', 1)%, 'permutations', 1000, 'pValueMethod', 'permuteFullModel');

%%
%[CM, accuracy, ~, pVal, classifierInfo] = classifyEEG(currX, Y, 'classify', 'LDA', 'averageTrials', 0, 'NFolds', 10,...
       % 'PCA', 0.99)%, 'permutations', 1000, 'pValueMethod', 'permuteFullModel');

[CM, accuracy] = classifyEEG(currX, Y, 'classify', 'LDA', 'NFolds', 10)
    

%% save output CM

dataDir = '/Users/slosorelli/Desktop/SEI/ACLS1_2/ABRdata/manuscriptCode/code/classificationData'
cd(dataDir)

save('ClassifierData_angleFFT_5to145ms_500respAvg_13subs_nozeroPad_lessthan1000Hz_02052018', 'CM', 'pVal', 'accuracy', 'classifierInfo');


%save('CM_FFTmagImagReal_FFR_0to140ms_500avg_13subs_20181102', 'CM', 'pVal', 'accuracy', 'classifierInfo');



