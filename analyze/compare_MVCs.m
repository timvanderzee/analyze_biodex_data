clear all; close all; clc

cd('C:\Users\u0167448\Documents\Data\SRS\Metingen')
folders = dir(cd);
scalefac = 144049;

data = struct();
c = 0;

% TA, Sol, Gas (from L to Z) ; 
id = [9 10 12; 3 13 14; 2 10 12; 9 13 3; 9 13 12; 2 10 14; 9 13 14; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 10 13 12];

for i = (length(folders)-2) %:-1:1
    cd(fullfile(folders(i+2).folder, folders(i+2).name))
    
    subfolders = dir(cd);
    
    for j = 1:length(subfolders)-2
        if subfolders(j+2).isdir
            
            c = c+1;
            cd(fullfile(subfolders(j+2).folder, subfolders(j+2).name))
            
            filename = dir('*MVC.c3d');
            
            c3d = ezc3dRead(fullfile(filename.folder, filename.name));

            % Check available analog channels
            analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

            % Read analog data
            analogData = c3d.data.analogs;  % [samples × channels]

            data(c).EMG         = analogData(:,id(c,:));
            data(c).angle       = analogData(:,17) * 180/pi;
            data(c).velocity    = analogData(:,18) * 180/pi;
            data(c).torque      = -analogData(:,20) * scalefac;
            
            figure(c)
            set(gcf, 'name', filename.name(1))
           
            subplot(4,1,1)
            plot(data(c).torque); hold on
            
            for k = 1:3
                subplot(4,1,k+1)
                plot(data(c).EMG(:,k)); hold on
                title(num2str(k))
            end
            
            set(gcf, 'units', 'normalized', 'position', [.1 .1 .3 .7])
            
        end
    end
end

%%
for k = 1:15
    Tmax(k) = max(data(k).torque);
end
