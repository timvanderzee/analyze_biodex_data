clear all; close all; clc

cd('C:\Users\u0167448\Documents\Data\SRS\Metingen')
folders = dir(cd);
scalefac = [35.6838 144049];

data = struct();
c = 0;

% TA, Sol, Gas (from L to Z) ; 
EMGid = [9 10 12; 3 13 14; 2 10 12; 9 13 3; 9 13 12; 2 10 14; 9 13 14; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 10 13 12];

acts = [20 30];
angs = 5:10:35;
alfabet = 'a':'j';

kk = 0;
for i = (length(folders)-8) %:-1:1
    cd(fullfile(folders(i+2).folder, folders(i+2).name))
    
    subfolders = dir(cd);
    
    for j = 1:length(subfolders)-2
        if subfolders(j+2).isdir
            
            c = c+1;
            cd(fullfile(subfolders(j+2).folder, subfolders(j+2).name))
            
            cd('processed')
            ofiles = dir('*onsets.mat');
            load(ofiles.name, 'id')

            cd(fullfile(subfolders(j+2).folder, subfolders(j+2).name))
            for m = 1:length(angs)
                for n = 1:length(acts)
                    
                    kk = kk+1;
%                                
                    trialname = [subfolders(j+2).name(1), '-', num2str(angs(m)), '-', num2str(acts(n))];
                    
                    figure(kk)
                    set(gcf, 'name', trialname)
                             
                    data = struct();
                    for o = 1:length(alfabet)
                        filename = fullfile(subfolders(j+2).folder, subfolders(j+2).name, [trialname, alfabet(o), '.c3d']);

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
          

                        subplot(6,1,1)
                        plot(data(o).t, data(o).angle); hold on
                        
                        subplot(6,1,2)
                        plot(data(o).t, data(o).velocity); hold on
                        
                        subplot(6,1,3)
                        plot(data(o).t, data(o).torque); hold on

                        for k = 1:3
                            subplot(6,1,k+3)
                            plot(data(o).t, data(o).EMG(:,k)); hold on
                            title(num2str(k))
                        end

%                     pause
                    end
                    
                    set(gcf, 'units', 'normalized', 'position', [.1 .1 .3 .7])

                    cd(fullfile(subfolders(j+2).folder, subfolders(j+2).name))

                    cd('processed')
                    save([trialname, '.mat'], 'data', 'scalefac', 'dt', 'id')
                    
                end
            end            
        end
    end
end


