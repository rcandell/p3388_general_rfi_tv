

clear all;
fclose all;
close all;

delete("test_vbw.csv");

rfi_config_path = './config/reactors_autogen.json';
rfi=rfigen.rfigenerator(rfi_config_path);
rfi.write_test_vector();



