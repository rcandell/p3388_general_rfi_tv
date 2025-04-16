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
                newReactor = rfigen.rfireactor(obj.rfi_props.config.spectrogram.NFreqBins,reactor_props);
                obj.rfi_state_reactors{end+1} = newReactor;
            end

        end
        
        function make_spectrogram(obj)
            
            disp("Number of frequency bins: " + obj.rfi_props.config.spectrogram.NFreqBins);
            disp("Number of reactors: " + length(obj.rfi_state_reactors));
            disp("Output file path: " + obj.rfi_props.config.spectrogram.PathToOutputSpectrogram);

            t = 0;
            W = obj.rfi_props.config.spectrogram.WindowSize_s;
            disp("Window size (sec): " + W + " for replication");

            dur = obj.rfi_props.config.spectrogram.Duration_s;
            disp("Duration (sec): " + dur + " for replication");

            N = length(obj.rfi_state_reactors);
            L = obj.rfi_props.config.spectrogram.NFreqBins;
            assert(rem(L,2)) % must be odd number of bins
            NF = obj.rfi_props.config.spectrogram.NoiseFloorPower_dB;  % relative power in dB
            nfv = power(10,NF/20);  % rel power converted to amplitude
            
            while t < dur

                % set up interference vector
                J = nfv*ones(1,L);

                % add possible J for each reactor
                for ii = 1:N
                    r = obj.rfi_state_reactors{ii};
                    J = r.add(J);
                end

                % interference stored as log amplitude 
                J = 20*log10(J);

                % write time step to csv output file
                writematrix(J,obj.rfi_props.config.spectrogram.PathToOutputSpectrogram,"WriteMode","append");
                t = t + W;
            end
        end

        function make_time_signal(obj)
            ifile_name = obj.rfi_props.config.spectrogram.PathToOutputSpectrogram;
            ofile_name = obj.rfi_props.config.ifft.PathToOutputTimeSignal;

            % open the input file
            fid_in = fopen(ifile_name, "r");

            % open the output file
            % fid_out = fopen(ofile_name,'W');
            % fmt='%.8f,%.8f\n';
            
            % loop through each set of lines
            tline = fgetl(fid_in);
            lineno = 1;
            while ischar(tline)

                % convert to array
                v_dB = str2num(tline); %#ok<ST2NM>

                % construct time chunk object
                Tchunk = rfigen.rfitimechunk(obj.rfi_props);

                % convert to time series using ifft
                Tchunk = Tchunk + v_dB;

                % write to the output file
                X = Tchunk.X(:);
                Z = [real(X), imag(X)];
                writematrix(Z,ofile_name,"WriteMode","append");

                if 0
                    t = linspace(0, Tchunk.tau, Tchunk.N*Tchunk.U*Tchunk.M); %#ok<UNRCH>
                    subplot(2,1,1), plot(t, Z(:,1))
                    subplot(2,1,2), plot(t, Z(:,2))
                end
                    
                % last thing, get next line
                tline = fgetl(fid_in);
                lineno = lineno + 1;
            end

            % fclose(fid_out);
            fclose(fid_in);
        end
    end
end

