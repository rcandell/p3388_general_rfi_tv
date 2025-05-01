
clear;
fclose all;
close all;

rng("shuffle")
config_file_template = "./config/jspec_config_template.json";
fft_config_csv_file = "./config/jspecs - gaussian.xlsx";
output_file = "./config/reactors_autogen.json";
rfigen.jspec_csvtojson(config_file_template, fft_config_csv_file, output_file);
