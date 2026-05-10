%% EEG preprocessing pipeline

% Dataset dataset used in the study:
% Todd J., Cardellicchio P., Swami V., Cardini F., Aspell J.E.
% "Weaker implicit interoception is associated with more negative body image: Evidence from gastric-alpha phase amplitude coupling and the heartbeat evoked potential"

% Main preprocessing steps:
% 1. Load multimodal BrainVision recordings.
% 2. Select EEG channels from simultaneous EEG/ECG/EGG data.
% 3. Band-pass filtering, and notch filtering.
% 4. Perform ICA decomposition for artifact identification and removal.
% 5. Reject artifact-related ICA components.
% 6. Remove and interpolate bad EEG channels.
% 7. Re-reference EEG signals to the average reference.

% Required toolbox:
% - FieldTrip 
% - custom electrode layout and neighbour files has been used

clear all
close all
clc

%load full dataset - subject 1

num=1;
filename = sprintf('participant %03d.vhdr', num)
filepath= 'EEG_ECG_EGG_Data/' 
filefull= [filepath filename]
subject = filefull;
disp(['Processing: ' filefull]);

%visualize subject

cfg = [];
cfg.dataset = filefull
data = ft_preprocessing(cfg);
subject = cfg.dataset;
% cfg.viewmode = 'vertical';
% cfg.continuous = 'yes';
% cfg.blocksize = 10;
% ft_databrowser(cfg,data)

%select EEG 

cfg=[];
cfg.channel = setdiff(data.label, {'EGG1','EGG2','EGG3','EGG4','EGG5','EGG6'}); 
cfg.preproc.detrend='yes';
EEG = ft_preprocessing(cfg,data);

cfg=[];
cfg.viewmode = 'vertical';
cfg.continuous = 'yes'; 
cfg.blocksize = 10;
cfg.ylim      = [-30 30];
ft_databrowser(cfg,EEG);

% filtering 
cfg = [];
cfg.bpfilter = 'yes';
cfg.bpfreq = [1 45];       
cfg.bpfilttype  = 'but';  
EEG_filt = ft_preprocessing(cfg, EEG);

%notch
cfg = [];
cfg.bsfilter = 'yes'; 
cfg.bsfreq = [49 51];
EEGfilt = ft_preprocessing(cfg, EEG_filt);

% cfg=[]
% cfg.viewmode = 'vertical';
% cfg.continuous = 'yes'; 
% cfg.blocksize = 10;
% cfg.ylim      = [-30 30]
% ft_databrowser(cfg,EEGfilt);

% visualize PSD 

% cfg = [];
% 
% cfg.output  = 'pow';
% cfg.channel = 'all';
% cfg.method  = 'mtmfft';
% cfg.taper   = 'hanning';
% cfg.foi     = 1:1:100; 
% EEG_psd   = ft_freqanalysis(cfg, EEG);
% EEGfilt_psd   = ft_freqanalysis(cfg, EEGfilt);

% for i=1:32
% figure
% plot(EEG_psd.freq, EEG_psd.powspctrm(i,:)); 
% xlabel('Freq (Hz)');
% ylabel('Pow (uV^2/Hz)');
% title(['PSD channel ' num2str(i)]);
% hold on
% plot(EEGfilt_psd.freq, EEGfilt_psd.powspctrm(i,:));
% end


EEG=EEGfilt;


%%ICA 

% extract ecg channels 

cfg=[];
cfg.channel = setdiff(data.label, { ...
    'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5', ...
    'FC1','FC2','FC6','T7','C3','Cz','C4','T8', ...
    'TP9','CP5','CP1','CP2','CP6','TP10','P7','P3','Pz','P4','P8', ...
    'PO9','O1','Oz','O2','PO10','EGG4','EGG5','EGG6'}); 

ECG = ft_preprocessing(cfg,data);
%
cfg = [];
dataICA = ft_appenddata(cfg, EEG, ECG)
% cfg.viewmode = 'vertical';
% cfg.continuous = 'yes'; 
% cfg.blocksize = 720
% cfg.ylim      = [-100 100]
% ft_databrowser(cfg,dataICA);
%

x=1 %input("load comp - 1 / new ICA - 2 ")
if x==2
    
    n=rank(dataICA.trial{1})
    cfg = [];
    cfg.method = 'runica';%fastica
    cfg.numcomponent = n
    data_comp= ft_componentanalysis(cfg, dataICA);  

    b=input('save ICA?: ','s')

    if b=='y'
    
    filename = sprintf('data_comp_raw_%03d.mat', num)
    filepath= 'ICA_comp_raw/' 
    filefull= [filepath filename]
    save(filefull,'data_comp');
    end
end
%
if x==1
    filename = sprintf('data_comp_raw_%03d.mat', num)
    pathname= 'ICA_comp_raw/' 
    fullpath = fullfile(pathname, filename);
    data_comp = load(fullpath);
    data_comp =data_comp.data_comp;
end

%-- PLOT COMPONENTS --
cfg = [];
cfg.layout = 'custom_32'; 
cfg.viewmode = 'component';
 
cfg.blocksize = 100;
ft_databrowser(cfg, data_comp)

datacomp=data_comp.trial{1};
ecg=ECG.trial{1};

%bad components selection

cfg = [];
cfg.channel = idx_comp_bad
data_comp_bad = ft_selectdata(cfg, data_comp);

%reconstruct EEG

cfg = [];
cfg.component = [idx_comp_bad]; 
datanew = ft_rejectcomponent(cfg, data_comp, dataICA)

cfg=[]
cfg.channel = setdiff(datanew.label, {'EGG1','EGG2','EGG3'});
EEGnew = ft_preprocessing(cfg,datanew);
%
cfg = [];
cfg.blocksize = 500;
ft_databrowser(cfg, EEGnew);

%% bad channel removal 

remove='y'
if remove== 'y'

cfg          = [];
cfg.method   = 'summary';
cfg.neighbours = 'custom32_neigh.mat'
EEGclean       = ft_rejectvisual(cfg, EEGnew);

badchans = setdiff(EEG_wavelet.label, EEGclean.label);
if length(badchans)>0
cfg = [];

cfg.blocksize = 500;
cfg.ylim=[-100 100];
ft_databrowser(cfg, EEGclean)

% interpolation

cfg = [];
cfg.method = 'template';
cfg.template = 'custom32_neigh.mat';
neig = ft_prepare_neighbours(cfg);

cfg = [];
cfg.badchannel = badchans;
cfg.method = 'spline';
cfg.neighbours = neig;
cfg.elec = 'standard_1020.elc'
EEG_interp = ft_channelrepair(cfg,EEGclean);

cfg = [];
cfg.layout    = 'biosemi32.lay';
cfg.blocksize = 500;
cfg.ylim=[-60 60];
ft_databrowser(cfg, EEG_interp)
EEG_wavelet=EEG_interp;
end
end

% re-referencing 

cfg = [];
cfg.channel = 'all'; % this is the default
cfg.reref = 'yes';
cfg.refmethod = 'avg';
cfg.refchannel = 'all';
EEG_avg = ft_preprocessing(cfg, EEG_wavelet);

EEG_processed=EEG_avg;

cfg = [];
cfg.blocksize = 30;
cfg.ylim=[-15 15];
ft_databrowser(cfg, EEG_processed)

