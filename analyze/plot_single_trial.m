clc; clear; close all
% githubfolder = uigetdir('C:\', 'Select GitHub folder');
cd .. 
cd ..
addpath(genpath(cd))

datafolder = uigetdir('C:\', 'Select data folder');
% datafolder = 'C:\Users\u0167448\Documents\Data\0412\Z';
cd(datafolder)


%% do analysis
alfabet = 'a':'z';
nrep = 10;
vs = alfabet(1:nrep);

% sample frequency (Hz)
fs = 1000;

% time
ti = -.1:(1/fs):.1;

% activation (% max)
acts = [20 30];

% joint angles (deg)
phis = [5 15 25 35];

% linetypes and symbols
ls = {':','-'};
ms = {'o', 's'};

% settings
settings.EMG_channel = 12; % channel number
settings.t0int = .05; % seconds
settings.angle_thres = 2; % degrees

% pre-allocate
intData = nan(length(ti), 4, length(vs));

% get some colors
color = lines(7);

% make some figures
for k = 1:length(phis) % loop over angles
    figure(k)
    set(gcf, 'name', ['Angle = ', num2str(phis(k))])
end

for k = 1:length(phis) % loop over angles
    for l = 1:length(acts) % loop over activations
        phi = phis(k);
        
        for i = 1:length(vs)
            
            filename =  ['Y-', num2str(phi), '-',num2str(acts(l)), vs(i),'.c3d'];
            
            if exist(filename, 'file')
                figure(k)
                [t, selData] = analyze_trial(filename, 0, fs, settings, color(l,:));
                
                mps = [1 1 1 -1];
                for j = 1:4
                    intData(:,j,i) = interp1(t, selData(:,j), ti) * mps(j);
                end
            end
        end
        
        %% summary figures
        figure(10)
        color = get(gca, 'colororder');
        
        ylabels = {'Angle','Velocity', 'Activation', 'Torque'};
        for j = 1:4
            subplot(4,1,j)
            plot(ti, mean(intData(:,j,:),3, 'omitnan'), 'color', color(k,:), 'linestyle', ls{l}, 'linewidth', 1.5); hold on
        end
        
        figure(20)
        id = ti < .02 & ti > 0;
        plot(mean(intData(id,1,:),3, 'omitnan')- mean(intData(1,1,:),3, 'omitnan'), (mean(intData(id,4,:),3, 'omitnan')- mean(intData(1,4,:),3, 'omitnan')), 'color', color(k,:), 'marker', ms{l}); hold on
    end
end

%%
figure(10)
% ylims = [-1.2 0.6; 0 2.5e-4; 0 1.2e-3];
for j = 1:4
    subplot(4,1,j)
    xline(0,'k-')
    
    box off
    xlabel('Time (s)')
    ylabel(ylabels{j})
    title(ylabels{j})
end

subplot(413)
ylim([0 2.5e-4])

figure(20)
xlabel('Angle')
ylabel('Torque')
box off

%%
function[t, selData] = analyze_trial(filename,plot_raw, fs, settings, color)

%% get settings
EMG_channel = settings.EMG_channel;
t0int = settings.t0int;
angle_thres = settings.angle_thres;

%% load
% load
c3d = ezc3dRead(filename);

% Check available analog channels
analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

% Read analog data
analogData = c3d.data.analogs;  % [samples × channels]

N = length(analogData(:,17));
dt = 1/fs;
traw = 0:dt:(N-1)*dt;

%% filter
id1 = 1:16; % EMG channels
id2 = 17:21; % Biodex channels

filtData = analogData;

fc = [5 400];
Wn = fc / (fs*.5);
[b,a] = butter(2, Wn, 'bandpass');

for id = id1
    filtData(:,id) = abs(filtfilt(b,a,analogData(:,id)));
end

fc = 10;
Wn = fc / (fs*.5);
[b,a] = butter(2, Wn);

for id = [id1 id2]
    filtData(:,id) = filtfilt(b,a, filtData(:,id));
end

%% sync
ids = [17 18 EMG_channel 20];
g = [110 77746 1];

phi0 = mean(filtData(traw < t0int,ids(1)));
dphi = (filtData(:,ids(1)) - phi0) * g(1);

id = find(dphi > angle_thres, 1);
t = traw - traw(id);

%% plot
selData = filtData(:,ids);
titles = {'Angle', 'Velocity', 'EMG', 'Torque'};

for i = 1:length(ids)
    
    subplot(4,1,i)
    if plot_raw
        plot(t, analogData(:,ids(i))); hold on
    end
    
    plot(t, filtData(:,ids(i)), 'color', color); hold on
    title(titles{i})
    
    xline(0, 'k-')
    box off
    xlabel('Time (s)')
end



end
