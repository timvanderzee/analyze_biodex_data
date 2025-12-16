clc; clear; close all
% githubfolder = uigetdir('C:\', 'Select GitHub folder');
% datafolder = uigetdir('C:\', 'Select data folder');
datafolder = 'C:\Users\u0167448\Documents\Data\0412\Z';
cd(datafolder)
% addpath(genpath(githubfolder))

%% do analysis
alfabet = 'a':'z';
nrep = 10;
vs = alfabet(1:nrep);

% sample frequency (Hz)
fs = 1000;

% time
ti = -.1:(1/fs):.1;

% activation (% max)
acts = [20 30];

% joint angles (deg)
phis = [5 15 25 35];

figure(1)
set(gcf,  'units', 'normalized', 'position', [0 0 1 .8])


for k = 1:length(phis) % loop over angles
    for l = 1:length(acts) % loop over activations
        phi = phis(k);
        
        for i = 1:length(vs)
            
            filename =  ['Z-', num2str(phi), '-',num2str(acts(l)), vs(i),'.c3d'];
            
            if exist(filename, 'file')
                
                figure(1)
                set(gcf, 'name', filename)
                id(i,l,k) = analyze_trial(filename);
                

            end
        end
        
    
    end
end

save('onsets.mat', 'id');
% load('onsets.mat', 'id');

%%
function[id] = analyze_trial(filename)


    %% load
    % load
    c3d = ezc3dRead(filename);

    % Check available analog channels
%     analogLabels = c3d.parameters.ANALOG.LABELS.DATA;

    % Read analog data
    analogData = c3d.data.analogs;  % [samples × channels]


    plot(analogData(:,17));

        [id, ~] = ginput(1);

        xline(id(1),'k--')
        pause

    
end
