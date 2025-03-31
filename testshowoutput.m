
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
X = 1:config.NFreqBins;
Y = 0:1/config.OutputSampleRate_Hz:config.OutputDuration_s;

outputfile = "./outputs/test.csv";
J=readmatrix(outputfile);
figure, imagesc(X,Y,J);
xlabel('time (s)')
ylabel('freq bin')
title('Sample test vector of powers vs time and frequecy')
colorbar
set(gca,'YDir','normal')


