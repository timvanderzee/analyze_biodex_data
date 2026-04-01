clear all; close all; clc
[githubfolder,~,~] = fileparts(which('process_data'));
cd(githubfolder);
cd .. 
addpath(genpath(cd))

% mainfolder = uigetdir(); 
mainfolder = 'C:\Users\u0167448\OneDrive - KU Leuven\Master students\Adrien_Mia\Biodex Data';
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
Ijoint = nan(10,4,2,15);
vjoint  = nan(10,4,2,15);
Tjoint  = nan(10,4,2,15);
Ajoint  = nan(10,4,2,15);

FL         = nan(10,4,2,15);
SOLact     = nan(10,4,2,15);
TAact      = nan(10,4,2,15);
GASact     = nan(10,4,2,15);

P     = nan(10,4,2,15);
act      = nan(10,4,2,15);
ang     = nan(10,4,2,15);

Ps = flip('L':'Z');

load('MVC.mat', 'MVCc', 'Tmax');
MVC = flip(MVCc,2);
load('Passive.mat', 'A', 'T')
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
                
                data(k).angle = data(k).angle -A(1,kk) -5;
                data(k).torque = data(k).torque -T(m,kk);
                
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
                
                fdata(k).acc = grad5(fdata(k).velocity, mean(diff(fdata(k).t)));
                
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
                    id_SRS  = fdata(k).t > 0 & fdata(k).t < .04;
                    
                    if kk == 1
                        figure(km)
                        set(gcf, 'name', trialname)
                        data_plot(fdata(k), 1:length(fdata(k).t), color(k,:))
                    end
                    
                    legend('1', '2', '3', '4', '5','6', '7', '8', '9', '10')
        
                    % stiffness calc
                    fcost = @(c,A,w,T) sum((T-(c(1)*A + c(2)*w)).^2);
                    
                    dA = fdata(k).angle(id_SRS) - fdata(k).angle(find(id_SRS,1));
                    dT = fdata(k).torque(id_SRS) - fdata(k).torque(find(id_SRS,1));
                    dw = fdata(k).acc(id_SRS) - fdata(k).acc(find(id_SRS,1));
                    
                    % find stiffness and inertia
                    C = fmincon(@(c) fcost(c,dA,dw,dT), [0 0], [],[],[],[],[0 0], [], [], []);

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
                    kjoint(k,m,n,kk) = C(1);
                    Ijoint(k,m,n,kk) = C(2);
                    
                    ang(k,m,n,kk) = angs(m);
                    act(k,m,n,kk) = acts(n);
                    P(k,m,n,kk) = kk;
                    
%                     if isfield(fdata(k), 'FL')
%                         kmuscle(k,m,n,kk) = p2(1);
%                     end
                end
            end
        end
    end
end


%% remove some data
% p3 soleus looks bad
SOLact(:,:,:,3) = nan;

%% average over repetitions
sdata = struct();

sdata.participant = squeeze(mean(P,1,'omitnan'));
sdata.angle = squeeze(mean(ang,1,'omitnan'));
sdata.act_level = squeeze(mean(act,1,'omitnan'));

sdata.joint_stiffness = squeeze(mean(kjoint,1,'omitnan'));
% sdata.joint_inertia = squeeze(mean(Ijoint,1,'omitnan'));

sdata.joint_angle = -squeeze(mean(Ajoint,1,'omitnan'));
sdata.joint_torque = squeeze(mean(Tjoint,1,'omitnan'));
sdata.joint_velocity = squeeze(mean(vjoint,1,'omitnan'));
sdata.muscle_length = squeeze(mean(FL,1,'omitnan'));

sdata.TA_activation = squeeze(mean(TAact,1,'omitnan'));
sdata.SOL_activation = squeeze(mean(SOLact,1,'omitnan'));
sdata.GAS_activation = squeeze(mean(GASact,1,'omitnan'));



%% summary figure
colors = parula(15);
if ishandle(km+1), close(km+1); end
figure(km+1)

flds = fields(sdata);
cs = [.5 .5 .5; 0 0 0];

for j = 4:length(flds)
    nexttile
    
    for i = 1:size(sdata.(flds{j}),3)
        plot(angs, sdata.(flds{j})(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
    end
    
    for k = 1:2
    errorbar(angs, mean(sdata.(flds{j})(:,k,:),3,'omitnan'), std(sdata.(flds{j})(:,k,:),1,3,'omitnan'), '--o', 'linewidth', 1, 'color', cs(k,:), 'markerfacecolor', cs(k,:))
    end
    
    box off
    xlabel('Angle (deg')
    
    title(strrep(flds{j}, '_', ' '))
end

%% 
if ishandle(km+2), close(km+2); end
figure(km+2)

for i = 6:15
    nexttile
    plot(sdata.muscle_length(:,:,i), sdata.joint_stiffness(:,:,i), 'o'); hold on
    box off
    
    xlabel('Muscle length')
    ylabel('Joint stiffness')
    title(['P', num2str(i)])
end

%% lump everything into table
for j = 1:length(flds)
    AllData(:,j) = sdata.(flds{j})(:);
end

Tab = array2table(AllData, 'VariableNames', flds);

cd(githubfolder)
filename = 'alldata.xlsx';
writetable(Tab,filename)