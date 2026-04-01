clear all; close all; clc

cd('C:\Users\u0167448\Documents\Data\SRS\Metingen')
folders = dir(cd);
scalefac = [35.6838 144049];

% filter properties
fs = 1000;
Wn = 2/(.5*fs);
Wn2 = [5 400]/(.5*fs);
[b,a] = butter(2, Wn);
[d,c] = butter(2, Wn2);

data = struct();
o = 0;

% TA, Sol, Gas (from L to Z) ; 
id = [9 10 12; 3 13 14; 2 10 12; 9 13 3; 9 13 12; 2 10 14; 9 13 14; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 9 13 12; 10 13 12];

color = lines(2);
visualize = 0;

MVCnames = {'MVC', 'MVCta'};
% MVCnames = {'MVCta'};

Tmax = nan(15,2);
MVC = nan(3,15,2);

for i = (length(folders)-2):-1:1
    cd(fullfile(folders(i+2).folder, folders(i+2).name))
    
    subfolders = dir(cd);
    
    for j = 1:length(subfolders)-2
        if subfolders(j+2).isdir
            
            o = o+1;
            cd(fullfile(subfolders(j+2).folder, subfolders(j+2).name))
            
            for k = 1:length(MVCnames)
                filename = dir(['*', MVCnames{k}, '.c3d']);

                if ~isempty(filename)
                    c3d = ezc3dRead(fullfile(filename.folder, filename.name));

                    % Check available analog channels
                    analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

                    % Read analog data
                    analogData = c3d.data.analogs;  % [samples × channels]

                    dt = 1/1000;
                    data(o).t           = (0:dt:(length(analogData)-1)*dt);

                    data(o).EMG         = analogData(:,id(o,:));
                    data(o).angle       = analogData(:,17) * scalefac(1);
                    data(o).velocity    = analogData(:,18) * scalefac(1);
                    data(o).torque      = -analogData(:,20) * scalefac(2);

                    % filter
                    fdata = data;
                    for mm = 1:3
                        fdata(o).EMG(:,mm) = filtfilt(b,a,abs(filtfilt(d,c,data(o).EMG(:,mm))));
                    end

                    fdata(o).angle      = filtfilt(b,a,data(o).angle);
                    fdata(o).velocity   = filtfilt(b,a,data(o).velocity);
                    fdata(o).torque     = filtfilt(b,a,data(o).torque);

                    if k == 1
                        [Tmax(o,k), maxid] = max(fdata(o).torque-fdata(o).torque(1));
                    else
                        [Tmax(o,k), maxid] = min(fdata(o).torque-fdata(o).torque(1));
                    end
                    
%                     if o == 2
%                         keyboard
%                     end
                    MVC(:,o,k) = fdata(o).EMG(maxid-200,:);

                    if visualize
                        figure(o)
                        set(gcf, 'name', filename.name(1))

                        data_plot(data(o), 1:length(data(o).t), color(1,:));
                        data_plot(fdata(o), 1:length(data(o).t), color(2,:));

                        for ii = 1:6
                            subplot(3,2,ii)
                            xline(fdata(o).t(maxid),'k--')
                            xline(fdata(o).t(maxid-100),'r-')
                        end
                    end
                else
                    disp(['Does not exist: ', subfolders(j+2).name, MVCnames(k)])
                end
            end
        end
    end
end

%% combine
MVCc = [MVC(1,:,2); MVC(2:3,:,1)];

%%
cd('C:\Users\u0167448\Documents\GitHub\analyze_biodex_data')
save('MVC.mat', 'MVC', 'Tmax', 'MVCc')