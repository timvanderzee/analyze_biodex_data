clear all; close all; clc
cd ..
addpath(genpath(cd))
mainfolder = uigetdir(); 
cd(mainfolder)

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

Ps = flip('L':'Z');
dates = {'2302' '2302' '1812' '1812' '1812' '1712' '1712' '1712' '1712' '1612' '1512' '1012' '1012' '1012' '0412'};

load('MVC.mat', 'MVC', 'Tmax');
color = turbo(10);

%%
for kk = 1:15 % participants
    
    disp(Ps(kk))
    
%     subfolder = fullfile(mainfolder, num2str(dates{kk}), Ps(kk));
%     cd(fullfile(subfolder, 'processed'))
    
    for m = 1:length(angs) % angles        
        for n = 1:length(acts) % activations
            
            km = km + 1;        
            
            % load
            trialname = [Ps(kk), '-', num2str(angs(m)), '-', num2str(acts(n))];
            load([trialname, '.mat'], 'data');
            
            for k = 1:10 % repetitions
                
                % get the starting angle
                id = data(k).t < 0;
                phi0(k) = mean(data(k).angle(id));
                
                % filter
                fdata = data;
                for mm = 1:3
                    fdata(k).EMG(:,mm) = filtfilt(b,a,abs(filtfilt(d,c,data(k).EMG(:,mm)))) ./ MVC(mm,kk);
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
                    id_SRS = fdata(k).t > 0 & fdata(k).t < .02;
                    
                    if kk == 1
                        figure(km)
                        set(gcf, 'name', trialname)
                        data_plot(fdata(k), 1:length(fdata(k).t), color(k,:))
                    end
                    
                    legend('1', '2', '3', '4', '5','6', '7', '8', '9', '10')
                    % plot
                    %                             figure(km)
                    %                             data_plot(fdata(k), id_prior, color(n,:)); hold on
                    %                             data_plot(fdata(k), id_SRS, color(n,:)); hold on
                    
%                                                 figure(100)
%                                                 plot(fdata(k).angle(id_SRS), fdata(k).torque(id_SRS)); hold on
                    
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



%% remove some data
% p3 soleus looks bad
SOLact(:,:,:,3) = nan;

%% compute joint stiffness
kj = mean(mean(kjoint,1,'omitnan'),4,'omitnan');

Aj = mean(mean(Ajoint,1,'omitnan'),4,'omitnan');
Tj = mean(mean(Tjoint,1,'omitnan'),4,'omitnan');
vj = mean(mean(vjoint,1,'omitnan'),4,'omitnan');

TA = mean(mean(TAact,1,'omitnan'),4,'omitnan');
SOL = mean(mean(SOLact,1,'omitnan'),4,'omitnan');
GAS = mean(mean(GASact,1,'omitnan'),4,'omitnan');

%%
figure(10)
subplot(211)
bar([squeeze(mean(mean(mean(TAact,1,'omitnan'),2),3)) ...
    squeeze(mean(mean(mean(SOLact,1,'omitnan'),2),3))...
    squeeze(mean(mean(mean(GASact,1,'omitnan'),2),3))]);

subplot(212)
bar(squeeze(mean(mean(GASact,1,'omitnan'),2))')
yline(1,'k--')

%%

figure(11)
subplot(321)
plot(angs, squeeze(SOL), '-o')
title('SOL')

subplot(322)
plot(angs, squeeze(GAS), '-o'); hold on
% plot(angs, squeeze(TA), '--')
title('GAS')

subplot(323)
plot(angs, squeeze(Aj), '-o')
title('Angle')

subplot(324)
plot(angs, squeeze(vj), '-o')
title('Speed')

subplot(325)
plot(angs, squeeze(Tj), '-o')
title('Torque')

subplot(326)
plot(angs, squeeze(kj), '-o')
title('Stiffness')




