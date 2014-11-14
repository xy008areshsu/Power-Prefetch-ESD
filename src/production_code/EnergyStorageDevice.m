classdef EnergyStorageDevice
    %ENERGYSTORAGEDEVICE class
    
    properties
        energy_cost                     % in $/kWh
        power_cost                      % in $/kW
        energy_density                  % in Wh/L
        power_density                   % in W/L
        charge_discharge_rate           % ratio
        life_cycle                      % number of discharges * 1000
        depth_of_discharge              % depth of discharge of each discharge, in percentage
        float_life                      % in years
        energy_efficiency               % in percentage
        self_discharge_per_day          % in percentage
        ramp_time                       % in seconds
        max_capacity                    % in kWh
    end
    
    methods
    end
    
end

