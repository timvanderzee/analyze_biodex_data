clear all; close all; clc

cd('C:\Users\u0167448\OneDrive - KU Leuven\Bestanden van Mia Aerts - Metingen')
folders = dir(cd);

newfolder = 'C:\Users\u0167448\Documents\Data\SRS\Metingen';

for i = (length(folders)-4):-1:1
    cd(fullfile(folders(i+2).folder, folders(i+2).name))
    
    subfolders = dir(cd);
    
    for j = 1:length(subfolders)-2
        if subfolders(j+2).isdir
            
     
            cd(fullfile(subfolders(j+2).folder, subfolders(j+2).name))
            
            ofile = dir('*onsets.mat');
            
            load(ofile.name, 'id')

            cd(fullfile(newfolder, folders(i+2).name, subfolders(j+2).name));
            
            mkdir('processed')
            cd('processed')
            save(ofile.name, 'id')
        end
    end
end

   