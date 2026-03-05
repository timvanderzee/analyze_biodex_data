clear all; close all; clc
cd('C:\Users\u0167448\Documents\Data\SRS\Metingen')
folders = dir(cd);
acts = [20 30];
angs = 5:10:35;

% filter properties
fs = 1000;
Wn = 5/(.5*fs);
Wn2 = [5 400]/(.5*fs);
[b,a] = butter(2, Wn);
[d,c] = butter(2, Wn2);

kk = 0;
km = 0;

kjoint  = nan(10,4,2,15);
vjoint  = nan(10,4,2,15);
Tjoint  = nan(10,4,2,15);
Ajoint  = nan(10,4,2,15);

SOLact     = nan(10,4,2,15);
TAact      = nan(10,4,2,15);
GASact     = nan(10,4,2,15);

color = lines(2);

for i = (length(folders)-2):-1:1
    cd(fullfile(folders(i+2).folder, folders(i+2).name))
    
    subfolders = dir(cd);
    
    for j = 1:length(subfolders)-2
        if subfolders(j+2).isdir
            
            kk = kk + 1;
            disp(kk)
            
            cd(fullfile(subfolders(j+2).folder, subfolders(j+2).name, 'processed'))
           
            for m = 1:length(angs)
                km = km + 1;
                
                for n = 1:length(acts)

                    % load
                    trialname = [subfolders(j+2).name(1), '-', num2str(angs(m)), '-', num2str(acts(n))];                    
                    load([trialname, '.mat'], 'data');

                    for k = 1:10
                        
                        % get the starting angle
                        id = data(k).t < 0;
                        phi0(k) = mean(data(k).angle(id));
                        
                        % filter
                        fdata = data;
                        for mm = 1:3
                            fdata(k).EMG(:,mm) = filtfilt(b,a,abs(filtfilt(d,c,data(k).EMG(:,mm))));
                        end
                        
                        fdata(k).angle      = filtfilt(b,a,data(k).angle);
                        fdata(k).velocity   = filtfilt(b,a,data(k).velocity);
                        fdata(k).torque     = filtfilt(b,a,data(k).torque);
                        
                        % synchronize
                        tid = find((fdata(k).angle-phi0(k)) > 2,1);
                        
                        if ~isempty(tid)
                            dt = data(k).t(tid);
                            fdata(k).t = data(k).t - dt;

                            % select intervals
                            id_prior = fdata(k).t > -.1 & fdata(k).t < 0;
                            id_SRS = fdata(k).t > 0 & fdata(k).t < .05;

                            % plot
%                             figure(km)
%                             data_plot(fdata(k), id_prior, color(n,:)); hold on
%                             data_plot(fdata(k), id_SRS, color(n,:)); hold on

%                             figure(2)
%                             plot(fdata(k).angle(id_SRS), fdata(k).torque(id_SRS)); hold on

                            p = polyfit(fdata(k).angle(id_SRS), fdata(k).torque(id_SRS), 1);

                            % save summary terms
                            TAact(k,m,n,kk)    = mean(fdata(k).EMG(id_prior,1));
                            SOLact(k,m,n,kk)   = mean(fdata(k).EMG(id_prior,2));
                            GASact(k,m,n,kk)   = mean(fdata(k).EMG(id_prior,3));
                            
                            Ajoint(k,m,n,kk) = mean(fdata(k).angle(find(id_SRS,1)));
                            Tjoint(k,m,n,kk) = mean(fdata(k).torque(find(id_SRS,1)));
                            vjoint(k,m,n,kk) = mean(fdata(k).velocity(find(id_SRS,1)));
                            kjoint(k,m,n,kk) = p(1);
                        end
                    end
                end
            end
        end
    end
end

%% compute joint stiffness
kj = mean(mean(kjoint,1,'omitnan'),4);

Aj = mean(mean(Ajoint,1,'omitnan'),4);
Tj = mean(mean(Tjoint,1,'omitnan'),4);
vj = mean(mean(vjoint,1,'omitnan'),4);

TA = mean(mean(TAact,1,'omitnan'),4);
SOL = mean(mean(SOLact,1,'omitnan'),4);
GAS = mean(mean(GASact,1,'omitnan'),4);


