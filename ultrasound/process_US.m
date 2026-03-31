clear all; close all; clc

mainfolder = 'C:\Users\u0167448\Documents\Data\SRS\Metingen';
cd(mainfolder)

fs = 1000;

kk = 0;
color = lines(10);

acts = [20 30];
angs = 5:10:35;
alfabet = 'a':'j';

Biodexfolder = 'C:\Users\u0167448\OneDrive - KU Leuven\Master students\Adrien_Mia\Biodex Data';
USfolder = 'C:\Users\u0167448\OneDrive - KU Leuven\Bestanden van Chris Smeets - Tracked';

Ps = 'L':'Z';
dates = {'2302' '2302' '1812' '1812' '1812' '1712' '1712' '1712' '1712' '1612' '1512' '1012' '1012' '1012' '0412'};

ti = -8:.01:5;
FLi = nan(length(ti), length(angs), length(acts), length(alfabet), length(Ps));

for c = 1:length(Ps)
    
    disp(Ps(c))
    
    subfolder = fullfile(mainfolder, num2str(dates{c}), Ps(c));
    cd(fullfile(subfolder, 'processed'))

    ofiles = dir('*onsets.mat');
    load(ofiles.name, 'id')

        
    for m = 1:length(angs)
        for n = 1:length(acts)
            
            kk = kk+1;

            for o = 1:length(alfabet)

                filename = fullfile(USfolder, ['Tracked_', Ps(c)], [Ps(c), '-', num2str(angs(m)), '-', num2str(acts(n)), alfabet(o), '_tracked.mat']);
                
                if exist(filename, 'file')
                    load(filename);
                else
                    disp(['Does not exist: ', filename])
                end
                
                
                dt = 1/1000;
                
                FL = Fdat.Region.FL;
                t = Fdat.Region.Time - id(o,n,m) * dt + 1;
                
        
                FLi(:,m,n,o,c) = interp1(t, FL, ti);
                
            end
        end
    end
end

%% load torque data


%%
color = lines(length(angs));
close all
n = 1;

gcolor = [.8 .8 .8];

figure(1)
for c = 1:10
    figure(c)
    
    for m = 1:length(angs)

        % load the torque data
        filename = fullfile(Biodexfolder, [Ps(c), '-', num2str(angs(m)), '-', num2str(acts(n)),'.mat']);

        if exist(filename, 'file')
            load(filename, 'data')
        end
        
        Ti = nan(length(ti), 10);
        Ai = nan(length(ti), 10);
        
        for i = 1:10
%             plot(data(i).t, data(i).torque, 'color', [.5 .5 .5]); hold on
            
            Ai(:,i) = interp1(data(i).t, data(i).angle, ti);
            Ti(:,i) = interp1(data(i).t, data(i).torque, ti);
        end
        
        subplot(311)
%         plot(ti, Ti, 'color', gcolor)
        plot(ti, mean(Ai,2, 'omitnan'), 'color', color(m,:), 'linewidth', 2); hold on
        
        subplot(312)
%         plot(ti, Ti, 'color', gcolor)
        plot(ti, mean(Ti,2, 'omitnan'), 'color', color(m,:), 'linewidth', 2); hold on
        
        subplot(313)
%         plot(ti, squeeze(FLi(:,m,n,:,c)), 'color', gcolor)
        plot(ti, mean(FLi(:,m,n,:,c),4, 'omitnan'), 'color', color(m,:), 'linewidth', 2); hold on

    end

    for i = 1:3
        subplot(3,1,i)
        xline(0, 'k--')
        xlim([-5 1])
    end
end


% end
