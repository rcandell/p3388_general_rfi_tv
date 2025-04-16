classdef rfigenerator < handle
    % RFIGENERATOR Class for generating RFI test vectors
    %   This class manages the generation of radio frequency interference (RFI) test vectors
    %   based on configuration properties loaded from a file. It initializes RFI reactors
    %   and provides methods to create spectrograms and time-domain signals, supporting
    %   standardized testing, such as for the IEEE 3388 standard.
    %
    %   Author: Rick Candell
    %   (c) Copyright Rick Candell All Rights Reserved
    %
    %   Properties:
    %     rfi_props - Configuration properties loaded from a file
    %     rfi_state_reactors - Cell array of rfireactor objects
    %     fout - Output file handle (not used in this implementation)
    %     p_fft - Private property for FFT parameters (not used in this implementation)
    %
    %   Methods:
    %     rfigenerator - Constructor to initialize the object
    %     make_spectrogram - Generate the spectrogram from reactor interference
    %     make_time_signal - Convert spectrogram to time-domain signal
    %
    %   Usage:
    %     obj = rfigenerator('path/to/config.json');
    %     obj.make_spectrogram();
    %     obj.make_time_signal();
    
    properties

        % RFI Properties
        rfi_props = [];  % Object holding configuration properties (instance of rfigen.rfiprops)

        % State reactors
        rfi_state_reactors = {}; % Cell array storing rfireactor objects for interference generation

        % Output file
        fout = []; % File handle for output (not used; file paths are in rfi_props)

    end

    properties (Access = private)
        p_fft = [];
    end
    
    methods
        function obj = rfigenerator(path_to_config_file)
            % RFIGENERATOR Constructor to initialize the RFI generator
            %   obj = rfigenerator(path_to_config_file) creates an rfigenerator object by
            %   loading configuration from the specified file and initializing reactors.
            %
            %   Inputs:
            %     path_to_config_file - String specifying the path to the configuration file
            %
            %   Note: Assumes the configuration file defines 'Reactors' as either a single
            %         structure or a cell/structure array of reactor properties.

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
            % MAKE_SPECTROGRAM Generate the spectrogram for the RFI scenario
            %   This method simulates interference over time, combining contributions from
            %   all reactors to create a spectrogram, which is written to a CSV file.
            %
            %   The spectrogram represents interference amplitude (in dB) across frequency
            %   bins for each time window.     

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
            % MAKE_TIME_SIGNAL Convert spectrogram to time-domain signal
            %   This method reads the spectrogram CSV file (in dB), converts each time step
            %   to a time-domain signal using an inverse FFT (via rfitimechunk), and writes
            %   the complex signal (real and imaginary parts) to a CSV file.
            
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

