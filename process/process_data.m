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

km = 0;

kjoint  = nan(10,4,2,15);
kmuscle = nan(10,4,2,15);
vjoint  = nan(10,4,2,15);
Tjoint  = nan(10,4,2,15);
Ajoint  = nan(10,4,2,15);

FL         = nan(10,4,2,15);
SOLact     = nan(10,4,2,15);
TAact      = nan(10,4,2,15);
GASact     = nan(10,4,2,15);

Ps = flip('L':'Z');

load('MVC.mat', 'MVC', 'Tmax');
color = turbo(10);

%%
for kk = 1:15 % participants
    
    disp(Ps(kk))
    
    
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
                
                if isfield(data(k), 'FL')
                    fid = isfinite(data(k).FL);
                    fdata(k).FL(fid)     = filtfilt(b,a,data(k).FL(fid));
                end
                
                % synchronize
                tid = find((fdata(k).angle-phi0(k)) > 2,1);
                
                if ~isempty(tid)
                    dt = data(k).t(tid);
                    fdata(k).t = data(k).t - dt;
                    
                    % select intervals
                    id_prior = fdata(k).t > -.1 & fdata(k).t < 0;
                    id_SRS  = fdata(k).t > 0 & fdata(k).t < .02;
                    
                    if kk == 10
                        figure(km)
                        set(gcf, 'name', trialname)
                        data_plot(fdata(k), 1:length(fdata(k).t), color(k,:))
                    end
                    
                    legend('1', '2', '3', '4', '5','6', '7', '8', '9', '10')
        
                    % compute stiffnesses
                    p1 = polyfit(fdata(k).angle(id_SRS), fdata(k).torque(id_SRS), 1);
                    
                    if isfield(fdata(k), 'FL')
                        p2 = polyfit(fdata(k).FL(id_SRS), fdata(k).torque(id_SRS), 1);
                    end
                    
                    % save summary terms
                    if isfield(fdata(k), 'FL')
                        FL(k,m,n,kk)    = mean(fdata(k).FL(id_prior,1));
                    end
                    
                    TAact(k,m,n,kk)    = mean(fdata(k).EMG(id_prior,1));
                    SOLact(k,m,n,kk)   = mean(fdata(k).EMG(id_prior,2));
                    GASact(k,m,n,kk)   = mean(fdata(k).EMG(id_prior,3));
                    
                    Ajoint(k,m,n,kk) = mean(fdata(k).angle(find(id_SRS,1)));
                    Tjoint(k,m,n,kk) = mean(fdata(k).torque(find(id_SRS,1)));
                    vjoint(k,m,n,kk) = mean(fdata(k).velocity(find(id_SRS,1)));
                    kjoint(k,m,n,kk) = p1(1);
                    
                    if isfield(fdata(k), 'FL')
                        kmuscle(k,m,n,kk) = p2(1);
                    end
                end
            end
        end
    end
end



%% remove some data
% p3 soleus looks bad
SOLact(:,:,:,3) = nan;

%% average over repetitions
Kj = squeeze(mean(kjoint,1,'omitnan'));
Km = squeeze(mean(kmuscle,1,'omitnan'));

Aj = squeeze(mean(Ajoint,1,'omitnan'));
Tj = squeeze(mean(Tjoint,1,'omitnan'));
vj = squeeze(mean(vjoint,1,'omitnan'));
Lj = squeeze(mean(FL,1,'omitnan'));

TA = squeeze(mean(TAact,1,'omitnan'));
SOL = squeeze(mean(SOLact,1,'omitnan'));
GAS = squeeze(mean(GASact,1,'omitnan'));

%% summary figure
colors = parula(15);
if ishandle(km+1), close(km+1); end
figure(km+1)

subplot(421)
for i = 1:size(SOL,3)
    plot(angs, SOL(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
end

plot(angs, mean(SOL,3,'omitnan'), '-o')
title('SOL')

subplot(422)
for i = 1:size(GAS,3)
    plot(angs, GAS(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
end

plot(angs, mean(GAS,3,'omitnan'), '-o'); hold on
% plot(angs, squeeze(TA), '--')
title('GAS')

subplot(423)
for i = 1:size(Aj,3)
    plot(angs, Aj(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
end
plot(angs, mean(Aj,3,'omitnan'), '-o')
title('Angle')

subplot(424)
for i = 1:size(vj,3)
    plot(angs, vj(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
end
plot(angs, mean(vj,3,'omitnan'), '-o')
title('Speed')

subplot(425)
for i = 1:size(Tj,3)
    plot(angs, Tj(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
end
plot(angs, mean(Tj,3,'omitnan'), '-o')
title('Torque')

subplot(426)
for i = 1:size(Kj,3)
    plot(angs, Kj(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
end
plot(angs, mean(Kj,3,'omitnan'), '-o')
title('Joint stiffness')

subplot(427)
for i = 1:size(Km,3)
    plot(angs, Km(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
end
plot(angs, mean(Km,3,'omitnan'), '-o')
title('Muscle stiffness')

subplot(428)
for i = 1:size(Lj,3)
    plot(angs, Lj(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
end
plot(angs, mean(Lj,3,'omitnan'), '-o')
title('Muscle length')




