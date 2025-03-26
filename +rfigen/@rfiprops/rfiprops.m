classdef rfiprops < handle
    %RFITVCONFIG Summary of this class goes here
    %   Detailed explanation goes here
    % Author: Rick Candell
    % 
    % (c) Copyright Rick Candell All Rights Reserved    
    
    properties

        % json config text
        config = [];
        
        % configuration file info
        path_to_config_file = [];

        % Gilbert Elliot probabilities for broadband RFI
        % transition probs: col1 (11), col2 (12), col1 (21), col2 (22)
        ge_probs_bb_rfi = [];

        % Broadband RFI relative power
        ge_power_bb_rfi = [];

        % freq bin information
        rf_nfreqbins = [];

        % time space
        output_duration_s = [];
        output_samplerate_hz = [];
      
    end
    
    methods
        function obj = rfiprops(path_to_config_file)

            obj.path_to_config_file = path_to_config_file;
            obj = obj.loadConfiguration();
            
        end

        function obj = loadConfiguration(obj)

            % load the configuration dictionary
            filename = obj.path_to_config_file;
            fileID = fopen(filename, 'r');
            json_data = fread(fileID, '*char')';
            fclose(fileID);
            obj.config = jsondecode(json_data);  

            % save to structured code
            obj.rf_nfreqbins = obj.config.NFreqBins;
            obj.output_duration_s = obj.config.OutputDuration_s;
            obj.output_samplerate_hz = obj.config.OutputSampleRate_Hz;

            % % load the broadband RFI probabilities
            % filename = obj.config.PathToGEProbsBB;
            % fileID = fopen(filename, 'r');
            % json_data = fread(fileID, '*char')';
            % fclose(fileID);
            % bbinfo = jsondecode(json_data);  

            % save to structured code
            % obj.ge_probs_bb_rfi = reshape(bbinfo.rfi_bb_probs, [2,2])';          

        end
        
    end
end

