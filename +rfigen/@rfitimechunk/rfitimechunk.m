classdef rfitimechunk < handle
    %RFITIMESERIES Summary of this class goes here
    %   Detailed explanation goes here
    
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
        function obj = rfitimechunk(rfi_props)
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
            rfigen.loginfo("Starting sample rate is " + obj.fs)

            % desired time resolution
            obj.dF = obj.fs/obj.N;
            obj.dT = 1/obj.dF;

            % Number of times to repeat signal
            obj.M = obj.tau/obj.dT;

            % uniform phase size
            obj.apply_poffset = rfi_props.config.ifft.ApplyRandomPhaseOffset;
            obj.pnoisestd = rfi_props.config.ifft.PhaseNoise_rads;
            
            % Upsample rate after the IFFT to apply to the time signal
            obj.U = rfi_props.config.ifft.UpsampleRate;  
            
        end

        function obj = plus(obj, y)
            % y must be dB volts or dB power
            % compute the ifft and store
            obj.X = obj.ifft(y);
            % repeat time chunk over time period
            obj = obj.rep();
            % upsample the time domain signal
            obj.X = resample(obj.X, obj.U, 1);            
        end        

        % concat input m times to output
        function obj = rep(obj)
            % compute number of time to repeat, keep fractional part
            m = floor(obj.M);
            assert(m>=1)
            fp = obj.M - m;
            obj.X = repmat(obj.X(:), m, 1);
            obj.X = obj.X(:).';
            I = 1:round(fp*obj.N);
            obj.X = [obj.X obj.X(I)];
        end

        function X = ifft(obj, YdB)

            % convert fft to time domain using ifft
            Y0 = power(10,YdB/20);  % linear

            % reorder the spectrogram sample such that the ifft works
            % The spectrogram should look like the output of an fft with
            % the lower half, positive freqs and the upper half, negatives
            Im = ceil(length(Y0)/2);
            Y1 = [Y0(Im)  Y0(Im+1:end) (Y0(1:Im-1))];

            if 0
                subplot(3,1,1), stem(Y0)            % original spectrogram input
                subplot(3,1,2), stem(Y1)            % should should fft style arangement
                subplot(3,1,3), stem(fftshift(Y1))  % should show same as Y0
            end

            if 1
                % Apply a random phase
                if obj.apply_poffset
                    poff = pi*rand();
                end
                theta_v = obj.pnoisestd*rand(size(Y1))+poff;
                Y2 = Y1.*exp(1j*theta_v);  
            else 
                % for testing turn off phase
                Y2 = Y1;
            end
    
            % convert to time domain using IFFT
            X = ifft(Y2, obj.N);

            % plot it out
            if 1
                t = linspace(0,obj.tau,obj.N); %#ok<UNRCH>
                subplot(4,1,1), plot(t, real(X)), title('time series output real')
                subplot(4,1,2), plot(t, imag(X)), title('time series output imag')

                f = linspace(-obj.fs/2, obj.fs/2, obj.N)/1e6;
                subplot(4,1,3), stem(f, fftshift(abs(fft(X,obj.N)))), ...
                    title('FFT of new time series')
                subplot(4,1,4), stem(f, Y0), title('original two-sided FFT')
            end
            
        end
        
    end
end

