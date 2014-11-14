classdef FlyWheel < EnergyStorageDevice
    %FLYWHEEL class 
    
    properties
    end
    
    methods
        function self = FlyWheel(varargin)
            if nargin == 1
               self.max_capacity = varargin{1};
               self.energy_cost = 1500;
               self.float_life = 14;
            elseif nargin == 3
               self.max_capacity = varargin{1};
               self.energy_cost = varargin{2};
               self.float_life = varargin{3};
            elseif nargin == 0
               self.max_capacity = 2;
               self.energy_cost = 1500;
               self.float_life = 14;
            end
           
            self.power_cost = 250;
            self.energy_density = 80;
            self.power_density = 1600;
            self.charge_discharge_rate = 1;
            self.life_cycle = 200;
            self.depth_of_discharge = 1;
            self.energy_efficiency = 0.95;
            self.self_discharge_per_day = 1;
            self.ramp_time = 0.001;
        end        
        
    end
    
end

