classdef rfiprops
    %RFITVCONFIG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % configuration file info
        path_to_config_file = [];
        config_dict = [];

        % Gilbert Elliot probabilities for broadband RFI
        % transition probs: col1 (11), col2 (12), col1 (21), col2 (22)
        ge_probs_bb_rfi = [];

        % Gilbert Elliot probabilities for broadband RFI relative power
        ge_ampsprobs_bb_rfi = [];
        ge_amps_bb_rfi = [];

        % Gilber Elliot probabilities for narrowband RFI relative power
        % Array of center frequencies
        ge_freqs_Hz = [];

        % narrowband transition matrix
        % one row per center frequency
        % transition probs: col1 (11), col2 (12), col1 (21), col2 (22)

        % narrowband amplitudes
        % one row per center frequency
        % statistics: col1 (mean), col2 ()        
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
            obj.config_dict = jsondecode(json_data);

            % load the broadband RFI probabilities
            filename = obj.config_dict.PathToGEProbsBB;
            fileID = fopen(filename, 'r');
            json_data = fread(fileID, '*char')';
            fclose(fileID);
            x = jsondecode(json_data);            
            obj.ge_probs_bb_rfi = reshape(x.rfi_bb_probs, [2,2])';

        end
        
    end
end

