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
    plot(data(i).angle); hold on
    
    subplot(312)
    plot(data(i).velocity); hold on
    
    subplot(313)
    plot(data(i).torque); hold on
end

% clear id
% for i = 1:3
%     [id(i,:), ~] = ginput(2);
%     
%     subplot(311)
%     xline(id(i,1), 'k--')
%     xline(id(i,2), 'r--')
%     drawnow
% end

idT = [  1428        7813
       17557       30662
       39735       50823
       60904       74681
       90978      116347
      127100      149782
      159358      173975
      183888      194304
      202369      216818
      223370      230763];
  
  idA = [
            2800        7569
       26440       39712
       67915       73306];
%%
Tm = nan(1,9);
for i = 1:9
    Tm(i) = mean(data(1).torque(idT(i,1):idT(i,2)));
end

Am = nan(1,3);
for i = 1:3
    Am(i) = mean(data(2).angle(idA(i,1):idA(i,2)));
end

dAm = Am-Am(1);
dTm = Tm-Tm(1);

% true torque
w = (25.07 + 24.99) * 0.453592; % [kg]
F = w * 9.81;
r = 2.54 * (0:8) / 100;
Tr = F * r;

% true angle
Ar = -([90 60 120] - 90);

figure(10)

subplot(121)
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

subplot(122)
plot(dAm,Ar, 'o')

pA = polyfit(dAm,Ar, 1);
hold on

x = min(dAm):max(dAm);
plot(x, polyval(pA, x),'--')

xlabel('Gemeten hoek (deg)')
ylabel('Daadwerkelijke hoek (deg)')
box off

plot(x,x,'k-')
axis equal
axis([0 max(dAm) 0 max(dAr)])
