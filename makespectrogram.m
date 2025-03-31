

clear all;
fclose all;
close all;

rfi_config_path = './config/reactors_autogen.json';
rfi=rfigen.rfigenerator(rfi_config_path);

delete("./outputs/test.csv");
rfi.make_spectrogram();

fclose all;

