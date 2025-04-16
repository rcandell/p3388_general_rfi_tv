classdef rfireactor < rfigen.gereactor
   % RFIREACTOR Class for modeling radio frequency interference (RFI) reactors
    %   This class represents an RFI reactor that generates interference patterns
    %   based on specified bandwidth and power distributions. It is used in the
    %   context of simulating RFI for wireless communication systems, particularly
    %   for compliance with the IEEE 3388 standard.
    %
    %   Each reactor models the ON/OFF behavior using a Gilbert-Elliot model and
    %   defines how interference is distributed across frequency bins when ON.
    %
    %   Properties:
    %     name - Name of the reactor
    %     centerbin - Central frequency bin of the interference
    %     bw_dist - Structure defining the bandwidth distribution (type, mean, std)
    %     power_dist - Structure defining the power distribution (type, mean, std)
    %     power_shaping - Structure for power shaping (enabled, std)
    %     nbins - Total number of frequency bins
    %     J - Interference magnitude vector across all bins
    %
    %   Methods:
    %     rfireactor - Constructor
    %     resetJ - Reset interference vector J to zeros
    %     add - Add interference to a signal and reset J
    %     step - Update state and generate interference if ON
    %     calculate_bin_range - Helper to get valid bin range
    %
    % Author: Rick Candell
    
    properties
        name = [];  % Name of the reactor (not unique)
        centerbin = [];  % Central frequency bin where interference is centered
        bw_dist = [];  % Structure containing bandwidth distribution parameters (type, mean, std)
        power_dist = [];  % Structure containing power distribution parameters (type, mean, std)
        power_shaping = [];  % Structure for power shaping (enabled, std)
        nbins = [];  % Total number of frequency bins
        J = [];  % Interference magnitude vector across all bins, initialized to zeros
    end
    
    methods
        function obj = rfireactor(nbins, reactor_props)
            ge_probs = reactor_props.ge_probs;
            ge_probs = reshape(ge_probs, [2,2]).';
            obj@rfigen.gereactor(ge_probs);
            obj.name = reactor_props.Name;
            obj.centerbin = reactor_props.centerbin;
            obj.bw_dist = reactor_props.bw_distr;
            obj.power_dist = reactor_props.pwr_distr;
            obj.power_shaping = reactor_props.pwr_shaping;
            obj.nbins = nbins;
            obj.J = zeros(1,nbins);
        end

        function resetJ(obj)
            obj.J = zeros(1,obj.nbins);
        end
        
        function x = add(obj, x)
            obj = obj.step();
            x = x + obj.J;
            obj.resetJ();
        end

        function obj = step(obj)
            % STEP Update the reactor state and generate interference magnitude if ON
            %   This method updates the internal state of the reactor and, if the state is ON,
            %   calculates the interference magnitude across the frequency bins based on
            %   the defined distributions and shaping.            
            obj = step@rfigen.gereactor(obj);
            if obj.state == 1

                % number of bins for interference
                if obj.bw_dist.type == "normal"
                    u = obj.bw_dist.mean;
                    s = obj.bw_dist.std;
                    if (u<=1) && (s==0)
                        L = 1;
                    else
                        L = 2*ceil((u+s*abs(randn()))/2)+1;  % always odd
                    end
                    offset = (L-1)/2;
                    startbin = obj.centerbin - offset;
                    endbin = obj.centerbin + offset;
                    I = obj.calculate_bin_range(startbin, endbin);
                elseif obj.bw_dist.type == "flat"
                    I = 1:obj.nbins;
                else
                    error("unknown bw distribution type %s", obj.bw_dist.type);
                end

                % amplitude level
                if obj.power_dist.type == "normal"
                    u = obj.power_dist.mean;
                    s = obj.power_dist.std;
                    p = u+s*randn();
                    plin = power(10,p/10);  % get linear pwr
                    a = sqrt(plin);  % convert to volts
                    Lr = length(I);
                    r = a*ones(1,Lr);

                    % apply shaping
                    if obj.power_shaping.enabled
                        ps_x = 1:obj.nbins;
                        ps_pdf = pdf('normal',ps_x,obj.centerbin,obj.power_shaping.std);
                        ps_pdf = ps_pdf(I)/max(ps_pdf(I));
                        r = r.*ps_pdf;
                    end

                    % add reactor component
                    obj.J(I) = r;
                else
                    error("unknown pwr distribution type %s", obj.power_dist.type);
                end
            end
        end

        function I = calculate_bin_range(obj, startbin, endbin)
            Ilow = max([startbin 1]);
            Ihigh = min([endbin obj.nbins]);
            I = Ilow:Ihigh;
        end

    end
end

