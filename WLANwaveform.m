% Check if WLAN System Toolbox is available
if ~license('test', 'WLAN_System_Toolbox')
    error('WLAN System Toolbox is not installed or not available.');
end

% Define system parameters
cfgVHT = wlanVHTConfig;    % Create a VHT configuration object
cfgVHT.ChannelBandwidth = 'CBW20'; % 20 MHz channel bandwidth
cfgVHT.MCS = 4;            % Modulation and coding scheme
cfgVHT.APEPLength = 1024;  % Payload length in bytes

% Generate WLAN waveform
txWaveform = wlanWaveformGenerator([], cfgVHT);

% Add noise to the waveform
snr = 20; % Signal-to-noise ratio in dB
rxWaveform = awgn(txWaveform, snr, 'measured');

% Perform receiver processing
rxCfgVHT = wlanVHTConfig;
rxLLTF = wlanLLTFDemodulate(rxWaveform, rxCfgVHT);
chEst = wlanLLTFChannelEstimate(rxLLTF, rxCfgVHT);
rxData = wlanVHTDataRecover(rxWaveform, chEst, noiseVar, rxCfgVHT);

% Measure performance
[ber, ~] = biterr(txData, rxData);
fprintf('Bit Error Rate (BER): %f\n', ber);