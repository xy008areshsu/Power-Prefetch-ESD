classdef LithiumIonBattery < Battery
    %LITHIUMIONBATTERY class

    
    properties
    end
    
    methods
        % constructor
        function self = LithiumIonBattery()
            self.energy_cost = 525;
            self.power_cost = 175;
            self.energy_density = 150;
            self.power_density = 450;
            self.charge_discharge_rate = 5;
            self.life_cycle = 5;
            self.depth_of_discharge = 0.8;
            self.float_life = 8;
            self.energy_efficiency = 0.85;
            self.self_discharge_per_day = 0.001;
            self.ramp_time = 0.001;
            self.max_capacity = 30;
        end
    end
    
end

