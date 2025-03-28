classdef rfigenerator < handle
    %GENERATERFITV Summary of this class goes here
    %   Detailed explanation goes here
    % Author: Rick Candell
    % 
    % (c) Copyright Rick Candell All Rights Reserved
    
    properties

        % RFI Properties
        rfi_props = [];  % will be object of rfiprops

        % state reactors
        rfi_state_reactors = {}; % a cell array of reactors

        % output file
        fout = [];

    end

    properties (Access = private)
        p_fft = [];
    end
    
    methods
        function obj = rfigenerator(path_to_config_file)
            % load the properties information
            obj.rfi_props = rfigen.rfiprops(path_to_config_file);

            % create array of state reactors
            Nreactors = length(obj.rfi_props.config.Reactors);
            for ii = 1:Nreactors
                if isscalar(obj.rfi_props.config.Reactors)
                    reactor_props = obj.rfi_props.config.Reactors;
                else
                    if iscell(obj.rfi_props.config.Reactors(ii))
                        reactor_props = cell2mat(obj.rfi_props.config.Reactors(ii));
                    else
                        reactor_props = obj.rfi_props.config.Reactors(ii);
                    end
                end
                newReactor = rfigen.rfireactor(obj.rfi_props.rf_nfreqbins,reactor_props);
                obj.rfi_state_reactors{end+1} = newReactor;
            end

        end
        
        function write_test_vector(obj)
            disp("Sample rate (Hz): " + obj.rfi_props.output_samplerate_hz);
            disp("Duration (sec): " + obj.rfi_props.output_duration_s);
            disp("Number of frequency bins: " + obj.rfi_props.rf_nfreqbins);
            disp("Number of reactors: " + length(obj.rfi_state_reactors));
            disp("Output file path: " + obj.rfi_props.config.PathToOutputFile);

            t = 0;
            ts = 1/obj.rfi_props.output_samplerate_hz;
            dur = obj.rfi_props.output_duration_s;
            N = length(obj.rfi_state_reactors);
            L = obj.rfi_props.rf_nfreqbins;
            NF = obj.rfi_props.rel_nf_power_dB;  % relative power in dB
            nfv = power(10,NF/20);  % rel power converted to amplitude
            
            while t < dur

                % set up interference vector
                J = nfv*ones(1,L);

                % add possible J for each reactor
                for ii = 1:N
                    r = obj.rfi_state_reactors{ii};
                    J = r.add(J);
                end

                % interference is linear convert to dB
                J = 20*log10(J);

                % write time step to csv output file
                writematrix(J,obj.rfi_props.config.PathToOutputFile,"WriteMode","append");
                t = t + ts;
            end
        end
    end
end

