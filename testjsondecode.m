
clear all;
filename = "./config/rfi_config.json";
fileID = fopen(filename, 'r');
json_data = fread(fileID, '*char')';
fclose(fileID);
config = jsondecode(json_data);  