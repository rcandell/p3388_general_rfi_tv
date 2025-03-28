classdef rfireactor < rfigen.gereactor
    %VBWRFIREACTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name = [];
        centerbin = [];
        bw_dist = [];
        power_dist = [];
        power_shaping = [];
        nbins = []; % num bins total

        J = [];
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
            obj = step@rfigen.gereactor(obj);
            if obj.state == 1

                % number of bins for interference
                % r = 0; 
                % startbin = 0;
                % endbin = 0;
                if obj.bw_dist.type == "normal"
                    u = obj.bw_dist.mean;
                    s = obj.bw_dist.std;
                    L = 2*ceil((u+s*abs(randn()))/2)+1;  % always odd
                    offset = (L-1)/2;
                    startbin = obj.centerbin - offset;
                    endbin = obj.centerbin + offset;
                    I = obj.calculate_bin_range(startbin, endbin);
                else
                    error("unknown bw distribution type %s", obj.bw_dist.type);
                end

                % amplitude level
                if obj.power_dist.type == "normal"
                    u = obj.power_dist.mean;
                    s = obj.power_dist.std;
                    p = u+s*randn();
                    plin = power(10,p/10);
                    a = sqrt(plin);
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

