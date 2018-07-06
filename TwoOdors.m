function TwoOdors
% This protocol is a starting point for a two odor pavlovian task
% Each trial starts with a variable 'No Lick period',
% during which the subject has to wait for the cue to arrive,
% Cues can be one of three cues A, B, C, or no cue
% followed by a delay
% followed by a reinforcer - water, white noise or nothing, with
% user-defined probablities
% Written by Priyanka Gupta, 5/2017.

% Wiring (Outputs)
% Wires (1-4): Blank, OdorA, OdorB, AirPuff
% BNCs (1-2): SyncOut, ~
% Port4: Port4In = LicksIN, ValveState8 = water;

%% dependencies
% TwoOdors_TaskParameters.m
% /Sounds/FakeSoundServer.m % if psychtoolbox is unavailable
% /utils/AlbeanuBpodParameterGUI.m
% /utils/ExtractLickTimeStamps
% /Plots/PavlovianTrialTypeOutcomePlot.m
% /Plots/PavlovianLickRasterPlot.m
% /Plots/OnlinePhotometryPlot.m
% /Photometry/NIDAQPhotometry.m (calls /Photometry/NIDAQ_callback.m, /Photometry/LED_modulation.m)
% /Photometry/OnlineDemodulation.m

global BpodSystem
global LickRasterWindow
global numplots
global S
global nidaq % for photometry data
global nTrialsToShow % for lickrasterplots
global nRows

%% Define parameters
%S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

% load settings from the previous session
Allfiles = dir(fileparts(BpodSystem.Path.CurrentDataFile));
try
    LastSession = load(fullfile(fileparts(BpodSystem.DataPath),Allfiles(end).name));
    S = LastSession.SessionData.TrialSettings(end);
catch % If settings file was an empty struct, populate struct with default settings
    TwoOdors_TaskParameters()
end
clear LastSession Allfiles

% Initialize parameter GUI plugin
AlbeanuBpodParameterGUI('init', S);
BpodSystem.Status.Pause = 1;
HandlePauseCondition;
S = AlbeanuBpodParameterGUI('sync', S);

%% Define trials
MaxTrials = S.GUI.MaxTrials;
pCuedTrials = 1 - S.GUI.pUnCuedReward - S.GUI.pUnCuedPunishment;
pCues = str2num(S.GUI.pCues_ABC);
pRewards = str2num(S.GUI.pRewards_ABC);
pPunish = str2num(S.GUI.pPunishment_ABC);
nCuedTrials = ceil(ceil(MaxTrials*pCuedTrials)*pCues);

% Trialtypes
% 0 = uncued trials
% 1,2,3 = cue A,B,C
%TrialTypes = ceil(rand(1,1000)*2);
TrialTypes =   [zeros(1,ceil(MaxTrials*S.GUI.pUnCuedReward)), ...
                zeros(1,ceil(MaxTrials*S.GUI.pUnCuedPunishment)), ...
                ones(1,nCuedTrials(1)), ...
                2*ones(1,nCuedTrials(2)), ...                
                3*ones(1,nCuedTrials(3)) ...
                ];

% randomize the trial list
random_order = randperm(numel(TrialTypes));
TrialTypes = TrialTypes(random_order)';

for i = 1:3
    Outcomes.(['Cue',num2str(i)]) = [ones(1,ceil(pRewards(i)*nCuedTrials(i))), ...
                -1*ones(1,ceil(pPunish(i)*nCuedTrials(i))), ...
                zeros(1,nCuedTrials(i) - (ceil(pRewards(i)*nCuedTrials(i)) + ceil(pPunish(i)*nCuedTrials(i))))];
    Outcomes.(['Cue',num2str(i)]) = Outcomes.(['Cue',num2str(i)])(randperm(nCuedTrials(i)));
end

ReinforcerTypes = [ones(1,ceil(MaxTrials*S.GUI.pUnCuedReward)), ...
                -1*ones(1,ceil(MaxTrials*S.GUI.pUnCuedPunishment)), ...
                Outcomes.Cue1, Outcomes.Cue2, Outcomes.Cue3];
ReinforcerTypes = ReinforcerTypes(random_order);
clear Outcomes

RewardedTrials = TrialTypes;
RewardedTrials(find(ReinforcerTypes~=1)) = NaN;

PunishedTrials = TrialTypes;
PunishedTrials(find(ReinforcerTypes~=-1)) = NaN;

ReinforcerTypes(ReinforcerTypes==-1) = 2;

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.Outcomes = []; % the outcome of each trial and anticipatory lick state will be added here

%% NIDAQ Initialization
Param.nidaqDev = S.GUI.DAQname;
if S.GUI.Photometry || S.GUI.Wheel
    NIDAQPhotometry('ini');
end

% for plots 
ScreenSize      = get(0,'ScreenSize');
FigurePosition.Outcomes  = [1 ScreenSize(2)+200 ScreenSize(3)*0.45 ScreenSize(4)*0.75];
FigurePosition.Photometry  = [ScreenSize(3)*1/2 ScreenSize(2)+200 ScreenSize(3)*0.45 ScreenSize(4)*0.75];
FigurePosition.Wheel  = [ScreenSize(3)*2/3 ScreenSize(2)+40 ScreenSize(3)*1/3 300];

%% Initialize plot - trial outcomes and lick rasters
nTrialsToShow = S.GUI.Trials2Show;
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', FigurePosition.Outcomes, ...% [200 200 1000 600],...
    'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');

SessionSummary = sprintf('%s : %s -- %s',...
    date, BpodSystem.GUIData.SubjectName, ...
    BpodSystem.GUIData.ProtocolName);
SessionLegend=uicontrol('style','text');
set(SessionLegend,'String',SessionSummary);
set(SessionLegend,'Position',[10,1,400,20]);
        
numplots = numel(find(pCues));

%BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .8 .89 .15]);
temp = [(pCues.*pRewards); (pCues.*pPunish)];
nRows = 3;
for i = 1:3
    if numel(find(temp(:,i)))>1
        nRows = 4;
        break;
    end
end

% trial outcome figure
BpodSystem.GUIHandles.SideOutcomePlot = subplot(nRows,numplots,[1:numplots]);

% lick rasters
for i = 1:3
    if pCues(i) > 0
        BpodSystem.GUIHandles.(['Cue',num2str(i),'ReinforcerPlot']) = subplot(nRows,numplots,numplots + i);
        if nRows > 3
            title(['Cue',num2str(i),' : ReinforcerA']);
            BpodSystem.GUIHandles.(['Cue',num2str(i),'Reinforcer2Plot']) = subplot(nRows,numplots,2*numplots + i);
            title(['Cue',num2str(i),' : ReinforcerB']);
            BpodSystem.GUIHandles.(['Cue',num2str(i),'NoReinforcerPlot']) = subplot(nRows,numplots,3*numplots + i);
            title(['Cue',num2str(i),' : NoReinforcer']);
        else
            title(['Cue',num2str(i),' : Reinforcer']);
            BpodSystem.GUIHandles.(['Cue',num2str(i),'NoReinforcerPlot']) = subplot(nRows,numplots,2*numplots + i);
            title(['Cue',num2str(i),' : NoReinforcer']);
        end
    end
end

PavlovianTrialTypeOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'init',{TrialTypes, RewardedTrials, PunishedTrials});

% LickRasterWindow
LickRasterWindow = [-1 4];
PavlovianLickRasterPlot(BpodSystem.GUIHandles, 'init');
StateToAlignTo = S.GUI.AlignLicksTo;

%% Initialize plot - photometry
%if S.GUI.Photometry
    
    try
        close 'Photometry plot'
    end
    
    BpodSystem.ProtocolFigures.PhotometryFig = figure('Position', FigurePosition.Photometry, ...%[210 210 1000 500],...
    'name','Photometry plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
    
    SessionLegend = uicontrol('style','text');
    set(SessionLegend,'String',SessionSummary);
    set(SessionLegend,'Position',[10,1,400,20]);
    
    % current trial
    BpodSystem.GUIHandles.CurrentTrialPhotometryPlot = subplot(nRows,numplots,[1:numplots]);

    % individual trial types
    for i = 1:3
        if pCues(i) > 0
            BpodSystem.GUIHandles.(['Cue',num2str(i),'ReinforcerPhotometryPlot']) = subplot(nRows,numplots,numplots + i);
            if nRows > 3
                title(['Cue',num2str(i),' : ReinforcerA']);
                BpodSystem.GUIHandles.(['Cue',num2str(i),'Reinforcer2PhotometryPlot']) = subplot(nRows,numplots,2*numplots + i);
                title(['Cue',num2str(i),' : ReinforcerB']);
                BpodSystem.GUIHandles.(['Cue',num2str(i),'NoReinforcerPhotometryPlot']) = subplot(nRows,numplots,3*numplots + i);
                title(['Cue',num2str(i),' : NoReinforcer']);
            else
                title(['Cue',num2str(i),' : Reinforcer']);
                BpodSystem.GUIHandles.(['Cue',num2str(i),'NoReinforcerPhotometryPlot']) = subplot(nRows,numplots,2*numplots + i);
                title(['Cue',num2str(i),' : NoReinforcer']);
            end
        end
    end
    
    OnlinePhotometryPlot(BpodSystem.GUIHandles, 'init');
    
%end

if S.GUI.Wheel
    % OnlineWheelPlot('ini');
end

%% Program Fake Sound Server
%SoundSamplingRate = 48000;  % Sound card sampling rate;
SoundSamplingRate = 192000;
AttenuationFactor = .5;
PunishSound = (rand(1,SoundSamplingRate*.5)*AttenuationFactor) - AttenuationFactor*.5;

% Program sound server
FakeSoundServer('init')
FakeSoundServer('Load', 2, 0);
FakeSoundServer('Load', 3, PunishSound);
% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

%% Main trial loop
for currentTrial = 1:MaxTrials
    S = AlbeanuBpodParameterGUI('sync', S); % Sync parameters with AlbeanuBpodParameterGUI plugin
    
    if S.GUI.UseWaterCalibration
        ValveTime = GetValveTimes(S.GUI.RewardAmount, [1 3]); % Update reward amounts
        %LeftValveTime = R(1); 
        %RightValveTime = R(2); 
    else
        ValveTime = S.GUI.RewardDuration;
    end
    
    % compute ITI and delay durations
    ITIRange = str2num(S.GUI.ITI_offset_mean_max);
    CurrentITI = ITIRange(3)+1;
    while CurrentITI > ITIRange(3)
        CurrentITI = exprnd(ITIRange(2));
    end
    CurrentITI = CurrentITI + ITIRange(1);
    
    DelayRange = str2num(S.GUI.Delay_offset_mean_max);
    CurrentDelay = DelayRange(3)+1;
    while CurrentDelay > DelayRange(3)
        CurrentDelay = exprnd(DelayRange(2));
    end
    CurrentDelay = CurrentDelay + DelayRange(1);
    
    CurrentCueDuration = S.GUI.CueDuration; 
    
    switch ReinforcerTypes(currentTrial) % Determine trial-specific state matrix fields
        case 0
            Reinforcer = 'NoReinforcer';
            PunishDuration = 0;
            PunishAction = {};
        case 1
            Reinforcer = 'Reward';
            S.GUI.WaterDispensed = S.GUI.WaterDispensed + S.GUI.RewardAmount;
            PunishDuration = 0;
            PunishAction = {};
        case 2
            Reinforcer = 'Punishment';
            if S.GUI.UseAirPuff
                PunishDuration = S.GUI.AirPuffDuration;
                PunishAction = {'WireState', 8};
            else
                PunishDuration = S.GUI.NoiseDuration;
                FakeSoundServer('Load', 3, S.GUI.NoiseAmplitude*PunishSound);
                PunishAction = {'SoftCode', 3};
            end
    end
    
    if TrialTypes(currentTrial)>0 % Determine trial-specific state matrix fields
        switch TrialTypes(currentTrial)
            case 1
                CueAction = {'WireState', 4};
            case 2
                CueAction = {'WireState', 2};
            case 3
                CueAction = {'WireState', 0};
            otherwise
                CueAction = {'WireState', 0};
        end
    else
        CueAction = {};
    end
    
    if S.GUI.SyncOut
        SendSyncOutAction = {'BNCState', 1};
    else
        SendSyncOutAction = {};
    end
    
    sma = NewStateMatrix(); % Assemble state matrix
    
    if S.GUI.AllowLicksDuringITI % restart ITI if animal licks, else move to Cue State
        sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', CurrentITI,...
        'StateChangeConditions', {'Tup', 'Cue'},...
        'OutputActions', SendSyncOutAction);
    else
        sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', CurrentITI,...
        'StateChangeConditions', {'Port4In', 'ITI', 'Tup', 'Cue'},...
        'OutputActions', SendSyncOutAction); 
    end
    
    % pavlovian?
    if S.GUI.TrainingPhase == 6
        PostDelayState = 'Response';
    else
        PostDelayState = Reinforcer;
    end

    sma = AddState(sma, 'Name', 'Cue', ...
        'Timer', S.GUI.CueDuration,...
        'StateChangeConditions', {'Tup', 'Delay'},...
        'OutputActions', CueAction); 
    
    sma = AddState(sma, 'Name', 'Delay', ...
        'Timer', CurrentDelay,...
        'StateChangeConditions', {'Tup', PostDelayState},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'Response', ...
        'Timer', S.GUI.ResponseTimeOut,...
        'StateChangeConditions', {'Port4In', Reinforcer, 'Tup', 'exit'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'Punishment', ...
        'Timer', PunishDuration,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', PunishAction);
    
    sma = AddState(sma, 'Name', 'NoReinforcer', ...
        'Timer', S.GUI.NoiseDuration,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'Reward', ...
        'Timer', ValveTime,...
        'StateChangeConditions', {'Port4In', 'Drinking', 'Tup', 'DrinkingGrace'},...
        'OutputActions', {'ValveState', 8});
    
    sma = AddState(sma, 'Name', 'Drinking', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port4Out', 'DrinkingGrace'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'DrinkingGrace', ...
        'Timer', .5,...
        'StateChangeConditions', {'Tup', 'PostOutcome', 'Port4In', 'Drinking'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'PostOutcome', ...
        'Timer', S.GUI.PostOutcome,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});

    SendStateMatrix(sma);

    %% Start NIDAQ in the background
    if S.GUI.Photometry || S.GUI.Wheel
        NIDAQPhotometry('Start');
    end

    RawEvents = RunStateMatrix;

    %% NIDAQ Stop acquisition and save data in bpod structure
    if S.GUI.Photometry
        NIDAQPhotometry('Stop');
        [Photoreceiver1Data, WheelData, Photoreceiver2Data] = NIDAQPhotometry('Save');
        if S.GUI.Photometry
            BpodSystem.Data.Photoreceiver1Data{currentTrial} = Photoreceiver1Data;
            if S.GUI.TwoFibers
                BpodSystem.Data.Photoreceiver2Data{currentTrial} = Photoreceiver2Data;
            end
        end
        if S.GUI.Wheel
            BpodSystem.Data.WheelData{currentTrial} = WheelData;
        end
    end
    
    % Process behavioral data from the trial
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = 10*TrialTypes(currentTrial) + ReinforcerTypes(currentTrial); % Adds the trial type and reinforcer type of the current trial to data
        [TimeToAlignTo] = UpdateSideOutcomePlot(...
            currentTrial,ReinforcerTypes(currentTrial),TrialTypes,ReinforcerTypes,...
            RewardedTrials, PunishedTrials, BpodSystem.Data, StateToAlignTo);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end

    if S.GUI.Photometry
        if S.GUI.Modulation
            [currentNidaq470, nidaqRaw] = ...
                OnlineDemodulation(Photoreceiver1Data(:,1), nidaq.LED1, S.GUI.LED.LED1(3), S.GUI.LED.LED1(2),...
                    TimeToAlignTo, currentTrial);
        end
        if S.GUI.LED.LED2(2) ~= 0
            currentNidaq405 = ...
                OnlineDemodulation(Photoreceiver1Data(:,1), nidaq.LED2, S.GUI.LED.LED2(3), S.GUI.LED.LED2(2),...
                    TimeToAlignTo,currentTrial);
        else
            currentNidaq405 = [0 0];
        end
        if S.GUI.TwoFibers
            % choose the appropriate LED!!!
            [currentNidaq470b, nidaqRawb] = ...
                OnlineDemodulation(Photoreceiver2Data(:,1), nidaq.LED1, S.GUI.LED.LED1(3), S.GUI.LED.LED1(2),...
                    TimeToAlignTo, currentTrial);
        end

        % Plotting
        % determine which subplot to refresh based on 
        % the current Cue type and reinforcer type
        if ReinforcerTypes(currentTrial) > 0
            if (nRows > 3 && ReinforcerTypes(currentTrial) == 2)
                AxesTag = ['Cue',num2str(TrialTypes(currentTrial)),'Reinforcer2PhotometryPlot'];
            else
                AxesTag = ['Cue',num2str(TrialTypes(currentTrial)),'ReinforcerPhotometryPlot'];
            end
        else
            AxesTag = ['Cue',num2str(TrialTypes(currentTrial)),'NoReinforcerPhotometryPlot'];
        end
        
        OnlinePhotometryPlot(BpodSystem.GUIHandles, 'update', ...
            AxesTag, currentNidaq470, currentNidaq405, nidaqRaw);

        if S.GUI.TwoFibers
            OnlinePhotometryPlot(BpodSystem.GUIHandles, 'update', ...
                        AxesTag, currentNidaq470b, currentNidaq405, nidaqRawb);
        end

    end
    
    if S.GUI.Wheel
        % OnlineWheelPlot('update');
    end

    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        FakeSoundServer('close');
        return
    end
    
    nTrialsToShow = S.GUI.Trials2Show;
    
end

function [TimeToAlignTo] = UpdateSideOutcomePlot(currentTrial,currentTrialType,TrialTypes,ReinforcerTypes,RewardedTrials,PunishedTrials,Data,StateToAlignTo)
    global BpodSystem
    global nRows

    % compute trial outcome and extract lick timestamps
    [LickEvents, OtherEvents, TimeToAlignTo] = ExtractLickTimeStamps(currentTrialType,currentTrial,StateToAlignTo);

    % Update Trial Outcome Plot
    PavlovianTrialTypeOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,...
        'update',Data.nTrials+1,TrialTypes,RewardedTrials,PunishedTrials);

    if TrialTypes(currentTrial)>0
        % Update Lick Raster Plot
        % determine which subplot to refresh based on 
        % the current Cue type and reinforcer type
        if ReinforcerTypes(currentTrial) > 0
            if (nRows > 3 && ReinforcerTypes(currentTrial) == 2)
                AxesTag = BpodSystem.GUIHandles.(['Cue',num2str(TrialTypes(currentTrial)),'Reinforcer2Plot']);
            else
                AxesTag = BpodSystem.GUIHandles.(['Cue',num2str(TrialTypes(currentTrial)),'ReinforcerPlot']);
            end
        else
    	   AxesTag = BpodSystem.GUIHandles.(['Cue',num2str(TrialTypes(currentTrial)),'NoReinforcerPlot']);
        end

    PavlovianLickRasterPlot(BpodSystem.GUIHandles, 'update', AxesTag, LickEvents, OtherEvents, ReinforcerTypes(currentTrial),currentTrial);
    end
