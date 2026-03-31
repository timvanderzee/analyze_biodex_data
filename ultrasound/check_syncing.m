clear all; close all; clc
% compare trial duration
Ps = flip('L':'Z');
dates = flip({'2302' '2302' '1812' '1812' '1812' '1712' '1712' '1712' '1712' '1612' '1512' '1012' '1012' '1012' '0412'});


biodex_folder = 'C:\Users\u0167448\OneDrive - KU Leuven\Master students\Adrien_Mia\Biodex Data';
cd(biodex_folder)

acts = [20 30];
angs = 5:10:35;
alfabet = 'a':'j';

USfolder = 'C:\Users\u0167448\OneDrive - KU Leuven\Bestanden van Chris Smeets - Tracked';

tmax = nan(length(angs), length(acts), length(alfabet), length(Ps));
tmax2 = nan(length(angs), length(acts), length(alfabet), length(Ps));

for c = 1:length(Ps)        
    for m = 1:length(angs)
        for n = 1:length(acts)

              filename = fullfile(biodex_folder, [Ps(c), '-', num2str(angs(m)), '-', num2str(acts(n)),'.mat']);
              
              if exist(filename, 'file')
                  load(filename)

                  for i = 1:length(data)
                      tmax(m,n,i,c) = max(data(i).t) - min(data(i).t);

                      USfilename = fullfile(USfolder, ['Tracked_', Ps(c)], [Ps(c), '-', num2str(angs(m)), '-', num2str(acts(n)), alfabet(i), '_tracked.mat']);
                      
                    if exist(USfilename, 'file')
                        load(USfilename, 'Fdat');
                        tmax2(m,n,i,c) = max(Fdat.Region.Time) - min(Fdat.Region.Time);
                    end
                      
                  end
              end
        end
    end
end

%%
close all
figure(1)

color = parula(15);

for i = 1:length(Ps)
    nexttile
    plot(reshape(tmax(:,:,:,i),1, numel(tmax(:,:,:,i))), ...
        reshape(tmax2(:,:,:,i),1, numel(tmax2(:,:,:,i))), '.', 'color', color(1,:)); hold on

    xlabel('Biodex time'); 
    ylabel('US time')
    axis equal

    plot([0 30], [0 30]-1, 'k-')
end

%%
us_folder = 'C:\Users\u0167448\OneDrive - KU Leuven\Bestanden van Chris Smeets - Tracked';
cd(us_folder)


files = dir('*0.mat');



