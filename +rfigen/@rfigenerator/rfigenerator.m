classdef rfigenerator
    %GENERATERFITV Summary of this class goes here
    %   Detailed explanation goes here
    % Author: Rick Candell
    % 
    % (c) Copyright Rick Candell All Rights Reserved
    
    properties

        % RFI Properties
        rfi_props = [];  % will be object of rfiprops

        % state reactors
        bb_state_reactor = [];
        nb_state_reactor = [];

    end
    
    methods
        function obj = rfigenerator(path_to_config_file)
            % load the properties information
            obj.rfi_props = rfigen.rfiprops(path_to_config_file);
            obj.bb_state_reactor = rfigen.gereactor(obj.rfi_props.ge_probs_bb_rfi);
        end
        
        function write_tes_vector(obj)
            disp("Sample rate (Hz): " + obj.rfi_props.config_dict.SampleRate_Hz);
            disp("Duration (sec): " + obj.rfi_props.config_dict.Duration_s);

            t = 0;
            ts = 1/obj.rfi_props.config_dict.SampleRate_Hz;
            dur = obj.rfi_props.config_dict.Duration_s;
            states = [];
            while t < dur
                obj.bb_state_reactor = obj.bb_state_reactor.step();
                states(end+1) = obj.bb_state_reactor.state;
                t = t + ts;
            end
            disp("Final time (sec): " + t);

            plot(0:ts:(length(states)-1)*ts, states, '-o')

        end
    end
end

