function [LickEvents, OtherEvents, TimeToAlignTo] = ExtractLickTimeStamps(currentTrialType, currentTrial, StateToAlignTo)

%This function extracts the outcome (licked post reinforcer or not) and the
%licking timestamps to update the Trial and licks plots, respectively. 
%The timestamp of lickEvents output is normalized to the timing of the event 
%specified by the input argument "StateToAlignTo" (cue or reward)
%
%Output arguments can be used as an input argument for Online_LickPlot function.
%
%function written by Quentin
%modified by Priyanka for TENSSTwoTonePavlovian protocol

global BpodSystem

% Outcomes
% column 1
% 0 = no licks during reinforcer period
% 1 = licks during reward period
% 2 = licks during white noise period
% column 2
% 0 = no anticipatory licking in the Cue or Delay period
% 1 = anticipatory licking in the Cue period
% column 3
% 0 = no anticipatory licking in the Delay period
% 1 = anticipatory licking in the Delay period

%% Extract Lick Timestamps for the entire trial
LickEvents = NaN;
if isfield(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.Events, 'Port4In')
    LickEvents = BpodSystem.Data.RawEvents.Trial{1,currentTrial}.Events.Port4In;
end

%% Count licks during the relevant states - Cue, Delay, Reinforcer
% log state start timestamps for marking the lick raster plot
t = BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Cue;
BpodSystem.Data.Outcomes(2,currentTrial) = any((LickEvents>=t(1))&(LickEvents<=t(2)));
OtherEvents(1) = t(1); % Cue start
t = BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Delay;
BpodSystem.Data.Outcomes(3,currentTrial) = any((LickEvents>=t(1))&(LickEvents<=t(2)));
OtherEvents(2) = t(1); % Delay start

% Choose reinforcer state based on trial type
switch currentTrialType
    case 0 % No reinforcer
        t = BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.NoReinforcer;
        if any((LickEvents>=t(1))&(LickEvents<=t(2)))
            BpodSystem.Data.Outcomes(3,currentTrial) = 1;
        end
    case 1 % rewarded
        t = BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Reward;
        if ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Drinking(1))
            BpodSystem.Data.Outcomes(1,currentTrial) = 1;
        end
    case 2 % punished
        t = BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Punishment;
        if any((LickEvents>=t(1))&(LickEvents<=t(2)))
            BpodSystem.Data.Outcomes(1,currentTrial) = 2;
        end
end

OtherEvents(3) = t(1); % reinforcer start
TimeToAlignTo = OtherEvents(StateToAlignTo);

% Align Lick TimeStamps to Desired state
% 1 - Cue, 2 - Delay, 3 - Reinforcer
if any(~isnan(LickEvents))
    LickEvents = LickEvents - OtherEvents(StateToAlignTo);
end

% Align Event TimeStamps to Desired state
OtherEvents = OtherEvents - OtherEvents(StateToAlignTo);

end

