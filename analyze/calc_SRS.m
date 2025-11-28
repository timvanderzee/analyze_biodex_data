clc
clear
close all

addpath(genpath(cd))

%%
vels = [60 90 120];
trqs = 20;
th = 80;
cs = 1;

colors = parula(6);

fs = 1000; % gok
dt = 1/fs;
ab = 'abc';

omega = nan(length(trqs), length(th), length(vels), length(ab), length(cs));
phi_id = nan(length(trqs), length(th), length(vels), length(ab), length(cs));
tau_id = nan(length(trqs), length(th), length(vels), length(ab), length(cs));
tau0 = nan(length(trqs), length(th), length(vels), length(ab), length(cs));

ls = {'-','--', ':'};

scale_fac_omega = 110; % guessed, not measured
scale_fac_tau = 77746;

for c = 1:length(cs)
    for i = 1:length(vels)
        figure(1)
        
        for jj = 1:length(ab)
            for j = 1:length(trqs)
                for k = 1:length(th)
                    
                    if c == 1
                        filename =  [num2str(vels(i)),'-', num2str(th(k)),'-', num2str(trqs(j)),ab(jj),'.c3d'];
                    else
                        filename =  ['C9_', num2str(vels(i)),'-', num2str(th(k)),'-', num2str(trqs(j)),ab(jj),'.c3d'];
                    end
                    
                    if exist(filename, 'file')
                        c3d = ezc3dRead(filename);
                        
                        % Check available analog channels
                        analogLabels = c3d.parameters.ANALOG.LABELS.DATA;
                        
                        % Read analog data
                        analogData = c3d.data.analogs;  % [samples × channels]
                        
                        N = length(analogData(:,17));
                        traw = 0:dt:(N-1)*dt;
                        
                        Wn = 20/(.5*fs);
                        [b,a] = butter(2, Wn);
                        
                        phi = filtfilt(b,a, analogData(:,17)) * scale_fac_omega;
                        phidot = filtfilt(b,a, analogData(:,18))  * scale_fac_omega;
                        tau = -filtfilt(b,a, analogData(:,20)) * scale_fac_tau;
                        
                        phi0 = mean(phi(traw < .05));
                        dphi = phi-phi0;
                        
                        id = find(dphi > 3, 1);
                        t = traw - traw(id);
                        
                        phi_id(j,k,i,jj,c) = dphi(id);
                        tau_id(j,k,i,jj,c) = tau(id);
                        tau0(j,k,i,jj,c) = mean(tau(1:200));
                        
                        omega(j,k,i,jj,c) = phidot(id);
                        
                        subplot(3,3,i)
                        %             plot(t, analogData(:,17), 'color', [.5 .5 .5]); hold on
                        plot(t, dphi, ls{jj}, 'color', colors(j,:)); hold on
                        title(['vel = ', num2str(vels(i))])
                        ylabel('Hoek')
                        ylim([-10 60])
                        
                        subplot(3,3,3+i)
                        %             plot(t, analogData(:,18), 'color',[.5 .5 .5]); hold on
                        plot(t, phidot, ls{jj}, 'color', colors(j,:)); hold on
                        plot(0, omega(j,k,i,jj), 'o', 'color', colors(j,:));
                        ylabel('Hoeksnelheid')
                        ylim([-200 200])
                        
                        subplot(3,3,6+i)
                        %             plot(t, analogData(:,20), 'color', [.5 .5 .5]); hold on
                        plot(t, tau, ls{jj}, 'color', colors(j,:)); hold on
                        yline(tau0(j,k,i,jj,c),'--', 'color', colors(j,:))
                        ylabel('Moment')
                        ylim([0 60])
                        
                    end
                end
            end
        end
        
        % make nice
        for ii = 1:9
            subplot(3,3,ii)
            box off
            xlim([-.2 1])
            xline(0,'k--')
        end
        
    end
    
    
end
% 
% omega(5, 2, 5, 2,1) = nan;
% omega(3, 4, 7, 2,1) = nan;
% omega(5, 3, 6, 2,1) = nan;

%% summary
if ishandle(11), close(11); end; figure(11)
if ishandle(12), close(12); end; figure(12)

type = 'SRS';

SRS = (tau_id - tau0) ./ phi_id;

if strcmp(type, 'omega')
    y = -omega;
    ylab = 'Hoeksnelheid (deg/s)';
    yl = [-10 100];
    
elseif strcmp(type, 'tau')
    y = tau0;
    ylab = 'Torque (N-m)';
    yl = [0 100];
else
    y = SRS;
    ylab = 'SRS (N-m/deg)';
    yl = [0 7];
end

k = 1;
c = 1;

figure(2)
subplot(311)
errorbar(vels, squeeze(mean(omega, 4)), squeeze(std(omega, 1, 4)),'o')
ylim([0 60])

subplot(312)
errorbar(vels, squeeze(mean(tau0, 4)), squeeze(std(tau0, 1, 4)),'o')
ylim([0 22])

subplot(313)
errorbar(vels, squeeze(mean(SRS, 4)), squeeze(std(SRS, 1, 4)),'o')
ylim([0 1])

titles = {'Angular velocity (deg/s)', 'Isometric torque (N-m)', 'SRS'};
for i = 1:3
    subplot(3,1,i)
    xlim([50 130])
    box off
    xlabel('Max. angular velocity (deg/s)')
    ylabel(titles{i})
end

%% make nice

return
%%
%kanaalIndex = 4;
for kanaalIndex = 1:size(analogData, 2) %analogdata is een 2D lijst we zeggen hier dus 2 omdat we de lengte van de kolommen willen = channels
    kanaalNaam = analogLabels{kanaalIndex};
    
    % Get full signal for this channel
    dataVector = analogData(:, kanaalIndex);  % column of samples
    
    % Plot
    figure;
    plot(dataVector);
    title(['Signaal van kanaal: ' kanaalNaam]);
    xlabel('Sample'); ylabel('Waarde');
    grid on;
    pause(0.5);
end

%%
% Read analog data
%analogData = c3d.data.analogs;  % [channels x subframes x frames]
%for index = 0:length(analogLabels)-1
% Example: extract and plot the first signal
% kanaalIndex = index+1;  % of use find(strcmp(...)) if you know the label
% kanaalNaam = analogLabels{kanaalIndex};

% Extract full signal over time
% Flatten: [subframes × frames] → single time vector
% data1D = squeeze(analogData(kanaalIndex, :, :));
% dataVector = reshape(data1D, 1, []);

% Plot
% figure;
% plot(dataVector);
% title(['Signaal van kanaal: ' kanaalNaam]);
% xlabel('Sample'); ylabel('Waarde');
% grid on;
%end
