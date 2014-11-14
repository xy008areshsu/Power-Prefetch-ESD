classdef UltraCapacitor < EnergyStorageDevice
    %ULTRACAPACITOR class 
    properties
    end
    
    methods
        function self = UltraCapacitor()
            self.energy_cost = 10000;
            self.power_cost = 100;
            self.energy_density = 30;
            self.power_density = 3000;
            self.charge_discharge_rate = 1;
            self.life_cycle = 1000;
            self.depth_of_discharge = 1;
            self.float_life = 12;
            self.energy_efficiency = 0.95;
            self.self_discharge_per_day = 0.2;
            self.ramp_time = 0.001;
            self.max_capacity = 30;  % TO BE MODIFIED
        end                
    end
    
end

