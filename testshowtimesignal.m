
clear all;
fclose all;
close all;

% file info
tsfile = "./outputs/timesignal.csv";

% jspec configuration
jspecpath = "./config/reactors_autogen.json";
fileID = fopen(jspecpath, 'r');
json_data = fread(fileID, '*char')';
fclose(fileID);
config = jsondecode(json_data);  

% loop through N samples (lines)
props = rfigen.rfiprops(jspecpath);
tsgen = rfigen.rfitimechunk(props);
Fs = tsgen.fs;
Ts = 1/Fs;
L = round(tsgen.tau*Fs);

for ii = 0:1000
    % I = sprintf('%i:%i', ii*N+1, ii*N+N);
    I = [ii*L+1 1 ii*L+L 2];
    X=readmatrix(tsfile,'Range',I);
    X = X(:,1)+1i*X(:,2);

    tt = 1000*(0:Ts:Ts*(L-1));
    subplot(3,1,1), plot(tt,real(X)), xlabel('time (ms)')
    subplot(3,1,2), plot(tt,imag(X)), xlabel('time (ms)')

    ff = 1e-6*linspace(-Fs/2, Fs/2, L);
    subplot(3,1,3), stem(ff, fftshift(abs(fft(X)))), xlabel('freq (MHz)')
end


