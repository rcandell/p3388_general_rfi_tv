
clear all;
fclose all;
close all;

% jsppec configuration
filename = "./config/reactors_autogen.json";
fileID = fopen(filename, 'r');
json_data = fread(fileID, '*char')';
fclose(fileID);
config = jsondecode(json_data);  

% compute the X and Y 
X = 1:config.spectrogram.NFreqBins;
Y = 0:1/config.spectrogram.SampleRate_Hz:config.spectrogram.Duration_s;

% show the output test vector as power vs time and frequency
outputfile = "./outputs/test.csv";
J=readmatrix(outputfile);
figure, imagesc(X,Y,J);
ylabel('time (s)')
xlabel('freq bin')
title('Sample test vector of powers vs time and frequecy')
colorbar
set(gca,'YDir','normal')


