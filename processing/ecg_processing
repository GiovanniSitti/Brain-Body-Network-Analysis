%% ECG preprocessing pipeline

% Main processing steps:
% 1. Load multimodal EEG/ECG/EGG recordings.
% 2. Select ECG channels from the full multimodal dataset.
% 3. Load R-peaks previously detected and corrected using R-DECO.
% 4. Convert R-peak sample indices into time points.
% 5. Compute inter-beat intervals (IBI/RR intervals).
% 6. Visually check R-peak alignment with the ECG trace.
% 7. Compute time-resolved cardiac sympathetic and parasympathetic indices.
% 8. Extract rCSI and rCVI/rCPI time series for later coupling analyses.

% Required toolbox and functions:
% - FieldTrip
% - R-DECO for R-peak detection and correction
% - robust_hrv functions, including compute_rCSI_rCVI_type.m from: 

% Candia-Rivera D., de Vico Fallani F., Chavez M., 2025
% "Robust and time-resolved estimation of cardiac sympathetic and
% parasympathetic indices"

clear all
close all
clc

%% load subject
 num = 1  %% change number of subject

cfg = [];
filename = sprintf('participant %03d.vhdr',num)
filepath= 'EEG_ECG_EGG_Data/'; 
filefull= [filepath filename]
cfg.dataset =filefull;
dataset= ft_preprocessing(cfg);
fs=dataset.fsample

%% ECG channels selection

cfg.channel = setdiff(dataset.label, { ...
    'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5', ...
    'FC1','FC2','FC6','T7','C3','Cz','C4','T8', ...
    'TP9','CP5','CP1','CP2','CP6','TP10','P7','P3','Pz','P4','P8', ...
    'PO9','O1','Oz','O2','PO10','EGG4','EGG5','EGG6'}); %tengo solo ECG
ECG = ft_preprocessing(cfg,dataset);

%%plot ecg
% cfg.viewmode = 'vertical';
% cfg.continuous = 'yes'; 
% cfg.blocksize = 40
% cfg.ylim      = [-100 100]
% ft_databrowser(cfg,ECG);
ecg_data=ECG.trial{1};
time=ECG.time{1};


%load the Rpeaks obtained with Rdeco

filename = sprintf('Export_Rpeaks_%03d.mat', num)
filepath= 'Export_Rpeaks/' 
filefull= [filepath filename]
file=load(filefull)
varname = fieldnames(file);
Export_Rpeaks = file.(varname{1});

% use only one ecg channel
Rpeaks_idx1=Export_Rpeaks.Channel_1.R;
% Rpeaks_idx2=Export_Rpeaks.Channel_2.R;
% Rpeaks_idx3=Export_Rpeaks.Channel_3.R;

% compute IBI

t_Rpeaks_1 = Rpeaks_idx1/fs;
% t_Rpeaks_2 = Rpeaks_idx2/fs;
% t_Rpeaks_3 = Rpeaks_idx3/fs;

RR1=diff(t_Rpeaks_1)
% RR2=diff(t_Rpeaks_2)
% RR3=diff(t_Rpeaks_3)

t_RR1 = t_Rpeaks_1(2:end);
% t_RR2 = t_Rpeaks_2(2:end);
% t_RR3 = t_Rpeaks_3(2:end);

%visually check Rpeak alignment with ecg
% figure
% plot(time,ecg_data(1,:))
% hold on
% xline(t_Rpeaks_1,'r')


% CPI and CSI computation

wind=15
method='exact';

% compute csi, cvi timeseries according to 'exact' method

struct_output = compute_rCSI_rCVI_type(RR1, t_RR1, wind, method)

rCSI=struct_output.CSI
rCVI=struct_output.CVI

Ds_out=struct_output.CSI_HR;
Dv_out=struct_output.CVI_HR; 
CSI_HRV=struct_output.CSI_HRV;
CVI_HRV=struct_output.CVI_HRV;

t_out=struct_output.time

figure
plot(t_out, rCSI, 'r')
hold on
plot(t_out, rCVI, 'b')
legend('rCSI', 'rCVI');
