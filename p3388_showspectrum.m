
clear all;
fclose all;
close all;

% jsppec configuration
filename = "./outputs_p3388/002_general_rfi_moderate.json";
fileID = fopen(filename, 'r');
json_data = fread(fileID, '*char')';
fclose(fileID);
config = jsondecode(json_data);  

% compute the X and Y 
Fs = 1;
Ts = 1/Fs;
X = 1:config.spectrogram.NFreqBins;
Y = 0:config.spectrogram.WindowSize_s:config.spectrogram.Duration_s;

% show the output test vector as power vs time and frequency
outputfile = "./outputs_p3388/002_general_rfi_moderate_specg.csv";
J=readmatrix(outputfile);
figure, imagesc(X,Y,J);
ylabel('Time (s)')
xlabel('Freq Bin')
title('Sample test vector of powers vs time and frequecy')
colorbar
set(gca,'YDir','normal')



