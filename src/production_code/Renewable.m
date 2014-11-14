classdef Renewable
    %RENEWABLE energy
    
    
    properties
        distribution               % 24 hours' energy availability, in kWh
    end
    
    methods
        function self = Renewable(distribution)
           self.distribution = distribution;
        end
    end
    
end

