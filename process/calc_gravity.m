clear all; close all; clc
mainfolder = 'C:\Users\u0167448\Documents\Data\SRS\Metingen';
Ps = flip('L':'Z');
dates = flip({'2302' '2302' '1812' '1812' '1812' '1712' '1712' '1712' '1712' '1612' '1512' '1012' '1012' '1012' '0412'});

angs = 5:10:35;
scalefac = [35.6838 144049];

A = nan(length(angs),length(Ps));
T = nan(length(angs), length(Ps));

for c = 1:length(Ps)
    
    disp(Ps(c))
    
    subfolder = fullfile(mainfolder, num2str(dates{c}), Ps(c));
    cd(subfolder)
    
    for j = 1:length(angs)
        file = dir(['*Fz', num2str(angs(j)),'.c3d']);
        disp(file.name)
    
    
        c3d = ezc3dRead(file.name);

        % Check available analog channels
        analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

        % Read analog data
        analogData = c3d.data.analogs;  % [samples × channels]

        dt = 1/1000;
        data.t           = (0:dt:(length(analogData)-1)*dt);

        data.angle       = analogData(:,17) * scalefac(1);

        data.torque      = -analogData(:,20) * scalefac(2);
        
        A(j,c) = mean(data.angle);
        T(j,c) = mean(data.torque);
    end
    
end

%% plot
figure(1)
plot(A, T, 'o-'); hold on

% range
mean(A-A(1,:),2)

cd('C:\Users\u0167448\Documents\GitHub\analyze_biodex_data')
save('Passive.mat', 'A', 'T', 'Ps', 'angs');
    
    