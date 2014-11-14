classdef CompressedAirEnergyStorage < EnergyStorageDevice
    %COMPRESSEDAIRENERGYSTORAGE class 
    
    properties
    end
    
    methods
        function self = CompressedAirEnergyStorage()
            self.energy_cost = 50;
            self.power_cost = 600;
            self.energy_density = 6;
            self.power_density = 0.5;
            self.charge_discharge_rate = 4;
            self.life_cycle = 15;
            self.depth_of_discharge = 1;
            self.float_life = 12;
            self.energy_efficiency = 0.68;
            self.self_discharge_per_day = 0.001;
            self.ramp_time = 600;
            self.max_capacity = 30;  
        end

    end
    
end

