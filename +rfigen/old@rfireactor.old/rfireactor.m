classdef rfireactor < rfigen.gereactor
    %BBGEREACTOR Summary of this class goes here
    %   Detailed explanation goes here
    % Author: Rick Candell
    % 
    % (c) Copyright Rick Candell All Rights Reserved
    
    properties
        name = [];
        nbins = [];         % num bins total

        J = [];
    end
    
    methods
        function obj = rfireactor(nbins, reactor_props)
            ge_probs = reactor_props.ge_probs;
            ge_probs = reshape(ge_probs, [2,2]).';
            obj@rfigen.gereactor(ge_probs);
            obj.nbins = nbins;
            obj.J = zeros(1,nbins);
        end

        function resetJ(obj)
            obj.J = zeros(1,obj.nbins);
        end

    end
        
    methods (Abstract)

        x = add(obj, x);
        % function x = add(obj, x)
        %     obj = obj.step();
        %     x = x + obj.J;
        %     obj.resetJ();
        % end
        
        obj = step(obj);
        % function obj = step(obj)
            % obj = step@rfigen.gereactor(obj);
            % if obj.state == 1
            %     if obj.power_dist.type == "normal"
            %         u = obj.power_dist.params.mean;
            %         s = obj.power_dist.params.std;
            %         p = u+s*randn();
            %         plin = power(10,p/10);
            %         a = sqrt(plin);
            %         L = obj.endbin - obj.startbin + 1;
            %         r = a*ones(1,L);
            %         obj.J(obj.startbin:obj.endbin) = r;
            %     end
            % end
        % end

    end

end

