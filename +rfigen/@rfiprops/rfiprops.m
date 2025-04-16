classdef rfiprops < handle
    %RFITVCONFIG Summary of this class goes here
    %   Detailed explanation goes here
    % Author: Rick Candell
    % 
    % (c) Copyright Rick Candell All Rights Reserved    
    
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

