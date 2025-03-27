classdef fbwrfireactor < rfigen.rfireactor
    %FBWRFIREACTOR Summary of this class goes here
    %   Detailed explanation goes here

properties
        % name = [];
        startbin = [];
        endbin = [];
        power_dist = [];
        % nbins = [];         % num bins total

    end
    
    methods
        function obj = fbwrfireactor(nbins, reactor_props)
            ge_probs = reactor_props.ge_probs;
            ge_probs = reshape(ge_probs, [2,2]).';
            obj@rfigen.rfireactor(ge_probs);
            obj.name = reactor_props.Name;
            obj.startbin = reactor_props.startbin;
            obj.endbin = reactor_props.endbin;
            obj.power_dist = reactor_props.pwr_distr;
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
                if obj.power_dist.type == "normal"
                    u = obj.power_dist.params.mean;
                    s = obj.power_dist.params.std;
                    p = u+s*randn();
                    plin = power(10,p/10);
                    a = sqrt(plin);
                    L = obj.endbin - obj.startbin + 1;
                    r = a*ones(1,L);
                    obj.J(obj.startbin:obj.endbin) = r;
                end
            end
        end
    end    
   
end

