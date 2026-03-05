vs = [30, 270, 350];

vs = [30, 120, 210];

close all
cd('C:\Users\u0167448\Documents\GitHub\analyze_biodex_data')

fs = 1000;

for i = 1:length(vs)
    c3d = ezc3dRead(['pilot_s', num2str(vs(i)), '.c3d']);

    % Check available analog channels
    analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

    % Read analog data
    analogData = c3d.data.analogs;  % [samples × channels]

    N = length(analogData);
    t = 0:(1/fs):(N-1)*(1/fs);
    
    figure(i)
    subplot(311)
    plot(t, -analogData(:,17)); hold on
    ylabel('Angle')
    xlabel('Time (s)')
    
    subplot(312)
    plot(t, analogData(:,18)); hold on
    ylabel('Velocity')
    xlabel('Time (s)')
    
    subplot(313)
    plot(-analogData(:,17), -analogData(:,20), '.'); hold on
    yline(0, 'k-')
    ylabel('Torque')
    xlabel('Angle')

    Tm(i) = mean(-analogData(:,20));
    
    for j = 1:3
        subplot(3,1,j)
        box off
    end
end

%% energetics

cd('D:\data_29_01_2026\Cosmed')

filename = 'P1 ES 20260129 CPET BxB_20260129123002';

data = readmatrix([filename, '.xlsx']);
data2 = readmatrix([filename, '.xlsx'], 'OutputType', 'datetime');    
VO2 = data(:,15);

t = (second(data2(:,10)) + 60*minute(data2(:,10))) / 60;


%%
clc

tstart = [0 7 15 23 31 39 47];
tstop = tstart + 5;

tlin = linspace(0,max(t), 1000);
VO2i = interp1(t(isfinite(t)), VO2(isfinite(t)), tlin);

if ishandle(10), close(10); end
figure(10)
plot(t, VO2); hold on
plot(tlin, VO2i, 'linewidth',1)
plot(t, movmean(VO2,50), 'linewidth',2)
ylabel('VO2 (mL/min)')
xlabel('Time (min)')

VO2a = nan(1, length(tstart));
for i = 1:length(tstart)
    xline(tstart(i),'k--')
    xline(tstop(i),'r--')
    
    VO2a(i) = mean(VO2i(tlin>tstart(i)+3 & tlin<tstop(i)));
    VO2a2(i) = mean(VO2(t>tstart(i)+3 & t<tstop(i)));
    
    plot([tstart(i) tstop(i)], [VO2a(i) VO2a(i)], 'k--', 'linewidth', 2)
    
end


%%
vs = [50 100 150 200 -50 -100];
if ishandle(2), close(2); end

color = lines(1);

figure(2)
plot(vs, (VO2a(2:end)),'o', 'markerfacecolor', color(1,:)); hold on
yline(VO2a(1), 'k--')
xlabel('Knee angular velocity (deg/s)')
box off
ylim([0 600])
ylabel('VO_2 (mL/min)')
% plot(vs, (VO2a2(2:end)-VO2a2(1)),'o')


