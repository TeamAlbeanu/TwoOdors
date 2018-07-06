function TwoOdors_TaskParameters()
% load Task parameters
% modified by Priyanka (CSHL): July 3, 2018

global S

% hack to get rid of any parameters 
% that are not used in current version of the code
S.GUI = [];
S.GUIPanels = [];
S.GUITabs = [];

S.GUI.WaterDispensed = 0;

% Training phase
S.Names.TrainingPhase = {'CueA-Reward', 'CueB-Reward', ...
    'CueA-Reward-CueB-Punish' , 'CueA-Punish-CueB-Reward', ...
    'CueA-CueB-CueC','GoNoGo'};
S.GUI.TrainingPhase = 5;
S.GUIMeta.TrainingPhase.Style = 'popupmenu';
S.GUIMeta.TrainingPhase.String = S.Names.TrainingPhase;
S.GUI.MaxTrials = 300;
S.GUI.Photometry = 1;
S.GUIMeta.Photometry.Style = 'checkbox';
S.GUIMeta.Photometry.String = 'Auto';
S.GUI.Modulation = 1;
S.GUIMeta.Modulation.Style = 'checkbox';
S.GUIMeta.Modulation.String = 'Auto';
S.GUI.Wheel = 1;
S.GUIMeta.Wheel.Style = 'checkbox';
S.GUIMeta.Wheel.String = 'Auto';
S.GUI.SyncOut = 1;
S.GUIMeta.SyncOut.Style = 'checkbox';

S.GUIPanels.General = {'WaterDispensed','TrainingPhase',...
    'MaxTrials','Photometry','Modulation','Wheel','SyncOut'};

%S.GUITabs.General={'General'};

% TaskTiming
S.GUI.CueDuration = 1; %s, duration of the sound stimulus
S.GUI.ResponseTimeOut = 1; %s
S.GUI.PostOutcome = 2; %s

S.GUI.ITI_offset_mean_max = [2 3 5]; %s
S.GUIMeta.ITI_offset_mean_max.Style = 'vectortext';
S.GUI.Delay_offset_mean_max = [0.5 1 2]; %s, How long after the Cue should the reinforcer be presented
S.GUIMeta.Delay_offset_mean_max.Style = 'vectortext';

S.GUI.AllowLicksDuringITI = 1; % Is the subject required to withhold licking during the ITI
S.GUIMeta.AllowLicksDuringITI.Style = 'checkbox';

S.GUIPanels.TaskTiming = {'CueDuration','ResponseTimeOut','PostOutcome',...
    'ITI_offset_mean_max','Delay_offset_mean_max','AllowLicksDuringITI'};

S.GUITabs.TaskStructure = {'TaskTiming','General'};

% Reinforcers
S.GUI.UseWaterCalibration = 0; % use the calibration table
S.GUIMeta.UseWaterCalibration.Style = 'checkbox';
S.GUI.RewardAmount = 4; %uL
S.GUI.RewardDuration = 0.04; %s
S.GUI.UseAirPuff = 1;
S.GUIMeta.UseAirPuff.Style = 'checkbox';
S.GUI.AirPuffDuration = 1; %s
S.GUI.NoiseAmplitude = 0.1;
S.GUI.NoiseDuration = 1; %s

S.GUIPanels.Reinforcers = {'UseWaterCalibration','RewardAmount','RewardDuration',...
    'UseAirPuff','AirPuffDuration',...
    'NoiseAmplitude','NoiseDuration'};

% Stimulus Probabilities
S.GUI.pCues_ABC = [0.5 0.5 0]; % 3 cues - total must sum to 1
S.GUIMeta.pCues_ABC.Style = 'vectortext';
S.GUI.pRewards_ABC = [1 0 0]; % chance of getting a reward following a given Cue type
S.GUIMeta.pRewards_ABC.Style = 'vectortext';
S.GUI.pPunishment_ABC = [0 0 0]; % chance of getting a whitenoise following a given Cue type
S.GUIMeta.pPunishment_ABC.Style = 'vectortext';
S.GUI.pUnCuedReward = 0; % fraction of trials when +ve reinforcer is presented without a preceding Cue
S.GUI.pUnCuedPunishment = 0; % fraction of trials when -ve reinforcer is presented without a preceding Cue

S.GUIPanels.StimulusProbabilities = {'pCues_ABC','pRewards_ABC','pPunishment_ABC',...
    'pUnCuedReward','pUnCuedPunishment'};

S.GUITabs.Stimuli_Reinforcers = {'Reinforcers', 'StimulusProbabilities'};

S.GUI.DAQname = 'Dev1';
S.GUIMeta.DAQname.Style = 'edittext';
S.GUI.NidaqDuration = 15;
S.GUI.NidaqSamplingRate = 6100;
S.GUI.TwoFibers = 0;
S.GUIMeta.TwoFibers.Style = 'checkbox';
S.GUI.LED.LED1 = [470, 0.6, 211]'; % wavelength, amplitude, frequency
S.GUI.LED.LED2 = [405, 0, 531]'; % wavelength, amplitude, frequency
S.GUIMeta.LED.Style = 'table';
S.GUIMeta.LED.ColumnLabel = {'LED1', 'LED2'};
S.GUIMeta.LED.RowLabel = {'nm', 'V', 'Hz'};
% S.GUI.LED1_Wavelength = 470;
% S.GUI.LED1_Amp = 0.6;
% S.GUI.LED1_Freq = 211;
% S.GUI.LED2_Wavelength = 405;
% S.GUI.LED2_Amp = 0; %1.5
% S.GUI.LED2_Freq = 531;

S.GUIPanels.Photometry={'LED','DAQname','NidaqDuration','NidaqSamplingRate','TwoFibers'};%,...
    %'LED1_Wavelength','LED1_Amp','LED1_Freq',...
    %'LED2_Wavelength','LED2_Amp','LED2_Freq'};

%S.GUITabs.Photometry={'Photometry'};

S.GUI.AlignLicksTo = 1;
S.Names.AlignLicksTo = {'CueStart', 'DelayStart', 'ReinforcerStart'};
S.GUIMeta.AlignLicksTo.Style = 'popupmenu';
S.GUIMeta.AlignLicksTo.String = S.Names.AlignLicksTo; % for plotting
S.GUI.Trials2Show = 90; % for plotting
S.GUI.DecimateFactor = 100; % for demodulation
S.GUI.BaselineBegin = 1; % for demodulation
S.GUI.BaselineEnd = 2; % for demodulation
S.GUI.NidaqMin = -5; % for plotting
S.GUI.NidaqMax = 10; % for plotting

S.GUIPanels.Plots = {'AlignLicksTo','Trials2Show','DecimateFactor',...
    'NidaqMin','NidaqMax','BaselineBegin','BaselineEnd'};

S.GUITabs.Photometry = {'Plots','Photometry'};

end
