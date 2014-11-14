classdef LeadAcidBattery < Battery
    %LEADACIDBATTERY class 
    
    properties 
        
    end
    
    methods
        % constructor
        function self = LeadAcidBattery(varargin)
            if nargin == 1
               self.max_capacity = varargin{1};
               self.energy_cost = 250;
            elseif nargin == 2
               self.max_capacity = varargin{1};
               self.energy_cost = varargin{2};
            elseif nargin == 0
               self.max_capacity = 12;
               self.energy_cost = 250;
            end
                        
            self.power_cost = 125;
            self.energy_density = 80;
            self.power_density = 128;
            self.charge_discharge_rate = 10;
            self.life_cycle = 2;
            self.depth_of_discharge = 0.8;
            self.float_life = 4;
            self.energy_efficiency = 0.75;
            self.self_discharge_per_day = 0.003;
            self.ramp_time = 0.001;
        end
        
    end
    
end

