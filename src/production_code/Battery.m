classdef Battery < EnergyStorageDevice
    %BATTERY class 
 
    
    properties
    end
    
    methods
        
        function expectedLifeCycle = expectedLifeCycles(DoD)
            p = [-0.000261655011655013,0.0485120435120438,-1.95961538461540,...
                 -77.4898989898990,5256.43356643357];  % This is got from polyfit function
            expectedLifeCycle = polyval(p, DoD);
            
        end

    end
    
end

