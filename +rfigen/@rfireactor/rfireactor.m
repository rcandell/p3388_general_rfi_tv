classdef rfireactor < rfigen.gereactor
    %BBGEREACTOR Summary of this class goes here
    %   Detailed explanation goes here
    % Author: Rick Candell
    % 
    % (c) Copyright Rick Candell All Rights Reserved
    
    properties
        name = [];
        startbin = [];
        endbin = [];
        power_dist = [];
        nbins = [];         % num bins total

        J = [];
    end
    
    methods
        function obj = rfireactor(nbins, reactor_props)
            ge_probs = reactor_props.ge_probs;
            ge_probs = reshape(ge_probs, [2,2]).';
            obj@rfigen.gereactor(ge_probs);
            obj.name = reactor_props.Name;
            obj.startbin = reactor_props.startbin;
            obj.endbin = reactor_props.endbin;
            obj.power_dist = reactor_props.pwr_distr;
            obj.nbins = nbins;
            obj.J = zeros(1,nbins);
        end

        function x = add(obj, x)
            obj = obj.step();
            x = x + obj.J;
        end

        function obj = step(obj)
            obj = step@rfigen.gereactor(obj);
            if obj.state == 1
                if obj.power_dist.type == "normal"
                    u = power(10, obj.power_dist.params.mean/10);
                    s = power(10, obj.power_dist.params.std/10);
                    p = u+s*randn();
                    L = obj.endbin - obj.startbin + 1;
                    r = u+s*ones(1,L);
                    obj.J(obj.startbin:obj.endbin) = r;
                end
            end
        end
    end
end

