c3d = ezc3dRead('Z-Fz35.c3d');

% Check available analog channels
analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

% Read analog data
analogData = c3d.data.analogs;  % [samples × channels]

close all
figure(1)
plot(analogData(:,17))

figure(2)
plot(analogData(:,20))