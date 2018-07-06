function [Data_Demod, Data_Raw] = OnlineDemodulation(rawData,refData,modFreq,modAmp,TimeToZero,thisTrial)

global BpodSystem S

decimateFactor      = S.GUI.DecimateFactor;
duration            = S.GUI.NidaqDuration;
sampleRate          = S.GUI.NidaqSamplingRate;
baseline_begin      = S.GUI.BaselineBegin;
baseline_end        = S.GUI.BaselineEnd;
% For filtering
lowCutoff           = 15;
pad                 = 1;

if S.GUI.Modulation
    %% Prepare reference data and generate 90deg shifted reference data
    % refData is the modulated LED waveform
    % rawData is unmodulated photoreceiver signal
    refData             = refData(1:length(rawData),1);   % match length of refData and rawData
    refData             = refData - mean(refData);          % remove DC offset
    samplesPerPeriod    = (1/modFreq)/(1/sampleRate);
    quarterPeriod       = round(samplesPerPeriod/4);
    refData90           = circshift(refData,[1 quarterPeriod]);

    %% Quadrature decoding and filtering
    processedData_0     = rawData .* refData;
    processedData_90    = rawData .* refData90;

    %% Filter
    lowCutoff = lowCutoff/(sampleRate/2); % normalized CutOff by half SampRate (see doc)
    [b, a] = butter(5, lowCutoff, 'low'); 

    % pad the data to suppress windows effect upon filtering
    if pad == 1
        paddedData_0        = processedData_0(1:sampleRate, 1);
        paddedData_90       = processedData_0(1:sampleRate, 1);
        demodDataFilt_0     = filtfilt(b,a,[paddedData_0; processedData_0]);
        demodDataFilt_90    = filtfilt(b,a,[paddedData_90; processedData_90]);        
        processedData_0     = demodDataFilt_0(sampleRate + 1: end, 1);
        processedData_90    = demodDataFilt_90(sampleRate + 1: end, 1);
    else
        processedData_0     = filtfilt(b,a,processedData_0);
        processedData_90    = filtfilt(b,a,processedData_90); 
    end
    
    demodData = (processedData_0 .^2 + processedData_90 .^2) .^(1/2);

    %% Correct for amplitude of reference
    demodData = demodData * 2/modAmp;
else
    demodData = rawData;
end

%% Expected Data set
SampRate        = sampleRate/decimateFactor;
ExpectedSize    = duration*SampRate;
Data            = NaN(ExpectedSize,1);
TempData        = decimate(demodData,decimateFactor);
Data(1:length(TempData)) = TempData;

%% DF/F calculation
Fbaseline = mean(Data(baseline_begin*SampRate:baseline_end*SampRate));
DFF       = 100*(Data-Fbaseline)/Fbaseline;

%% Time
Time        = linspace(0,duration,ExpectedSize);
Time        = Time' - TimeToZero;

%% Raw Data
ExpectedSizeRaw             = duration*sampleRate;
DataRaw                     = NaN(ExpectedSizeRaw,1);
DataRaw(1:length(rawData))  = rawData;

TimeRaw = linspace(0,duration,ExpectedSizeRaw);
TimeRaw = TimeRaw' - TimeToZero;

%% NewDataSet
Data_Demod(:,1)     = Time;
Data_Demod(:,2)     = Data;
Data_Demod(:,3)     = DFF;

Data_Raw(:,1)       = TimeRaw;
Data_Raw(:,2)       = DataRaw;
