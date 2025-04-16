classdef gereactor < handle
    % GEREACTOR A two-state Markov chain reactor
    %   This class implements a two-state Markov chain, often used in models like
    %   the Gilbert-Elliott model for simulating bursty behavior (e.g., ON/OFF states
    %   in RFI systems). The state transitions are determined by a 2x2 probability
    %   matrix, where only the diagonal elements are used: probs(1,1) is the
    %   probability of staying in state 0, and probs(2,2) is the probability of
    %   staying in state 1. The object starts in state 0.
    %
    %   Properties:
    %     state - Current state (0 or 1)
    %     probs - 2x2 transition probability matrix (only diagonal elements used)
    %
    %   Methods:
    %     gereactor - Constructor to initialize with probability matrix
    %     step - Update the state based on transition probabilities
    %
    %   Author: Rick Candell
    %   (c) Copyright Rick Candell All Rights Reserved
    
    properties
        state = 0;  % Current state of the reactor (0 or 1)
        probs = []; % 2x2 transition probability matrix (only diagonal elements used)
    end
    
    methods
        function obj = gereactor(probs)
            obj.probs = probs;
        end
        
        function obj = step(obj)
            % STEP Update the state of the reactor based on transition probabilities
            %   This method generates a random number and decides whether to transition
            %   to the other state or stay in the current state based on the probabilities
            %   stored in obj.probs.
            %
            %   Transition logic:
            %     - In state 0: if rand() > obj.probs(1,1), transition to state 1
            %     - In state 1: if rand() > obj.probs(2,2), transition to state 0
            %   Thus, P(0->0) = probs(1,1), P(0->1) = 1 - probs(1,1),
            %        P(1->1) = probs(2,2), P(1->0) = 1 - probs(2,2).
            
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

