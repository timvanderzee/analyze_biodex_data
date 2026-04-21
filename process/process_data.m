clear all; close all; clc
[githubfolder,~,~] = fileparts(which('process_data'));
cd(githubfolder);
cd .. 
addpath(genpath(cd))

mainfolder = uigetdir(); 
% mainfolder = 'C:\Users\u0167448\OneDrive - KU Leuven\Master students\Adrien_Mia\Biodex Data';
cd(mainfolder)

acts = [20 30];
angs = 5:10:35;

% moments arm
r = 0.05; % [m]
typical_example = 10;

% filter properties
fs = 1000;
Wn = 5/(.5*fs);
Wn2 = [5 400]/(.5*fs);
[b,a] = butter(2, Wn);
[d,c] = butter(2, Wn2);

kjoint  = nan(10,4,2,15);
Ijoint = nan(10,4,2,15);
vjoint  = nan(10,4,2,15);
Tjoint  = nan(10,4,2,15);
Ajoint  = nan(10,4,2,15);

FL         = nan(10,4,2,15);
SOLact     = nan(10,4,2,15);
TAact      = nan(10,4,2,15);
GASact     = nan(10,4,2,15);

FSRS        = nan(40,10,4,2,15); 
LSRS        = nan(40,10,4,2,15); 

P     = nan(10,4,2,15);
act      = nan(10,4,2,15);
ang     = nan(10,4,2,15);

Ps = flip('L':'Z');

load('MVC.mat', 'MVCc', 'Tmax');
MVC = flip(MVCc,2);
load('Passive.mat', 'A', 'T')
color = turbo(4);

%% loop over participants

for kk = 1:15
    
    disp(Ps(kk))

    for m = 1:length(angs) % angles        
        for n = 1:length(acts) % activations
                       
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
                
                % synchronize
                tid = find((fdata(k).angle-phi0(k)) > 2,1);
                
                if ~isempty(tid)
                    dt = data(k).t(tid);
                    fdata(k).t = data(k).t - dt;
                    
                    % select intervals
                    id_prior = fdata(k).t > -.1 & fdata(k).t < 0;
                    id_SRS  = fdata(k).t > 0 & fdata(k).t < .04;
                    
                    % typical example
                    if kk == typical_example
                        figure(n)
                        set(gcf, 'name', trialname)
                        data_plot(fdata(k), 1:length(fdata(k).t), [color(m,:) .2])

                        figure(3)
                        plot(fdata(k).angle(id_SRS), fdata(k).torque(id_SRS), 'color', color(m,:), 'linewidth', 1); hold on
                    end
        
                    % stiffness calc
                    fcost = @(c,A,w,T) sum((T-(c(1)*A + c(2)*w)).^2);
                    
                    dA = fdata(k).angle(id_SRS) - fdata(k).angle(find(id_SRS,1));
                    dT = fdata(k).torque(id_SRS) - fdata(k).torque(find(id_SRS,1));
                    da = fdata(k).acc(id_SRS) - fdata(k).acc(find(id_SRS,1));
                    
                    % find stiffness and inertia
                    options = optimoptions('fmincon','display','none');
                    C = fmincon(@(c) fcost(c,dA,da,dT), [0 0], [],[],[],[],[0 0], [], [], options);
%                     C = fminsearch(@(c) fcost(c,dA,da,dT), [0 0]);

                    % save summary terms
                    if isfield(fdata(k), 'FL')
                        FL(k,m,n,kk)    = mean(fdata(k).FL(id_prior,1));

                        % calculate SRS
                        TSRS = C(1)*dA;
                        FSRS(1:length(TSRS), k,m,n,kk) = TSRS / r;
                        FLs = fdata(k).FL(id_SRS,1);
                        
                        p = polyfit(FLs(1:39), FSRS(1:39,k,m,n,kk), 1);
                         
%                         if fdata(k).FL(find(id_SRS,1,'last'),1) > fdata(k).FL(find(id_SRS,1,'first'),1) % if there is lengthening
                        if p(1) > 0 % if there is lengthening
                            LSRS(1:length(TSRS), k,m,n,kk) = fdata(k).FL(id_SRS,1);
                        end
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
                    
                end
            end
        end
    end
end


%% remove some data
% p3 soleus looks bad
SOLact(:,:,:,[1 3 4 5 6 8]) = nan;

% participant 15 had sync issue
LSRS(:,[1 2], 1,:,15) = nan;
LSRS(:,[2 3 6 7 9 10], 2,:,15) = nan;
LSRS(:,4, 3,:,15) = nan;
LSRS(:,[3 6], 4,:,15) = nan;

FL([1 2], 1,:,15) = nan;
FL([2 3 6 7 9 10], 2,:,15) = nan;
FL(4, 3,:,15) = nan;
FL([3 6], 4,:,15) = nan;

% participants 1-5 have sync issue, participant 7-8 have bad tracking
LSRS(:,:,:,:,[(1:5), (7:8)]) = nan;
FL(:,:,:,[(1:5), (7:8)]) = nan;
% ks = [6, 9:15];

% check the number of repetitions with valid length estimates
idx = zeros(4,2,15);
for kk = 1:15
    for m = 1:length(angs) % angles        
        for n = 1:length(acts) % activations
            idx(m,n,kk) = sum(isfinite(LSRS(1,:,m,n,kk)));
        end
    end
end

%% figure 200: SRS plot
% average over trials
LSRSm = squeeze(mean(LSRS,2, 'omitnan'));
FSRSm = squeeze(mean(FSRS,2, 'omitnan'));

% calc SRS
SRS = nan(4,2,15);
if ishandle(200), close(200); end

for kk = 1:15
    for m = 1:length(angs) % angles        
        for n = 1:length(acts) % activations
            
            if idx(m,n,kk) > 2 % minimally 3 valid repetitions
                p = polyfit(LSRSm(1:39,m,n,kk), FSRSm(1:39,m,n,kk), 1);
                SRS(m,n,kk) = p(1);
            end
        end
    end
    
    if sum(isfinite(SRS(:,:,kk))) > 0
        figure(200)
        nexttile
        plot(angs, SRS(:,:,kk),'.-', 'markersize', 20);
        xlabel('Angle (deg)')
        ylabel('SRS (N/mm)')
        box off
        title(['Participant ', num2str(kk)])
    end
end

nexttile
for n = 1:2
    errorbar(angs, mean(SRS(:,n,:),3,'omitnan'), std(SRS(:,n,:),1,3,'omitnan'), '.', 'markersize', 20); hold on
end

title('Average')
xlabel('Angle (deg)')
ylabel('SRS (N/mm)')
box off

%% average over repetitions
sdata = struct();

sdata.participant = squeeze(mean(P,1,'omitnan'));
sdata.angle = squeeze(mean(ang,1,'omitnan'));
sdata.act_level = squeeze(mean(act,1,'omitnan'));

sdata.joint_stiffness = squeeze(mean(kjoint,1,'omitnan'));
sdata.joint_inertia = squeeze(mean(Ijoint,1,'omitnan'));

sdata.joint_angle = -squeeze(mean(Ajoint,1,'omitnan'));
sdata.joint_torque = squeeze(mean(Tjoint,1,'omitnan'));
sdata.joint_velocity = squeeze(mean(vjoint,1,'omitnan'));
sdata.muscle_length = squeeze(mean(FL,1,'omitnan'));
sdata.SRS = SRS;

sdata.TA_activation = squeeze(mean(TAact,1,'omitnan'));
sdata.SOL_activation = squeeze(mean(SOLact,1,'omitnan'));
sdata.GAS_activation = squeeze(mean(GASact,1,'omitnan'));

%% figure 201: summary figure
colors = parula(15);
color = lines(5);
if ishandle(201), close(201); end
figure(201)

flds = fields(sdata);
cs = [.5 .5 .5; 0 0 0];

for j = 4:length(flds)
    nexttile
    
    for i = 1:size(sdata.(flds{j}),3)
        plot(angs, sdata.(flds{j})(:,:,i),'-', 'color', [colors(i,:) .2]); hold on
    end
    
    for k = 1:2
        errorbar(angs, mean(sdata.(flds{j})(:,k,:),3,'omitnan'), std(sdata.(flds{j})(:,k,:),1,3,'omitnan'), '.-', 'color', color(k,:), 'markersize', 20)
    end
    
    box off
    xlabel('Angle (deg')
    
    title(strrep(flds{j}, '_', ' '))
end

%% figure 202 and 203: correlations plots
if ishandle(202), close(202); end
if ishandle(203), close(203); end

for i = 1:15
    
    if sum(isfinite(sdata.muscle_length(:,:,i))) > 0

        figure(202)
        nexttile
        plot(sdata.muscle_length(:,:,i), sdata.joint_stiffness(:,:,i), '.', 'markersize', 20); hold on
        box off

        xlabel('Muscle length')
        ylabel('Joint stiffness')
        title(['P', num2str(i)])
        
        figure(203)
        nexttile
        plot(sdata.muscle_length(:,:,i), sdata.SRS(:,:,i), '.', 'markersize', 20); hold on
        box off

        xlabel('Muscle length')
        ylabel('SRS')
        title(['P', num2str(i)])
    end
end

figure(202)
nexttile
errorbar(mean(sdata.muscle_length,3,'omitnan'), mean(sdata.joint_stiffness,3, 'omitnan'), std(sdata.joint_stiffness,1,3, 'omitnan'),...
    std(sdata.joint_stiffness,1,3, 'omitnan'), std(sdata.muscle_length,1,3, 'omitnan'), std(sdata.muscle_length,1,3, 'omitnan'), '.', 'markersize', 20); hold on
box off

xlabel('Muscle length')
ylabel('Joint stiffness')
title('Average')

figure(203)
nexttile
errorbar(mean(sdata.muscle_length,3,'omitnan'), mean(sdata.SRS,3, 'omitnan'), std(sdata.SRS,1,3, 'omitnan'),...
    std(sdata.SRS,1,3, 'omitnan'), std(sdata.muscle_length,1,3, 'omitnan'), std(sdata.muscle_length,1,3, 'omitnan'), '.', 'markersize', 20); hold on
box off

xlabel('Muscle length')
ylabel('SRS')
title('Average')

%% lump everything into table
AllData = nan(numel(sdata.(flds{1})(:)), length(flds));
for j = 1:length(flds)
    AllData(:,j) = sdata.(flds{j})(:);
end

%%
Tab = array2table(AllData, 'VariableNames', flds);

cd(githubfolder)
filename = 'alldata.xlsx';
writetable(Tab,filename)