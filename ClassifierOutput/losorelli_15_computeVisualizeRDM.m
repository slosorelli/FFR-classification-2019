% losorelli_15_computeVisualizeRDM.m
% --------------------------------------
% This script is illustrative of the confusion matrix and dendrogram plots 
% done for figure 2A. Specifically, it plots the classifier output for
% time-domain 500s .mat pseudo-trials. Note that the user needs
% to specify the input filenames for creating the visualizations.
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
addpath(genpath('misc'));
outputDir = '../ClassifierOutput';

%% Calculate RDM and plot time- and frequency-domain results (CM and dendrogram)

%load output data for time-domain 500s .mat classification
cd(outputDir)
load('losorelli_04_classifyTimeDomainCV_500s_intact_20190326_2004')


% load colors reference file
load('colors.mat', 'rgb10');

stimNames = {'ba', 'da', 'di', 'piano', 'bassoon', 'tuba'};
colorStim = {rgb10(1,:), rgb10(2,:), rgb10(3,:), rgb10(4,:), rgb10(5,:), rgb10(6,:)};

%compute RDM for dendrogram
RDM = computeRDM(C.CM);

% calc CM in percentages
CM = C.CM;
CM_perc = (diag(1./sum(CM,2))*CM)*100;


%% Plot CM, Dendrogram

close all
fSize = 12;

figure()

subplot(1,2,1)
clims = [0 100]; %standardize colorbar
imagesc(CM_perc, clims);
cb = colorbar;
cb.Label.String = '% classified'; cb.Label.FontSize = fSize; cb.Label.FontWeight = 'bold';
textStrings = num2str(CM_perc(:), '%0.1f');
textStrings = strtrim(cellstr(textStrings));
[x,y] = meshgrid(1:6);
hStrings = text(x(:),y(:),textStrings(:), 'HorizontalAlignment', 'center', 'fontSize', fSize);
midValue = mean(get(gca,'Clim'));
textColors = 'white';
textColors = repmat(CM_perc(:) < midValue,1,3);
set(hStrings, {'Color'}, num2cell(textColors,2));

ax = gca;
set(gca, 'XTickLabel', stimNames, 'YTickLabel', stimNames, 'XAxisLocation', 'top', 'FontSize', fSize)
%ax.XTickLabel{1} = stimNames{1}
ax.XTickLabel{1} = ['\color[rgb]{0.1216, 0.4667, 0.7059}' ax.XTickLabel{1}];
ax.YTickLabel{1} = ['\color[rgb]{0.1216, 0.4667, 0.7059}' ax.XTickLabel{1}];
ax.XTickLabel{2} = ['\color[rgb]{1, 0.498, 0.0549}' ax.XTickLabel{2}];
ax.YTickLabel{2} = ['\color[rgb]{1, 0.498, 0.0549}' ax.XTickLabel{2}];
ax.XTickLabel{3} = ['\color[rgb]{0.1725, 0.6275, 0.1725}' ax.XTickLabel{3}];
ax.YTickLabel{3} = ['\color[rgb]{0.1725, 0.6275, 0.1725}' ax.XTickLabel{3}];
ax.XTickLabel{4} = ['\color[rgb]{0.8392, 0.1529, 0.1569}' ax.XTickLabel{4}];
ax.YTickLabel{4} = ['\color[rgb]{0.8392, 0.1529, 0.1569}' ax.XTickLabel{4}];
ax.XTickLabel{5} = ['\color[rgb]{0.5804, 0.4039, 0.7412}' ax.XTickLabel{5}];
ax.YTickLabel{5} = ['\color[rgb]{0.5804, 0.4039, 0.7412}' ax.XTickLabel{5}];
ax.XTickLabel{6} = ['\color[rgb]{0.5490, 0.3373, 0.2941}' ax.XTickLabel{6}];
ax.YTickLabel{6} = ['\color[rgb]{0.5490, 0.3373, 0.2941}' ax.XTickLabel{6}];

xlabel('Predicted Stimulus', 'FontSize', fSize, 'FontWeight', 'bold');
ylabel('Actual Stimulus', 'FontSize', fSize, 'FontWeight', 'bold');

subplot(1,2,2)
plotDendrogram(RDM, 'nodeColors', colorStim, 'nodeLabels', stimNames,...
    'yLim', [0 1], 'FontSize', fSize, 'lineWidth', 1);
%set(gca, 'fontSize', labelFontSize, 'YAxisLocation', 'right')
ylabel('Distance', 'FontSize', fSize, 'FontWeight', 'bold');



