close all

%% calibration
clc
% load
files = {'s101', 's105'}; % 's106', 's107','s108', 'N-MVC'};
scalefac = [1 1]; %136825 136825 1 1 1 1 136825];

data = struct();
for i = 1:length(files)
    
    cd('C:\Users\u0167448\Documents\Data\SRS\calibration\s1')

    c3d = ezc3dRead([files{i},'.c3d']);

    % Check available analog channels
    analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

    % Read analog data
    analogData = c3d.data.analogs;  % [samples × channels]

    data(i).angle       = analogData(:,17) * 180/pi;
    data(i).velocity    = analogData(:,18) * 180/pi;
    data(i).torque      = -analogData(:,20) * scalefac(i);
end

%%
close all

for i = 1:length(files)
    figure(i)
    subplot(311)
    plot(data(i).angle - data(i).angle(1)); hold on
    
    subplot(312)
    plot(data(i).velocity); hold on
    
    subplot(313)
    plot(data(i).torque); hold on
end

% clear id
% for i = 1:10
%     [id(i,:), ~] = ginput(2);
%     
%     subplot(313)
%     xline(id(i,1), 'k--')
%     xline(id(i,2), 'r--')
%     drawnow
% end

id = [  1428        7813
       17557       30662
       39735       50823
       60904       74681
       90978      116347
      127100      149782
      159358      173975
      183888      194304
      202369      216818
      223370      230763];
    
%% MVC trials
Tm = nan(1,9);
for i = 1:9
    Tm(i) = mean(data(1).torque(id(i,1):id(i,2)));
end

dTm = Tm-Tm(1);

w = (25.07 + 24.99) * 0.453592; % [kg]
F = w * 9.81;
r = 2.54 * (0:8) / 100;
Tr = F * r;

close all
figure(1)

plot(dTm,Tr, 'o')

p = polyfit(dTm,Tr, 1);
hold on

x = 0:max(Tm);
plot(x, polyval(p, x),'--')

xlabel('Gemeten moment (N-m)')
ylabel('Daadwerkelijke moment (N-m)')
box off

plot(x,x,'k-')
axis equal
axis([0 max(Tm) 0 max(Tm)])
