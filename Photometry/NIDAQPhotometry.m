function [Photoreceiver1Data, WheelData, Photoreceiver2Data] = NIDAQPhotometry(action)

%% dependencies
% /Photometry/NIDAQ_callback.m
% /Photometry/LED_modulation.m

global nidaq S

switch action
    case 'ini'
        %% NIDAQ Initialization
        % Define parameters for analog inputs and outputs.
        nidaq.device            = S.GUI.DAQname;
        nidaq.duration      	= S.GUI.NidaqDuration; % in seconds
        nidaq.sample_rate     	= S.GUI.NidaqSamplingRate; % in Hz
        nidaq.ai_channels       = {'ai0','ai1'};
        nidaq.ai_data           = [];
        nidaq.ao_channels       = {'ao0','ao1'}; % LED1 and LED2
        nidaq.ao_data           = [];
        
        daq.reset
        daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true); % Necessary for this DAQ (X-series, USB)
        
        %create nidaq session
        nidaq.session = daq.createSession('ni');
        
        % Photoreceivers
        for i = 1:2
            MyChannel = addAnalogInputChannel(nidaq.session, nidaq.device, nidaq.ai_channels{i}, 'Voltage');
            MyChannel.TerminalConfig = 'SingleEnded';
        end
        
        % LEDs
        for i = 1:2
            MyChannel = addAnalogOutputChannel(nidaq.session, nidaq.device, nidaq.ao_channels{i}, 'Voltage');
            MyChannel.TerminalConfig = 'SingleEnded';
        end

        % Wheel rotary encoder (quadrature)
        nidaq.counter = addCounterInputChannel(nidaq.session, nidaq.device, 0, 'Position');
        nidaq.counter.EncoderType = 'X1';

        % other acquisition settings
        nidaq.session.Rate = nidaq.sample_rate;
        nidaq.session.IsContinuous = false;
        nidaq.session.addlistener('DataAvailable', @Nidaq_callback);
        
    case 'Start'
        %% Start NIDAQ acquisition
        nidaq.ai_data            = [];

        if S.GUI.Photometry
            % get modulated LED amplitude as a function of time
            % if S.GUI.Modulation == 0, amplitude becomes 0
            nidaq.LED1 = LED_modulation(S.GUI.Modulation*S.GUI.LED.LED1(2),S.GUI.LED.LED1(3)); % Amplitude, Frequency
            if S.GUI.TwoFibers
                % this should change to the appropriate LED
                % nidaq.LED2 = LED_modulation(S.GUI.Modulation*S.GUI.LED.LED2(2),S.GUI.LED.LED2(3));
            else
                nidaq.LED2 = LED_modulation(S.GUI.Modulation*S.GUI.LED.LED2(2),S.GUI.LED.LED2(3)); 
            end
        end

        % send amplitude waveforms to LED drivers
        nidaq.ao_data           = [nidaq.LED1 nidaq.LED2];
        nidaq.session.queueOutputData(nidaq.ao_data);
        nidaq.session.NotifyWhenDataAvailableExceeds = nidaq.sample_rate/5;
        nidaq.session.prepare();
        nidaq.session.startBackground();
        
    case 'Stop'
        %% Stop NIDAQ Acquisition
        nidaq.session.stop();
        wait(nidaq.session) % Wait until nidaq session stops
        if S.GUI.Photometry
            % set all LEDs back to zero
            nidaq.session.outputSingleScan(zeros(1,length(nidaq.ao_channels)));
        end

    case 'Save'
        %% Save Data

        Photoreceiver1Data  = [];
        Photoreceiver2Data  = [];
        WheelData           = [];
        
        % get new data
        if S.GUI.Photometry

            % Photoreceivers
            Photoreceiver1Data = nidaq.ai_data(:,1);
            if S.GUI.TwoFibers == 1
                Photoreceiver2Data = nidaq.ai_data(:,2);
            end

            % Concatenate LED waveforms for demodulation
            if S.GUI.Modulation
                Photoreceiver1Data = [Photoreceiver1Data nidaq.ao_data(1:size(Photoreceiver1Data,1),:)];
                if (S.GUI.LED.LED2(2) == 0 && S.GUI.TwoFibers == 1)
                    Photoreceiver2Data = [Photoreceiver2Data nidaq.ao_data(1:size(Photoreceiver1Data,1),2)];
                end
            end

        end

        if S.GUI.Wheel
            WheelData  = nidaq.ai_data(:,3);
        end
        
end
end