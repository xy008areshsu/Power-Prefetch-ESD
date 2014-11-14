classdef ESDEfficacy
    %ESDEFFICACY class 
    
    properties
        esd
        demand
        h_shave
        
    end
    
    methods
        function self = ESDEfficacy(esd, demand, h_shave)
            self.esd = esd;
            self.demand = demand;
            % a couple of constraints of choosing h_shave
            assert(h_shave < (self.demand.h_peak - self.demand.h_valley), ...
                'h_shave should be less than (h_peak - h_valley)');
            self.h_shave = h_shave;
        end
        
        function life = expectedLifeTime(self)
            depth_of_discharge_actual = 0.8;           % assume all esds have actual DoD 0.8
            life = min([self.demand.p_peak * self.esd.life_cycle * (self.esd.depth_of_discharge...
                /depth_of_discharge_actual), self.esd.float_life]);
        end
        
        function cost = amortizedCost(self)
           cost = max([self.h_shave * self.esd.power_cost/self.expectedLifeTime(),...
               self.h_shave * self.demand.w_peak * self.esd.energy_cost...
               /(self.expectedLifeTime() * self.esd.depth_of_discharge),...
               self.h_shave * self.demand.w_peak * self.esd.charge_discharge_rate ...
               * self.esd.power_cost / (self.demand.w_valley * self.expectedLifeTime())]);
           
        end
    end
    
end

