%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

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
function FakeSoundServer(Function, varargin)
% Note: On some Ubuntu systems with Xonar DX, L&R audio seem to be remapped
% to the third plug on the card (from the second plug where they're
% supposed to be). A modified version of this plugin for those systems is
% available upon request. -JS 8/27/2014
global BpodSystem
SF = 192000; % Sound card sampling rate
nSlaves = 32;
Function = lower(Function);
switch Function
    case 'init'
            if isfield(BpodSystem.PluginObjects, 'SoundServer')
                try
                    PsychPortAudio('Close', BpodSystem.PluginObjects.SoundServer);
                catch
                end
            end
            % Set up sound server in emulator mode
            BpodSystem.PluginObjects.SoundServer = struct;
            BpodSystem.PluginObjects.SoundServer.Sounds = cell(1,32);
            BpodSystem.PluginObjects.SoundServer.Enabled = 1;
            try
                sound(zeros(1,10), 48000);
                disp('Fake sound server successfully initialized.')
            catch
                BpodSystem.PluginObjects.SoundServer.Enabled = 0;
                disp('Error starting the Fake sound server. Some platforms do not support sound in MATLAB. See "doc sound" for more details.')
            end
    case 'close'
            BpodSystem.PluginObjects = rmfield(BpodSystem.PluginObjects, 'SoundServer');
            disp('Fake sound server successfully closed.')
    case 'load'
        SlaveID = varargin{1};
        Data = varargin{2};
        Siz = size(Data);
        if Siz(1) > 2
            error('Sound data must be a row vector');
        end
            if Siz(1) == 1 % If mono, send the same signal on both channels
                R = rem(length(Data), 4); % Trim for down-sampling
                if R > 0
                    Data = Data(1:length(Data)-R);
                end
                Data = mean(reshape(Data, 4, length(Data)/4)); % Down-sample 192kHz to 48kHz (only once for mono)
                Data(2,:) = Data;
            else
                R = rem(length(Data(1,:)), 4); % Trim for down-sampling
                if R > 0
                    Data1 = Data(1,1:length(Data(1,:))-R);
                else
                    Data1 = Data(1,:);
                end
                R = rem(length(Data(2,:)), 4); % Trim for down-sampling
                if R > 0
                    Data2 = Data(2,1:length(Data(2,:))-R);
                else
                    Data2 = Data(2,:);
                end
                Data = zeros(1,length(Data1)/4);
                Data(1,:) = mean(reshape(Data1, 4, length(Data1)/4)); % Down-sample 192kHz to 48kHz
                Data(2,:) = mean(reshape(Data2, 4, length(Data2)/4)); % Down-sample 192kHz to 48kHz
            end
            BpodSystem.PluginObjects.SoundServer.Sounds{SlaveID} = Data;
    case 'play'
        SlaveID = varargin{1};
        if SlaveID < nSlaves+1
                l = size(BpodSystem.PluginObjects.SoundServer.Sounds{SlaveID},1);
                if l == 2
                    BpodSystem.PluginObjects.SoundServer.Sounds{SlaveID} = BpodSystem.PluginObjects.SoundServer.Sounds{SlaveID}';
                end
                sound(BpodSystem.PluginObjects.SoundServer.Sounds{SlaveID}, 48000);
        else
            error(['The psychtoolbox sound server currently supports only ' num2str(nSlaves) ' sounds.'])
        end
    case 'stop'
            clear playsnd
    case 'stopall'
        for x = 1:nSlaves
                clear playsnd;
        end
    otherwise
        error([Function ' is an invalid op code for PsychToolboxSoundServer.'])
end