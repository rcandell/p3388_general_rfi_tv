classdef rfitimechunk < handle
    %RFITIMESERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % RFI Properties
        rfi_props = [];  

        % ifft properties
        tau     = [];  % output window period
        bw      = [];  % bandwidth of output signal
        NIFFT   = [];  % number of points in the IFFT
        M       = [];  % number of times to repeat the ifft output

        % time chunk
        X = []; % the time chunk
    end
    
    methods
        function obj = rfitimechunk(rfi_props)
            obj.rfi_props = rfi_props;
            ifft_params = rfi_props.config.ifft;
            obj.tau = ifft_params.TimePeriod_tau_s;
            if obj.tau <= 0
                obj.tau = 1/rfi_props.config.spectrogram.SampleRate_Hz;
            end
            obj.bw = ifft_params.Bandwidth_Hz;
            obj.NIFFT = ifft_params.NPtsIFFT;
            obj.M = (obj.tau*obj.bw)/obj.NIFFT;
        end

        function obj = plus(obj, y)
            % y must be dB volts or dB power
            % compute the ifft and store
            obj.X = obj.ifft(y);
            obj = obj.rep();
        end        

        % concat input m times to output
        function obj = rep(obj)
            % compute number of time to repeat, keep fractional part
            m = floor(obj.M);
            fp = obj.M - m;
            obj.X = repmat(obj.X(:).', m, 1);
            obj.X = obj.X(:).';
            I = 1:floor(fp*obj.NIFFT);
            obj.X = [obj.X round(obj.X(I))];
        end

        function X = ifft(obj, Y0)

            % convert fft to time domain using ifft
            Y0 = power(10,Y0/20);
            % convert to 2-sided spectrum
            Y1 = [Y0(1) Y0(2:end)/2 fliplr(conj(Y0(2:end)))/2];
    
            % conver to time domain
            NptsFFT = obj.rfi_props.config.spectrogram.NFreqBins;
            NptsIFFT = obj.rfi_props.config.ifft.NPtsIFFT;
            if NptsIFFT == -1
                NptsIFFT = 2*NptsFFT;  % signal real, make 2-sided
            end
            if NptsIFFT < NptsFFT
                error("Number of points in the IFFT are less than the number of FFT points")
            end
            % X = ifft(Y2, NptsIFFT, 'symmetric');
            X = ifft(Y1, NptsIFFT);
            
            % write the time domain signal to output file
            % here it will be in text format

            % temp plot it out
            if 0 
                L = NptsFFT;
                Ts_spg = 1/obj.rfi_props.output_samplerate_hz;
                Ts_td = Ts_spg/L;
                t = (0:length(X)-1)*Ts_td;
    
                subplot(4,1,1), plot(real(X)), title('time series output real')
                subplot(4,1,2), plot(imag(X)), title('time series output imag')
                subplot(4,1,3), stem(abs(fft(X,NptsIFFT))), title('FFT of time series')
                subplot(4,1,4), stem([Y1 zeros(1,NptsIFFT-length(Y1))]), title('original symmertric FFT')
            end
            
        end
        
    end
end

