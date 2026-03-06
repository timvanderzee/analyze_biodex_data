clear all; close all; clc

mainfolder = 'C:\Users\u0167448\Documents\Data\SRS\Metingen ultrasounds';

folders = dir(mainfolder);

for i = 1:length(folders)-3
    cd(fullfile(folders(i+2).folder, folders(i+2).name));
    
    TVDfiles = dir('*.tvd');
   
    for j = 1:length(TVDfiles)
        TVDfile = fullfile(folders(i+2).folder, folders(i+2).name, TVDfiles(j).name);
        
        if ~exist(strrep(TVDfile,'.tvd','.mp4'), 'file')
        
            TVDdata = TVD2ALL(TVDfile,'VideoQuality', 100); 

            save(strrep(TVDfile,'.tvd','.mat'),'TVDdata')
            disp(['Saved: ', TVDfile])
        end
        
    end
end
