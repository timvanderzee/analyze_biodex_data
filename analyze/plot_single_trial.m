clc
clear
close all

filename =  '5-20a.c3d';
foldername = which('plot_single_trial');

[pathRepoFolder,~,~] = fileparts(foldername);

cd(pathRepoFolder)
cd ..
addpath(genpath(cd))
cd('Data')
%%
c3d = ezc3dRead(filename);

% Check available analog channels
analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

% Read analog data
analogData = c3d.data.analogs;  % [samples × channels]

N = length(analogData(:,17));
dt = 1/1000;
traw = 0:dt:(N-1)*dt;

%% plot
figure(1)

subplot(211)
plot(traw, analogData(:,2))

subplot(212)
plot(traw, analogData(:,20))
