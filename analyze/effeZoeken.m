clc
clear
close all

cd('C:\Users\u0167448\Documents\ezc3d_matlab\Data')
% addpath(genpath(cd))

%%
vels = [20 30 45 60 90 120 150 240 360 500];
trqs = 10:10:60;
th = [50 80 110 140];
cs = [1 2];

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
scale_fac_tau = (60-20) / (.00042 - .00015);

for c = 1:length(cs)
    for i = 1:length(vels)
        figure(i)
        
        for jj = 1:length(ab)
            for j = 1:length(trqs)
                for k = 1:length(th)
                    
                    
                    if c == 1
                        filename =  [num2str(vels(i)),'-', num2str(th(k)),'-', num2str(trqs(j)),'-',ab(jj),'.c3d'];
                    else
                        filename =  ['C9_', num2str(vels(i)),'-', num2str(th(k)),'-', num2str(trqs(j)),'-',ab(jj),'.c3d'];
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
                        tau = filtfilt(b,a, analogData(:,20)) * scale_fac_tau;
                        
                        phi0 = mean(phi(traw < .05));
                        dphi = phi-phi0;
                        
                        id = find(dphi < (-.03 * scale_fac_omega), 1);
                        t = traw - traw(id);
                        
                        phi_id(j,k,i,jj,c) = dphi(id);
                        tau_id(j,k,i,jj,c) = tau(id);
                        tau0(j,k,i,jj,c) = mean(tau(1:200));
                        
                        omega(j,k,i,jj,c) = phidot(id);
                        
                        subplot(3,4,k)
                        %             plot(t, analogData(:,17), 'color', [.5 .5 .5]); hold on
                        plot(t, dphi, ls{jj}, 'color', colors(j,:)); hold on
                        title(['th = ', num2str(th(k))])
                        ylabel('Hoek')
                        ylim([-60 10])
                        
                        subplot(3,4,4+k)
                        %             plot(t, analogData(:,18), 'color',[.5 .5 .5]); hold on
                        plot(t, phidot, ls{jj}, 'color', colors(j,:)); hold on
                        plot(0, omega(j,k,i,jj), 'o', 'color', colors(j,:));
                        ylabel('Hoeksnelheid')
                        ylim([-100 100])
                        
                        subplot(3,4,8+k)
                        %             plot(t, analogData(:,20), 'color', [.5 .5 .5]); hold on
                        plot(t, tau, ls{jj}, 'color', colors(j,:)); hold on
                        yline(tau0(j,k,i,jj,c),'--', 'color', colors(j,:))
                        ylabel('Moment')
                        ylim([0 100])
                        
                    end
                end
            end
        end
        
        % make nice
        for ii = 1:12
            subplot(3,4,ii)
            box off
            xlim([-.2 1])
            xline(0,'k--')
        end
        
    end
    
    
end

omega(5, 2, 5, 2,1) = nan;
omega(3, 4, 7, 2,1) = nan;
omega(5, 3, 6, 2,1) = nan;

%% summary
if ishandle(11), close(11); end; figure(11)
if ishandle(12), close(12); end; figure(12)

type = 'SRS';

SRS = (tau_id - tau0) ./ -phi_id;

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

for c = 1 %:length(cs)
    figure(10+c)
    color = get(gca,'colororder');
    
    
    for i = 1:length(vels)
        for k = 1:length(th)
            subplot(2,5,i)
            plot(trqs, mean(y(:,k,i,:,c),4, 'omitnan'), 'color', color(k,:), 'linewidth',2); hold on
            box off
            title([num2str(vels(i)), ' deg/s'])
            xlabel('Torque (N-m)')
            ylabel(ylab)
            ylim(yl)
            xlim([0 70])
        end
%         yline(vels(i), 'k--')
    end
    
    
    for i = 1:length(vels)
        for k = 1:length(th)
            subplot(2,5,i)
            plot(trqs, y(:,k,i,1,c),'.', 'color', color(k,:));
            plot(trqs, y(:,k,i,2,c),'.', 'color', color(k,:));
        end
    end
    
    subplot(251)
    legend('th = 50 N-m', 'th = 80 N-m', 'th = 110 N-m', 'th = 140 N-m', 'target', 'location', 'best')
    legend boxoff
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
