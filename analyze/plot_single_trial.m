clc
clear
close all

cd('C:\Users\u0167448\Documents\Data\adrien(angle-EMG)')

vs = 'abcde';

ti = -.1:.001:.1;

acts = [20 40];
phis = [5 25 45];

ls = {':','-'};

for l = 1:length(acts)
    
for k = 1:length(phis)
    figure(k)
    phi = phis(k);

for i = 1:length(vs)
    filename =  [num2str(phi), '-',num2str(acts(l)), vs(i),'.c3d'];
    
    [t, selData] = analyze_trial(filename, 0);
    
    mps = [1 1 1 -1];
    for j = 1:4
        intData(:,j,i) = interp1(t, selData(:,j), ti) * mps(j);
    end
    
end

%% 
figure(10)
color = get(gca, 'colororder');

ylabels = {'Angle','Velocity', 'Activation', 'Torque'};
for j = 1:4
    subplot(1,4,j)
    plot(ti, mean(intData(:,j,:),3), 'color', color(k,:), 'linestyle', ls{l}, 'linewidth', 1.5); hold on


end
end
end

%%
figure(10)
% ylims = [-1.2 0.6; 0 2.5e-4; 0 1.2e-3];
for j = 1:4
    subplot(1,4,j)
    xline(0,'k-')
    
    box off
    xlabel('Time (s)')
    ylabel(ylabels{j})
    title(ylabels{j})
end

legend('5','25','45', 'location', 'best')
legend boxoff

subplot(143)
ylim([0 2.5e-4])

%%
function[t, selData] = analyze_trial(filename,plot_raw)

%% load
c3d = ezc3dRead(filename);

% Check available analog channels
analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

% Read analog data
analogData = c3d.data.analogs;  % [samples × channels]

N = length(analogData(:,17));
fs = 2000;
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

fc = 20;
Wn = fc / (fs*.5);
[b,a] = butter(2, Wn);

for id = [id1 id2]
    filtData(:,id) = filtfilt(b,a, filtData(:,id));
end

%% sync
ids = [17 18 2 20];
g = [110 77746 1];

phi0 = mean(filtData(traw < .05,ids(1)));
dphi = (filtData(:,ids(1)) - phi0) * g(1);

id = find(dphi > 3, 1);
t = traw - traw(id);

%% plot
selData = filtData(:,ids);

for i = 1:length(ids)

    subplot(4,1,i)
    if plot_raw
        plot(t, analogData(:,ids(i))); hold on
    end
    
    plot(t, filtData(:,ids(i))); hold on
    
    xline(0, 'k-')
    box off
end



end
