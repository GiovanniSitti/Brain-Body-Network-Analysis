This repository contains an analysis pipeline for investigating electrophysiological interactions between the brain, heart, and gut in humans during resting state using simultaneous electroencephalographic (EEG), electrocardiographic (ECG), and electrogastrographic (EGG) recordings.

Time-resolved physiological markers were extracted for each organ, including EEG alpha-band power, cardiac sympathetic and parasympathetic indices (CSI, CPI), and gastric rhythm power. 

Coupling between physiological time series was quantified using the Maximal Information Coefficient (MIC) across extended temporal delays, followed by surrogate-based statistical testing to identify significant interactions.

The resulting significant couplings were integrated to reconstruct large-scale electrophysiological networks summarizing the strength, temporal delays, and directionality of interactions among the brain, heart, and gut.

# Repository Structure

processing/  
├── eeg_processing/  
├── ecg_processing/  
└── egg_processing/  

coupling_analysis/  

graph_reconstruction/  

# Tools and Libraries

The analysis pipeline was developed using:
- MATLAB
- FieldTrip toolbox
- MINEpy (Maximal Information-based Nonparametric Exploration)

# Citation

If you use this repository or code in your research, please cite:

Sitti G., Pitti L., Candia-Rivera D.  
*Infra-slow brain–heart–gut electrophysiological interactions reveal a coordinated multisystem physiological network in humans*.  
DOI: https://doi.org/10.64898/2026.04.15.718683
