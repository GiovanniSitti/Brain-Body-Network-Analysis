%% EGG preprocessing pipeline

% Main processing steps:
%
% - Load EEG/ECG/EGG recordings
% - Select gastric EGG channels from the multimodal dataset
% - Visually inspect raw EGG recordings
% - Compute FFT spectra to identify the gastric peak frequency
% - Apply filtering in the normogastric frequency range
% - Compute time-resolved gastric power dynamics

% Required toolboxes and external functions:
%
% FieldTrip
% EGG processing functions are based on:
%EGG_Scripts toolbox
% Wolpert N. et al., 2020
% "Electrogastrography for psychophysiological research: Practical considerations, analysis pipeline, and normative data in a large sample"

close all
clear all
clc

%% load subject 1
num=1

% visualize raw EGG data 
    
filename = sprintf('participant %03d.vhdr', num)
filepath= 'EEG_ECG_EGG_Data/'
filefull= [filepath filename];
patient = filefull;
disp(['Processing: ' filefull]);

cfg = [];
cfg.dataset =filefull  ;
data= ft_preprocessing(cfg);

cfg = [];
    cfg.channel = {'EGG4' 'EGG5' 'EGG6' };

EGG_raw=ft_selectdata(cfg,data);

cfg=[]

cfg.ylim     = [-100 100];
cfg.blocksize = 300;
ft_databrowser(cfg, EGG_raw);

%% COMPUTE FFT (verify that peak is in the range)
compute_FFT_EGG_new(EGG_raw)

%% Save EGG raw with eventually removed channels

% filename = sprintf('EGG_raw_%03d.mat', num)
% filepath= 'EGG_raw/';
% filefull= [filepath filename]
% save(filefull,'EGG_raw');
 
%% load EGG raw with bad channels already removed 

% filename = sprintf('EGG_raw_%03d.mat', num)
% filepath= 'EGG_raw/' 
% 
% filefull= [filepath filename]
% patient = filefull;
% disp(['Processing: ' filefull]);
% cfg = [];
% cfg.dataset =filefull ;
% EGG_raw= ft_preprocessing(cfg);
% %
% figure
% cfg=[]
% cfg.ylim     = [-200 200];   
% cfg.blocksize = 720
% ft_databrowser(cfg, EGG_raw);

%% Filtering (extracting signal in normogastric range with toolbox FIR filter)

n=length(EGG_raw.label);
EGG_filtered=EGG_raw;                                      
EEG_amplitude=EGG_raw;

for i=1:n
    %fprintf('Processing channel %d: %s\n ', i, EGG_raw.label{i});
          
    % select channel 
    cfg = [];
    cfg.channel = EGG_raw.label{i};
    EGGraw= ft_selectdata(cfg, EGG_raw);
    
    % filter channel i
    [EGG_filtered(i)]= compute_filter_EGG_new(EGGraw);
    
end

b=input('save egg filtered?','s')

if b=='y'

filename = sprintf('EGG_filtered_%03d.mat', num)
filepath= 'EGG_filtered/' ;
filefull= [filepath filename];
save(filefull,'EGG_filtered');

end

%% tf analysis
for num=1:28
filename = sprintf('EGG_filtered_%03d.mat', num)
filepath= 'EGG_filtered/'; 
filefull= [filepath filename]
EGG_filtered = load(filefull);
EGG_filtered =EGG_filtered.EGG_filtered;

n=size(EGG_filtered,2);

EGG_power = EGG_filtered

for i = 1:n

    [EGG_power(i), t] = compute_power_EGG(EGG_filtered(i));
    plot_EGG_visual_inspection_new(EGG_filtered(i), EGG_power(i), t);

end
end
