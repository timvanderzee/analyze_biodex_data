clear all; close all; clc


datafolder = 'C:\Users\u0167448\OneDrive - KU Leuven\Master students\Adrien_Mia\Data';

Ps = flip('L':'Z');
dates = flip({'2302' '2302' '1812' '1812' '1812' '1712' '1712' '1712' '1712' '1612' '1512' '1012' '1012' '1012' '0412'});

acts = [20 30];
angs = 5:10:35;
alfabet = 'a':'j';

Fs = nan(length(angs), length(acts), length(alfabet), length(Ps));
D = nan(length(angs), length(acts), length(alfabet), length(Ps));

for kk = 1:15
    
    disp(kk)
    subfolder = fullfile(datafolder, [Ps(kk) num2str(dates{kk})]);
    
    cd(subfolder)
    
    for m = 1:length(angs)
        for n = 1:length(acts)
            
            for j = 1:length(alfabet)
                trialname = [Ps(kk), '-', num2str(angs(m)), '-', num2str(acts(n)), num2str(alfabet(j)), '.mat'];
                
                
                if exist(trialname, 'file')
                    load(trialname);
                    
                    Fs(m,n,j,kk) = TVDdata.fps;
                    D(m,n,j,kk) = TVDdata.Height * TVDdata.cmPerPixX;
                else
                    disp(['Does not exist: ', trialname])
                end
            end
        end
    end
end

%%
% cd('C:\Users\u0167448\Documents\GitHub\analyze_biodex_data')
% save('USdata.mat', 'Fs', 'D', 'Ps', 'dates')