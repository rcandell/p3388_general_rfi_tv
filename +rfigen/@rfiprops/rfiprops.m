classdef rfiprops < handle
    % RFIPROPS Class for handling RFI configuration properties
    %   This class is responsible for loading and storing configuration properties
    %   from a JSON file. These properties are used to configure RFI (Radio Frequency
    %   Interference) generation systems, likely for testing wireless communication
    %   systems under the IEEE 3388 standard. The class provides a way to load
    %   configuration data and store it for use in other parts of the system.
    %
    %   Properties:
    %     config - Parsed JSON configuration object (a MATLAB structure)
    %     path_to_config_file - Path to the JSON configuration file
    %     ge_probs_bb_rfi - Gilbert-Elliot probabilities for broadband RFI
    %                       (Note: This property is declared but not initialized here;
    %                       it may be set elsewhere or extracted from the config.)
    %
    %   Methods:
    %     rfiprops - Constructor to initialize with the configuration file path
    %     loadConfiguration - Method to load and parse the JSON configuration
    %
    %   Author: Rick Candell
    %   (c) Copyright Rick Candell All Rights Reserved 
    
    properties

        % json config object model
        config = [];
        
        % configuration file info
        path_to_config_file = [];

        % Gilbert Elliot probabilities for broadband RFI
        % transition probs: col1 (11), col2 (12), col1 (21), col2 (22)
        ge_probs_bb_rfi = [];
        
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

        end
        
    end
end

