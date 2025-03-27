

clear all;
fclose all;
close all;


rfi_config_path = './config/rfi_config.json';
rfi=rfigen.rfigenerator(rfi_config_path);
rfi.write_test_vector();
return

