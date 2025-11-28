clc
clear
close all

fs = 1000; % gok
dt = 1/fs;

cd('C:\Users\u0167448\Documents\ezc3d_matlab\Data\calibratie')
filename =  ['test1.c3d'];
c3d = ezc3dRead(filename);

% Check available analog channels
analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

% Read analog data
analogData = c3d.data.analogs;  % [samples × channels]

N = length(analogData(:,17));
t = 0:dt:(N-1)*dt;

Wn = 20/(.5*fs);
[b,a] = butter(2, Wn);

% phi = filtfilt(b,a, analogData(:,17)) * scale_fac_omega;
% phidot = filtfilt(b,a, analogData(:,18))  * scale_fac_omega;
tau = filtfilt(b,a, analogData(:,20));


%%
close all

plot(t, analogData(:,20)); hold on
plot(t, tau); hold on


T1 = mean(tau(t<90 & t > 70));
T0 = mean(tau(t>100));

yline(T1,'k--')
yline(T0,'k--')

%% 
m = .65 + 15 + 1.13; % kg
r = .35; % m
MG = m * 9.81 * r;
scale_fac = MG / (T1 - T0);

%%
figure(2)
plot(t, tau*scale_fac)
