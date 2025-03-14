classdef gereactor
    
    properties
        state = 0;
        probs = [];
    end
    
    methods
        function obj = gereactor(probs)
            obj.probs = probs;
        end
        
        function obj = step(obj)
            r = rand();
            if obj.state == 0 % in state == 0
                if r>obj.probs(1,1)
                    obj.state = 1;
                end
            else % in state == 1
                if r>obj.probs(2,2)
                    obj.state = 0;
                end
            end
        end
    end
end

