clear all;
fclose all;
close all;

% base template for JSPECs
config_file_template = "./config/jspec_config_template.json";

% output location
output_dir_path = "./outputs";

% open test vector manifest
manifest_path = "./config/makeallspecs.xlsx";
T = readtable(manifest_path, MissingRule="omitrow");
Tst = table2struct(T);

% loop through the manifest
for ii = 1:length(Tst)

    % get meta data
    ID = Tst(ii).ID;
    make = Tst(ii).Make;
    name = Tst(ii).Name;
    fft_config_csv_file = Tst(ii).JSPECConfigPath;

    if make 
        disp("Making ID: " + ID + " Name: " + name)
    else
        disp("Skipping ID: " + ID + " Name: " + name)
        continue
    end

    % JSPEC output file path
    jspec_path = output_dir_path + "/" + ID + "_" + name + ".json";  
    disp("JSPEC PATH: " + jspec_path);

    % make jspec
    rfigen.jspec_csvtojson(config_file_template, fft_config_csv_file, jspec_path);
    disp("jspec json file created")

    % spectrogram output file path
    specg_path = output_dir_path + "/" + ID + "_" + name + "_specg.csv";    
    disp("SPECTROGRAM PATH: " + specg_path)
    
    % make spectrogram
    rfi=rfigen.rfigenerator(jspec_path);
    delete("./outputs/spectrogram.csv");
    rfi.make_spectrogram();
    disp("spectrogram created")

    % move spectrogram interim file to final file location
    interim_spectg_path = output_dir_path + "/spectrogram.csv";
    copyfile(interim_spectg_path, specg_path);
    disp("spectrogram final file copied")

    % time signal output file path
    ts_path = output_dir_path + "/" + ID + "_" + name + "_ts.csv";
    disp("TIME SERIES PATH: " + ts_path)
    
    % make time signal
    rfi=rfigen.rfigenerator(jspec_path);
    delete("./outputs/timesignal.csv");
    rfi.make_time_signal();
    disp("time series final file copied")

    % move time signal interim file to final file location
    interim_spectg_path = output_dir_path + "/timesignal.csv";
    copyfile(interim_spectg_path, ts_path);  
    disp("spectrogram final file copied")
    disp("*****************************************")

end
