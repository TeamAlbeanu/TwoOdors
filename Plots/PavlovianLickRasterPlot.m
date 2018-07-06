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
function PavlovianLickRasterPlot(AxesHandle, Action, varargin)
%%
% Plug in to LickRasters
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
global LickRasterWindow

switch Action
    case 'init'
        
        % nTrialsToShow = 90; %default number of trials to display
        
        % Remove ticks, set fonts etc
        j = 0;
        for i = 1:3
            if isfield(AxesHandle, ['Cue',num2str(i),'ReinforcerPlot'])
                if isvalid(AxesHandle.(['Cue',num2str(i),'ReinforcerPlot']))
                    j = j + 1;
                    set(AxesHandle.(['Cue',num2str(i),'ReinforcerPlot']),...
                        'TickDir', 'out', 'YLim', [0, nTrialsToShow+1], ...
                        'XLim', LickRasterWindow, 'XTick', [LickRasterWindow(1) 0 LickRasterWindow(2)],...
                        'YTick', [1, nTrialsToShow],'FontSize', 10);
                    hold(AxesHandle.(['Cue',num2str(i),'ReinforcerPlot']), 'on');
                    
                    if isfield(AxesHandle, ['Cue',num2str(i),'Reinforcer2Plot'])
                        if isvalid(AxesHandle.(['Cue',num2str(i),'Reinforcer2Plot']))
                            set(AxesHandle.(['Cue',num2str(i),'Reinforcer2Plot']),...
                                'TickDir', 'out', 'YLim', [0, nTrialsToShow+1], ...
                                'XLim', LickRasterWindow, 'XTick', [LickRasterWindow(1) 0 LickRasterWindow(2)],...
                                'YTick', [1, nTrialsToShow],'FontSize', 10);
                            hold(AxesHandle.(['Cue',num2str(i),'Reinforcer2Plot']), 'on');
                        end
                    end
                    
                    set(AxesHandle.(['Cue',num2str(i),'NoReinforcerPlot']),...
                        'TickDir', 'out', 'YLim', [0, nTrialsToShow+1], ...
                        'XLim', LickRasterWindow, 'XTick', [LickRasterWindow(1) 0 LickRasterWindow(2)],...
                        'YTick', [1, nTrialsToShow],'FontSize', 10);
                    hold(AxesHandle.(['Cue',num2str(i),'NoReinforcerPlot']), 'on');
                    xlabel(AxesHandle.(['Cue',num2str(i),'NoReinforcerPlot']),'Time from reward / cue (sec)','FontSize', 10);
                    
                    if j == 1
                        set(AxesHandle.(['Cue',num2str(i),'ReinforcerPlot']),...
                            'YTickLabel',strsplit(num2str([1, nTrialsToShow])));
                        ylabel(AxesHandle.(['Cue',num2str(i),'ReinforcerPlot']),'Trial#','FontSize', 10);
                        
                        if isfield(AxesHandle, ['Cue',num2str(i),'Reinforcer2Plot'])
                            if isvalid(AxesHandle.(['Cue',num2str(i),'Reinforcer2Plot']))
                                set(AxesHandle.(['Cue',num2str(i),'Reinforcer2Plot']),...
                                    'YTickLabel',strsplit(num2str([1, nTrialsToShow])));
                                ylabel(AxesHandle.(['Cue',num2str(i),'Reinforcer2Plot']),'Trial#','FontSize', 10);
                            end
                        end
                        
                        set(AxesHandle.(['Cue',num2str(i),'NoReinforcerPlot']),...
                            'YTickLabel',strsplit(num2str([1, nTrialsToShow])));
                        ylabel(AxesHandle.(['Cue',num2str(i),'NoReinforcerPlot']),'Trial#','FontSize', 10);
                    else
                        set(AxesHandle.(['Cue',num2str(i),'ReinforcerPlot']),...
                            'YTickLabel',[]);
                        set(AxesHandle.(['Cue',num2str(i),'NoReinforcerPlot']),...
                            'YTickLabel',[]);
                    end
                end
            end
        end
        
    case 'update'
        AxesTag = varargin{1};
        LickEvents = varargin{2};
        if ~iscolumn(LickEvents)
            LickEvents = LickEvents';
        end
        OtherEvents = varargin{3};
        ReinforcerType = varargin{4};
        CurrentTrial = varargin{5};
        
        if CurrentTrial<1
            CurrentTrial = 1;
        end
        
        % recompute xlim
        [mn, mx] = rescaleX(AxesTag,CurrentTrial,nTrialsToShow);
        
        % update all subplots if needed
        if mx > AxesTag.YLim(2)
            plot_tags = {'ReinforcerPlot', 'Reinforcer2Plot', 'NoReinforcerPlot'};
            for i = 1:3
                for plottype = 1:3
                    if isfield(AxesHandle, ['Cue',num2str(i),plot_tags{plottype}])
                        set(AxesHandle.(['Cue',num2str(i),plot_tags{plottype}]),...
                            'YLim', [mn-1, mx+1],'YTick', [mn, mx],...
                            'YTickLabel', strsplit(num2str([mn, mx])));
                    end
                end
                %                 if isfield(AxesHandle, ['Cue',num2str(i),'ReinforcerPlot'])
                %                     set(AxesHandle.(['Cue',num2str(i),'ReinforcerPlot']),...
                %                         'YLim', [mn-1, mx+1],'YTick', [mn, mx],...
                %                         'YTickLabel', strsplit(num2str([mn, mx])));
                %                     set(AxesHandle.(['Cue',num2str(i),'NoReinforcerPlot']),...
                %                         'YLim', [mn-1, mx+1],'YTick', [mn, mx],...
                %                         'YTickLabel', strsplit(num2str([mn, mx])));
                %                 end
            end
        end
        
        
        axes(AxesTag);
        
        % Plot Cue (until delay start)
        Ydata = [-0.3 0.3] + CurrentTrial;
        Ydata = [Ydata(1) Ydata(1) Ydata(2) Ydata(2)];
        Xdata = [OtherEvents(1:2) fliplr(OtherEvents(1:2))];
        patch(Xdata,Ydata,'y','EdgeColor','none');
        
        Ydata = [-0.3 0.3] + CurrentTrial;
        % Plot lick events
        if any(~isnan(LickEvents))
            Xdata = repmat(LickEvents,1,2);
            Ydata = repmat([-0.5 0.5],numel(LickEvents),1) + CurrentTrial;
            line(Xdata',Ydata','color','k','Linewidth',1.5)
        end
%         %Plot other events
%         Ydata = [-0.3 0.3] + CurrentTrial;
%         Cue - magenta, Delay - blue, reinforcer - green/red
%         Xdata = repmat(OtherEvents(1),1,2);
%         line(Xdata',Ydata','color','m','Linewidth',1); % Cue
%         Xdata = repmat(OtherEvents(2),1,2);
%         line(Xdata',Ydata','color','b','Linewidth',1); % Delay
        
        switch ReinforcerType
            case 0
            case 1
                Xdata = repmat(OtherEvents(3),1,2);
                line(Xdata',Ydata','color','g','Linewidth',1); % reward
            case 2
                Xdata = repmat(OtherEvents(3),1,2);
                line(Xdata',Ydata','color','r','Linewidth',1); % punishment
        end
end

end

function [mn,mx] = rescaleX(AxesTag,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
%set(AxesTag,'YLim',[mn-1 mx+1]);
end


