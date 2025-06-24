clear all;
fclose all;
% close all;

% base template for JSPECs
config_file_template = "./config_p3388/jspec_config_template.json";

% output location
output_dir_path = "./outputs_p3388";

% open test vector manifest
manifest_path = "./config_p3388/tv_generation_catalog.xlsx";
T = readtable(manifest_path, MissingRule="omitrow");
Tst = table2struct(T);

% operations
SPECTGOP = 1;
TIMESERIESOP = 0;

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
    
    if SPECTGOP
        % recalculate all of the formaulas in the specg spec
        if 1
        excel = actxserver('Excel.Application');
        workbook = excel.Workbooks.Open(fullfile(pwd, fft_config_csv_file));
        excel.Calculate;
        workbook.Save;
        workbook.Close;        
        excel.Quit;   
        end

        % make spectrogram        
        rfi=rfigen.rfigenerator(jspec_path);
        delete(specg_path);
        rfi.make_spectrogram();
        disp("spectrogram created")
    
        % move spectrogram interim file to final file location
        interim_spectg_path = rfi.rfi_props.config.spectrogram.PathToOutputSpectrogram;
        copyfile(interim_spectg_path, specg_path);
        disp("spectrogram final file copied")

        % show the spectrogram
        rfi.show_spectrum(interim_spectg_path);   
        name_s = strrep(name,"_"," ");
        title("Spectrogram for " + name_s, "interpreter", "none")
    end

    % time signal output file path
    ts_path = output_dir_path + "/" + ID + "_" + name + "_ts.csv";
    disp("TIME SERIES PATH: " + ts_path)

    if TIMESERIESOP    
        % make time signal
        rfi=rfigen.rfigenerator(jspec_path);
        delete(ts_path);
        rfi.make_time_signal();
        disp("time series final file copied")
    
        % move time signal interim file to final file location
        interim_ts_path = rfi.rfi_props.config.ifft.PathToOutputTimeSignal;
        copyfile(interim_ts_path, ts_path);  
        disp("spectrogram final file copied")
        disp("*****************************************")
    end

    % delete the interim files
    if SPECTGOP
        delete(interim_spectg_path);
    end
    if TIMESERIESOP
        delete(interim_ts_path);
    end

end
