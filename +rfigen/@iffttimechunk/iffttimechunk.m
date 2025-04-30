classdef iffttimechunk < handle
    % IFFTTIMECHUNK Class for handling time-domain chunks of RFI signals
    %   This class converts a frequency-domain spectrogram to a time-domain signal using
    %   inverse Fast Fourier Transform (IFFT). It is designed for radio frequency interference
    %   (RFI) simulation, supporting the IEEE 3388 standard for testing industrial
    %   wireless systems under interference conditions. The class manages configuration
    %   parameters, applies random phase noise, and repeats or upsamples the signal as needed.
    %
    %   Properties:
    %     rfi_props - Configuration properties (instance of rfiprops)
    %     tau - Duration of the time chunk (seconds)
    %     fs - Sample rate of the output signal (Hz)
    %     N - Number of points in the IFFT (two-sided)
    %     U - Upsample rate
    %     M - Number of times to repeat the IFFT output
    %     dF - Frequency resolution (Hz)
    %     dT - Time resolution (seconds)
    %     apply_poffset - Flag to apply random phase offset
    %     pnoisestd - Standard deviation of phase noise (radians)
    %     X - Time-domain signal (complex)
    %
    %   Methods:
    %     rfitimechunk - Constructor to initialize with RFI properties
    %     plus - Overloaded + operator to process spectrogram and compute time signal
    %     rep - Repeat the time chunk to match desired duration
    %     ifft - Perform IFFT with spectrogram reordering and phase addition
    %
    %   Usage:
    %     props = rfiprops('config.json');
    %     chunk = rfitimechunk(props);
    %     chunk = chunk + spectrogram_dB; % spectrogram_dB is a vector in dB
    %     time_signal = chunk.X;
    
    properties
        % RFI Properties
        rfi_props = [];  

        % ifft properties
        tau     = [];  % output window period
        fs      = [];  % bandwidth of output signal
        N       = [];  % number of points in the IFFT (two-sided)
        U       = [];  % upsample rate to be applied
        M       = [];  % number of times to repeat the ifft output
        dF      = [];  % frequency resolution from FFT
        dT      = [];  % desired time resolution

        % phase information
        apply_poffset = [];    % apply a block offset
        pnoisestd = [];  % range of random phase in revolutions

        % time chunk
        X = []; % the time chunk
    end
    
    methods
        function obj = iffttimechunk(rfi_props)
            obj.rfi_props = rfi_props;
            fft_params = rfi_props.config.spectrogram;
            ifft_params = rfi_props.config.ifft;

            % Chunk Duration
            % usually the same as the original spectrogram, but we can
            % modify the duration of the time chunk as we like
            if ifft_params.DurationPerChunk_s < 0
                obj.tau = fft_params.WindowSize_s;
            else
                obj.tau = ifft_params.DurationPerChunk_s;
            end
            rfigen.loginfo("Using time chunk size as " + obj.tau)

            % IFFT size
            obj.N = rfi_props.config.spectrogram.NFreqBins;
            rfigen.loginfo("Number of points in original single-sided FFT are " ...
                + rfi_props.config.spectrogram.NFreqBins)
            rfigen.loginfo("Number of points in output two-sided IFFT are " + obj.N)            

            % desired bandwidth of output signal
            obj.fs = ifft_params.StartingSampleRate_Hz;
            if obj.fs
                obj.fs = obj.N/obj.tau;
            end
            rfigen.loginfo("Starting sample rate is " + obj.fs)

            % desired time resolution
            obj.dF = obj.fs/obj.N;
            rfigen.loginfo("Frequency resolution is " + obj.dF)
            obj.dT = 1/obj.dF;
            rfigen.loginfo("Time resolution is " + obj.dT)

            % Number of times to repeat signal
            obj.M = obj.tau/obj.dT;

            % uniform phase size
            obj.apply_poffset = rfi_props.config.ifft.Phase.ApplyRandomPhaseOffset;
            obj.pnoisestd = rfi_props.config.ifft.Phase.PhaseNoise_rads;
            
            % Upsample rate after the IFFT to apply to the time signal
            obj.U = rfi_props.config.ifft.UpsampleRate;  
            
        end

        function obj = plus(obj, y)
            % PLUS Overloaded + operator to process spectrogram
            %   obj = plus(obj, y) takes a spectrogram y (in dB) and computes the time-domain
            %   signal by performing IFFT, repeating the signal, and upsampling.
            %
            %   Input:
            %     y - Spectrogram magnitude in dB (vector)
            %
            %   Output:
            %     obj - Updated object with time-domain signal in obj.X

            % compute the ifft and store
            obj.ifft(y);
            % repeat time chunk over time period
            obj = obj.rep();
            % upsample the time domain signal
            obj.X = resample(obj.X, obj.U, 1);            
        end        

        % concat input m times to output
        function obj = rep(obj)
            % REP Repeat the time-domain signal
            %   Repeats the time-domain signal (obj.X) to match the desired duration (obj.tau).
            %   Handles both integer and fractional repetitions.
            %
            %   Logic:
            %     - m: Integer number of full repetitions
            %     - fp: Fractional part of repetitions
            %     - Repeats X m times, then appends a fraction of X

            X0 = obj.X;

            exp_method = lower(obj.rfi_props.config.ifft.Expansion.ExpansionMethod);
           
            % expand out fft by repeating
            if exp_method == "repeat"
                % using repeat mode
                m = floor(obj.M);
                assert(m>=1)
                fp = obj.M - m; 
                obj.X = repmat(obj.X(:), m, 1);
                obj.X = obj.X(:).';
                I = 1:round(fp*obj.N);
                obj.X = [obj.X obj.X(I)];

            elseif exp_method == "interpolation"
                % using interpolation mode
                i0 = linspace(1, obj.N, obj.N);
                ii = linspace(1, obj.N, round(obj.M*obj.N));
                Xi = interp1(i0, obj.X, ii);

                if 0
                    subplot(2,1,1), plot(1:obj.N, real(obj.X)), axis tight
                    title("Original")
                    subplot(2,1,2), plot(1:length(Xi), real(Xi)), axis tight
                    title("Interpolated")
                end
                obj.X = Xi; 
            elseif exp_method == "upsample"
                % assuming upsampling in frequency domain
                obj.X = fftshift(obj.X);
            else
                error("Unsupported expansion method " + exp_method)
            end

            % plot it out
            if obj.rfi_props.config.ifft.Plots.InFnREP == true

                L0 = length(X0);
                f0 = linspace(-obj.fs/2, obj.fs/2, L0);
                L1 = length(obj.X);
                f1 = linspace(-obj.fs/2, obj.fs/2, L1)/1e6;

                % fft of original series
                Y0 = fftshift(abs(fft(X0)));
                subplot(3,1,1), stem(f0, Y0), ...
                    title('original two-sided FFT')

                % fft of new series
                Y1 = fftshift(abs(fft(obj.X,L1)));
                subplot(3,1,2), stem(f1, Y1), ...
                    title('FFT of new expanded time series')

                % fft of new series using original length
                f = linspace(-obj.fs/2, obj.fs/2, L0)/1e6;
                Y1s = fftshift(abs(fft(obj.X, L0)));
                subplot(3,1,3), stem(f, Y1s), ...
                    title('FFT of new time series, original length')

            end            
   
        end

        function ifft(obj, YdB)
            % IFFT Convert spectrogram to time-domain signal
            %   X = ifft(obj, YdB) converts a spectrogram magnitude (in dB) to a time-domain
            %   signal using IFFT. It reorders the spectrum, adds random phases, and performs IFFT.
            %
            %   Input:
            %     YdB - Spectrogram magnitude in dB (vector)
            %
            %   Output:
            %     X - Time-domain signal (complex vector)
            %
            %   Steps:
            %     1. Convert dB to linear magnitude
            %     2. Reorder spectrum to standard FFT order for IFFT
            %     3. Apply random phase noise
            %     4. Compute IFFT
            %
            %   Note: The reordering assumes YdB is in two-sided spectrum order (negative to
            %         positive frequencies). It shifts the spectrum to match MATLAB's IFFT
            %         expected order (DC, positive, negative frequencies).

            % convert fft to time domain using ifft
            Y0 = power(10,YdB/20);  % linear

            % now upsample if required
            exp_method = lower(obj.rfi_props.config.ifft.Expansion.ExpansionMethod);
            if exp_method == "upsample"
                % using interpolation mode
                interpmethod = obj.rfi_props.config.ifft.Expansion.UpsampleInterpolationMethod;
                i0 = linspace(1, obj.N, obj.N);
                ii = linspace(1, obj.N, round(obj.M*obj.N));
                Yi = interp1(i0, Y0, ii, interpmethod);

                if 0
                    subplot(2,1,1), stem(1:obj.N, Y0), axis tight
                    subplot(2,1,2), stem(1:length(Yi), Yi), axis tight
                end

                Y0 = Yi;
            end

            % reorder the spectrogram sample such that the ifft works
            % The spectrogram should look like the output of an fft with
            % the lower half, positive freqs and the upper half, negatives
            Im = ceil(length(Y0)/2);
            Y1 = [Y0(Im)  Y0(Im+1:end) (Y0(1:Im-1))];

            if obj.rfi_props.config.ifft.Phase.Enabled == true
                % Apply a random phase
                if obj.apply_poffset
                    poff = pi*rand();
                else
                    poff = 0;
                end
                ri = rand(size(Y1));
                theta_v = obj.pnoisestd*ri+poff;
                theta_v = theta_v - pi/2;
                phase_shift = exp(1i*theta_v);
                Y2 = Y1.*phase_shift;  
            else 
                % for testing turn off phase
                Y2 = Y1;
            end
    
            % convert to time domain using IFFT
            % obj.X = ifft(Y2, obj.N);
            obj.X = ifft(Y2);

            % plot it out
            if obj.rfi_props.config.ifft.Plots.InFnIFFT == true
                t = linspace(0,obj.tau,length(obj.X)); %#ok<UNRCH>

                subplot(4,1,1), plot(t, real(obj.X)), title('time series output real')
                subplot(4,1,2), plot(t, imag(obj.X)), title('time series output imag')

                f = linspace(-obj.fs/2, obj.fs/2, length(obj.X))/1e6;

                subplot(4,1,3), stem(f, fftshift(abs(fft(obj.X)))), ...
                    title('FFT of new time series')
                subplot(4,1,4), stem(f, Y0), ...
                    title('original two-sided FFT')
            end
            
        end
        
    end
end

