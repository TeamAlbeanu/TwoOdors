%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2015 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
% function OutcomePlot(AxesHandle,TrialTypeSides, OutcomeRecord, CurrentTrial)
function PavlovianTrialTypeOutcomePlot(AxesHandle, Action, varargin)
%% 
% Plug in to Plot trial type and trial outcome.
% AxesHandle = handle of axes to plot on
% Action = specific action for plot, "init" - initialize OR "update" -  update plot

%Example usage:
% TrialTypeOutcomePlot(AxesHandle,'init',TrialTypes)
% TrialTypeOutcomePlot(AxesHandle,'init',TrialTypes,'ntrials',90)
% TrialTypeOutcomePlot(AxesHandle,'update',CurrentTrial,TrialTypes,OutcomeRecord)

% varargins:
% TrialTypes: Vector of trial types (integers)
% OutcomeRecord:  Vector of trial outcomes
%                 Simplest case: 
%                               1: correct trial (green)
%                               0: incorrect trial (red)
%                 Advanced case: 
%                               NaN: future trial (blue)
%                                -1: withdrawal (red circle)
%                                 0: incorrect choice (red dot)
%                                 1: correct choice (green dot)
%                                 2: did not choose (green circle)
% OutcomeRecord can also be empty
% Current trial: the current trial number

% Adapted from BControl (SidesPlotSection.m) 
% Kachi O. 2014.Mar.17
% J. Sanders. 2015.Jun.6 - adapted to display trial types instead of sides

%% Code Starts Here
global nTrialsToShow %this is for convenience
global BpodSystem

switch Action
    case 'init'
        
        try
            close 'Outcome Plot';
        end
        
        %initialize pokes plot
        TrialTypeList = varargin{1}{1};
        RewardList = varargin{1}{2};
        PunishmentList = varargin{1}{3};
        
        nTrialsToShow = 90; %default number of trials to display
        
        if nargin > 3 %custom number of trials
            nTrialsToShow =varargin{3};
        end
        axes(AxesHandle);
        MaxTrialType = max(TrialTypeList);
               
        BpodSystem.GUIHandles.CurrentTrial = line([1,1],[-0.5, MaxTrialType+.5], 'LineStyle',':','Marker','none','color','k');

        %plot in specified axes
        %Xdata = 1:nTrialsToShow; Ydata = -TrialTypeList(Xdata);
        Xdata = 1:nTrialsToShow; 
        
        % plot all trials
        Ydata = TrialTypeList(Xdata)';
        BpodSystem.GUIHandles.FutureTrialLine = line([Xdata,Xdata],[Ydata,Ydata],'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        % overlay rewarded trials in blue
        Ydata = RewardList(Xdata)';
        BpodSystem.GUIHandles.FutureRewardedTrialLine = line([Xdata,Xdata],[Ydata,Ydata],'LineStyle','none','Marker','o','MarkerEdge','b','MarkerFace',[1 1 1], 'MarkerSize',6);
        % overlay punished trials in red
        Ydata = PunishmentList(Xdata)';
        BpodSystem.GUIHandles.FuturePunishmentTrialLine = line([Xdata,Xdata],[Ydata,Ydata],'LineStyle','none','Marker','o','MarkerEdge','m','MarkerFace',[1 1 1], 'MarkerSize',6);
        
        % create a plot handle for trial outcomes
        BpodSystem.GUIHandles.NoResponseLine = line([0,0],[-1,-1], 'LineStyle','none','Marker','o','MarkerEdge','none','MarkerFace','[1 1 1]', 'MarkerSize',4);
        BpodSystem.GUIHandles.RewardLicksLine = line([0,0],[-1,-1], 'LineStyle','none','Marker','o','MarkerEdge','none','MarkerFace','g', 'MarkerSize',4);
        BpodSystem.GUIHandles.PunishmentLicksLine = line([0,0],[-1,-1], 'LineStyle','none','Marker','o','MarkerEdge','none','MarkerFace','r', 'MarkerSize',4);
        BpodSystem.GUIHandles.CueAnticipatoryLicksLine = line([0,0],[-1,-1], 'LineStyle','none','Marker','s','MarkerEdge','r','MarkerFace','r', 'MarkerSize',4);
        BpodSystem.GUIHandles.DelayAnticipatoryLicksLine = line([0,0],[-1,-1], 'LineStyle','none','Marker','v','MarkerEdge','k','MarkerFace','k', 'MarkerSize',4);
        
        set(AxesHandle,'TickDir', 'out',...
            'YLim', [-0.5, MaxTrialType+.5], ...
            'YTick', 0:1:MaxTrialType,'YTickLabel', ['NoCue', strsplit(num2str(1:1:MaxTrialType))], 'FontSize', 10);
        xlabel(AxesHandle, 'Trial#', 'FontSize', 10);
        ylabel(AxesHandle, 'Trial Type', 'FontSize', 10);
        hold(AxesHandle, 'on');
        
        % legend
        plothandles = [BpodSystem.GUIHandles.FutureTrialLine, ...
            BpodSystem.GUIHandles.FutureRewardedTrialLine, ...
            BpodSystem.GUIHandles.FuturePunishmentTrialLine, ...
            BpodSystem.GUIHandles.RewardLicksLine, ...
            BpodSystem.GUIHandles.PunishmentLicksLine, ...
            BpodSystem.GUIHandles.CueAnticipatoryLicksLine, ...
            BpodSystem.GUIHandles.DelayAnticipatoryLicksLine];
        %TrialTypeString{1} = 'CurrentTrial';
        TrialTypeString{1} = 'NoReinforcer';
        TrialTypeString{2} = 'Rewarded';
        TrialTypeString{3} = 'Punished';
        %TrialTypeString{5} = 'NoResponse';
        TrialTypeString{4} = 'WaterLicks';
        TrialTypeString{5} = 'NoiseLicks';
        TrialTypeString{6} = 'CueLicks';
        TrialTypeString{7} = 'DelayLicks';
        legend(plothandles, TrialTypeString,...
            'Location','northoutside','Orientation','horizontal','boxoff');
        
        
    case 'update'
        CurrentTrial = varargin{1};
        TrialTypeList = varargin{2};
        RewardList = varargin{3};
        PunishmentList = varargin{4};
        OutcomeRecord = BpodSystem.Data.Outcomes';
        MaxTrialType = max(TrialTypeList);
        
        %set(AxesHandle,'YLim',[-MaxTrialType-.5, -.5], 'YTick', -MaxTrialType:1:-1,'YTickLabel', strsplit(num2str(MaxTrialType:-1:-1)));
        set(AxesHandle,'YLim', [-0.5, MaxTrialType+.5], 'YTick', 0:1:MaxTrialType,'YTickLabel', ['NoCue', strsplit(num2str(1:1:MaxTrialType))]);
        if CurrentTrial<1
            CurrentTrial = 1;
        end
        
        %TrialTypeList  = -TrialTypeList;
        % recompute xlim
        [mn, mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow);
        
        %axes(AxesHandle); %cla;
        %plot future trials
        %FutureTrialsIndx = CurrentTrial:mx;
        FutureTrialsIndx = mn:mx;
        Xdata = FutureTrialsIndx; 
        Ydata = TrialTypeList(Xdata)';
        set(BpodSystem.GUIHandles.FutureTrialLine, 'xdata', [Xdata,Xdata], 'ydata', [Ydata,Ydata]);
        Ydata = RewardList(Xdata)';
        set(BpodSystem.GUIHandles.FutureRewardedTrialLine, 'xdata', [Xdata,Xdata], 'ydata',[Ydata,Ydata]);
        Ydata = PunishmentList(Xdata)';
        set(BpodSystem.GUIHandles.FuturePunishmentTrialLine, 'xdata', [Xdata,Xdata], 'ydata',[Ydata,Ydata]);
        
        %Plot current trial
        set(BpodSystem.GUIHandles.CurrentTrial, 'xdata', [CurrentTrial,CurrentTrial]);
        
        %Plot past trials
        % OutcomeRecord
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
        if ~isempty(OutcomeRecord)
            indxToPlot = mn:CurrentTrial-1;
            % Plot Misses, no licks during reinforcer period
            NoLickTrialsIndx =(OutcomeRecord(indxToPlot,1) == 0);
            Xdata = indxToPlot(NoLickTrialsIndx); Ydata = TrialTypeList(Xdata)';
            set(BpodSystem.GUIHandles.NoResponseLine, 'xdata', [Xdata,Xdata], 'ydata', [Ydata,Ydata]);
            % Plot Reward Licks, licks during reward period
            RewardLickTrialsIndx =(OutcomeRecord(indxToPlot,1) == 1);
            Xdata = indxToPlot(RewardLickTrialsIndx); Ydata = TrialTypeList(Xdata)';
            set(BpodSystem.GUIHandles.RewardLicksLine, 'xdata', [Xdata,Xdata], 'ydata', [Ydata,Ydata]);
            % Plot Reward Licks, licks during reward period
            PunishmentLickTrialsIndx =(OutcomeRecord(indxToPlot,1) == 2);
            Xdata = indxToPlot(PunishmentLickTrialsIndx); Ydata = TrialTypeList(Xdata)';
            set(BpodSystem.GUIHandles.PunishmentLicksLine, 'xdata', [Xdata,Xdata], 'ydata', [Ydata,Ydata]);
            % Plot anticipatory Licks - Cue Period
            CueLickTrialsIndx = OutcomeRecord(indxToPlot,2) == 1;
            Xdata = indxToPlot(CueLickTrialsIndx); Ydata = TrialTypeList(Xdata)' - 0.2;
            set(BpodSystem.GUIHandles.CueAnticipatoryLicksLine, 'xdata', [Xdata,Xdata], 'ydata', [Ydata,Ydata]);
            % Plot anticipatory Licks - Cue Period
            DelayLickTrialsIndx = OutcomeRecord(indxToPlot,3) == 1;
            Xdata = indxToPlot(DelayLickTrialsIndx); Ydata = TrialTypeList(Xdata)' - 0.4;
            set(BpodSystem.GUIHandles.DelayAnticipatoryLicksLine, 'xdata', [Xdata,Xdata], 'ydata', [Ydata,Ydata]);
        end
end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end


