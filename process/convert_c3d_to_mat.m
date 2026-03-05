clear all; close all; clc

mainfolder = 'C:\Users\u0167448\Documents\Data\SRS\Metingen';
cd(mainfolder)

folders = dir(cd);
scalefac = [35.6838 144049];

data = struct();
c = 0;

% TA, Sol, Gas (from L to Z) ;
EMGid = [9 10 12; 3 13 14; 2 10 12; 9 13 3; 9 13 12; 2 10 14; 9 13 14; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 10 13 12];

acts = [20 30];
angs = 5:10:35;
alfabet = 'a':'j';

Ps = 'L':'Z';
dates = {'2302' '2302' '1812' '1812' '1812' '1712' '1712' '1712' '1712' '1612' '1512' '1012' '1012' '1012' '0412'};

kk = 0;
color = lines(10);

for c = length(Ps)
    
    disp(Ps(c))
    
    subfolder = fullfile(mainfolder, num2str(dates{c}), Ps(c));
    cd(fullfile(subfolder, 'processed'))

    ofiles = dir('*onsets.mat');
    load(ofiles.name, 'id')
    
    for m = 1:length(angs)
        for n = 1:length(acts)
            
            kk = kk+1;
            trialname = [Ps(c), '-', num2str(angs(m)), '-', num2str(acts(n))];
            
            data = struct();
            for o = 1:length(alfabet)
                filename = fullfile(subfolder, [trialname, alfabet(o), '.c3d']);
                
                c3d = ezc3dRead(filename);
                
                % Check available analog channels
                analogLabels = c3d.parameters.ANALOG.LABELS.DATA;
                
                % Read analog data
                analogData = c3d.data.analogs;  % [samples × channels]
                
                dt = 1/1000;
                data(o).t           = (0:dt:(length(analogData)-1)*dt) - id(o,n,m)*dt;
                data(o).EMG         = analogData(:,EMGid(c,:));
                data(o).angle       = analogData(:,17) * scalefac(1);
                data(o).velocity    = analogData(:,18) * scalefac(1);
                data(o).torque      = -analogData(:,20) * scalefac(2);
                
% 
%                 figure(kk)
%                 set(gcf, 'name', trialname)
%                 data_plot(data(o), 1:length(data(o).t), color(o,:));
%                 
            end
            
%             set(gcf, 'units', 'normalized', 'position', [.1 .1 .3 .7])
            
            cd(fullfile(subfolder, 'processed'))
            save([trialname, '.mat'], 'data', 'scalefac', 'dt', 'id')
            
        end
    end
end


