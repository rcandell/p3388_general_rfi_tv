
clear all;
fclose all;
close all;

config_file = "./config/jspec_config_template.json";
csv_file = "./config/jspecs.xlsx";
output_file = "./config/reactors_autogen.json";
rfigen.jspec_csvtojson(config_file, csv_file, output_file);
