% losorelli_15_computeVisualizeRDM.m
% --------------------------------------
% This script loads output data and computes a CM and Dendrogram for the
% results. First, the entire epoched 100/500s .mat files are loaded and the
% results are plotted. Next, temporal searchlight analyses are visualized
% for the corresponding searchlight output data. 
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

outputDir = '../ClassifierOutput';

%% Calculate RDM and plot time- and frequency-domain results (CM and dendrogram)

%load output data you wish to visualize
cd(outputDir)
load('losorelli_output_7a_PerceptualCMs') % CHANGE TO OUTPUT OF INTEREST TO VISUALIZE

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
fSize = 15;

make_it_tight = true;
subplot = @(m,n,p) subtightplot (m, n, p, [0.01 0.05], [0.07 0.07], [0.1 0.1]);
if ~make_it_tight,  clear subplot;  end

figure()

subplot(1,2,1)
clims = [0 100]; %standardize colorbar
imagesc(CM_perc, clims);
cb = colorbar;
cb.Label.String = '% classified'; cb.Label.FontSize = fSize; cb.Label.FontWeight = 'bold';
textStrings = num2str(CM_perc(:), '%0.2f');
textStrings = strtrim(cellstr(textStrings));
[x,y] = meshgrid(1:6);
hStrings = text(x(:),y(:),textStrings(:), 'HorizontalAlignment', 'center', 'fontSize', 12);
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
    'yLim', [-0.25 1])
set(gca, 'fontSize', fSize, 'YAxisLocation', 'right')
ylabel('distance', 'FontSize', fSize, 'FontWeight', 'bold');

%% Plot searchlight classification results 

%load output data
cd(outputDir)
load('losorelli_output_6a_timeDomainTemporalSearchlight')

Fs = 20000;

% Create time axis out of window midpoints (msec)
windowMidptMsec = mean(allWins-1, 2) / Fs * 1000;


close all; figure(); hold on; box off; 
set(gca, 'fontsize', 16)
% Plot time-resolved accuracies for each category as percentages
for i = 1:6
   plot(windowMidptMsec, squeeze(allCP(i,i,:))*100, '*-', 'linewidth', 2)
end

% Plot time-resolved mean accuracy (across categories) as percentages
plot(windowMidptMsec, allAcc*100, '-*k', 'linewidth', 4)
grid on
legend({'ba', 'da', 'di', 'piano', 'bassoon', 'tuba', 'Mean'}, 'location', 'northeast')
xlabel('Time (msec)'); ylabel('Classifier accuracy (%)')
xlim([0 200])
