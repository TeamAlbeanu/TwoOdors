function OnlinePhotometryPlot(AxesHandle, action, varargin)

global BpodSystem S

%% general ploting parameters
label_x         = 'Time (sec)';
label_y         = 'dF/F';
%XLims           = [S.GUI.TimeMin S.GUI.TimeMax];
XLims = [-1 4];
xstep           = 1;    
xtickvalues     = XLims(1):xstep:XLims(2);
YLims           = [S.GUI.NidaqMin S.GUI.NidaqMax];
MeanThickness   = 2;

switch action
    case 'init'

        %% Current trial plot
        MyAxes = AxesHandle.('CurrentTrialPhotometryPlot');
        axes(MyAxes);
        hold on

        % create a plot handle for each photometry trace
        %AxesHandle.lastplotRaw = plot([-5 5],[0 0],'-k');
        BpodSystem.GUIHandles.lastplotRaw = plot([-5 5],[0 0],'-k');
        BpodSystem.GUIHandles.lastplot470 = plot([-5 5],[0 0],'-g','LineWidth',MeanThickness);
        BpodSystem.GUIHandles.lastplot405 = plot([-5 5],[0 0],'-r','LineWidth',MeanThickness);
        set(MyAxes,'XLim',XLims,'XTick',xtickvalues);
        title('current trial');
        xlabel(label_x); 
        ylabel('Volts');
        ylim auto;
                
        % legend
        plothandles = [BpodSystem.GUIHandles.lastplotRaw, ...
                    BpodSystem.GUIHandles.lastplot470, ...
                    BpodSystem.GUIHandles.lastplot405];
        TraceTypeString{1} = 'Raw';
        TraceTypeString{2} = '470nm';
        TraceTypeString{3} = '405nm';
        legend(plothandles, TraceTypeString,...
            'Location','northoutside','Orientation','horizontal','boxoff');
        

        %% TrialType specific plots
        % Remove ticks, set fonts etc
        j = 0;
        for i = 1:3
            if isfield(AxesHandle, ['Cue',num2str(i),'ReinforcerPhotometryPlot'])
                MyAxes1 = AxesHandle.(['Cue',num2str(i),'ReinforcerPhotometryPlot']);
                if isvalid(MyAxes1)
                    j = j + 1;
                    axes(MyAxes1);
                    set(MyAxes1,'TickDir', 'out', 'YLim', YLims, ...
                        'XLim', XLims, 'XTick', xtickvalues, 'FontSize', 10);
                    BpodSystem.GUIHandles.(['Cue',num2str(i),'ReinforcerPhotometryData']) = ...
                        plot([-5 5],[0 0],'-r');
                    
                    if isfield(AxesHandle, ['Cue',num2str(i),'Reinforcer2PhotometryPlot'])
                        MyAxes2 = AxesHandle.(['Cue',num2str(i),'Reinforcer2PhotometryPlot']);
                        if isvalid(AxesHandle.(['Cue',num2str(i),'Reinforcer2PhotometryPlot']))
                            axes(MyAxes2);
                            set(MyAxes2, 'TickDir', 'out', 'YLim', YLims, ...
                                'XLim', XLims, 'XTick', xtickvalues, 'FontSize', 10);
                            BpodSystem.GUIHandles.(['Cue',num2str(i),'ReinforcerPhotometry2Data']) = ...
                            plot([-5 5],[0 0],'-r');
                        end
                    end
                    
                    MyAxes3 = AxesHandle.(['Cue',num2str(i),'NoReinforcerPhotometryPlot']);
                    axes(MyAxes3);
                    set(MyAxes3, 'TickDir', 'out', 'YLim', YLims, ...
                        'XLim', XLims, 'XTick', xtickvalues, 'FontSize', 10);
                    BpodSystem.GUIHandles.(['Cue',num2str(i),'NoReinforcerPhotometryData']) = ...
                        plot([-5 5],[0 0],'-r');
                    xlabel(MyAxes3,label_x,'FontSize', 10);
                    
                    if j == 1
                        ylabel(MyAxes1,label_y,'FontSize', 10);
                  
                        if isfield(AxesHandle, ['Cue',num2str(i),'Reinforcer2PhotometryPlot'])
                            if isvalid(MyAxes2)
                                ylabel(MyAxes2,label_y,'FontSize', 10);
                            end
                        end
                        
                        ylabel(MyAxes3,label_y,'FontSize', 10);
                    else
                        set(MyAxes1,...
                            'YTickLabel',[]);
                        set(MyAxes3,...
                            'YTickLabel',[]);
                    end
                end
            end
        end
        
    case 'update'
        AxesTag             = varargin{1};
        newData470          = varargin{2};
        newData405          = varargin{3};
        nidaqRaw            = varargin{4};
        %CurrentTrialType    = varargin{5};

        % Update the most-recent trial data plot
        if isvalid(BpodSystem.GUIHandles.lastplotRaw)
            set(BpodSystem.GUIHandles.lastplotRaw, ...
                'Xdata', nidaqRaw(:,1), 'YData', nidaqRaw(:,2));
            set(BpodSystem.GUIHandles.lastplot470, ...
                'Xdata', newData470(:,1), 'YData', newData470(:,2));
            set(BpodSystem.GUIHandles.lastplot405, ...
                'Xdata', newData405(:,1), 'YData', newData405(:,2));
        

            % for trial-specific plots - recompute the average trace
            AxesName    = AxesHandle.(AxesTag);
            TraceName   = AxesHandle.(strrep(AxesTag,'Plot','Data'));
            axes(AxesName);
            % get already plotted traces and append new traces to it
            AllData = get(AxesName, 'UserData');
            AllData(:,end+1)= newData470(:,3);
            % update figure
            set(AxesName, 'UserData', AllData);
            % update mean trace
            meanData = mean(AllData,2);
            set(TraceName, 'Xdata', newData470(:,1), 'YData', meanData, 'LineWidth' ,MeanThickness);
            set(AxesName, 'NextPlot', 'add');
            plot(newData470(:,1), newData470(:,3), '-k' , 'parent', AxesName);
            uistack(TraceName, 'top');
            hold off
            set(AxesName, 'XLim', XLims, 'XTick', xtickvalues, 'YLim', YLims);
        end
        
end
end