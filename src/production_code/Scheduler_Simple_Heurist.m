classdef Scheduler_Simple_Heurist
    %% Assumptions:
    % 1. Time series are numOfIntervals, and time step is 1 interval
    % 2. renewable energy pattern for each minute is given, as G(t)
    % 3. Energy/power Demand for each minute is given, as D(t), in the unit of kWh, and for now it is constant at each time step.
    % 4. There are three ESDs in the hierarchy, from top to bottom are: renewable(G), battery(B), and flywheel(F)
    % 5. At the beginning of the time series, the energy stored in battery(B) and flywheel(F) are half full, equal to their corresponding max capacities.
    % 6. The way this ESD hierarchy works is: G can charge B and F, as well as satisfy D; B can charge F, and D; F can only satisfy D.
    % 7. The self discharge of B(Loss rate of B) can be ignored, whereas that of F cannot.
    % 8. If, at each time step, G cannot be used fully, it is wasted(cannot be used for later time steps)
    %
    %% Variables that can be controlled, for each time step t:
    % 1. B_g(t): the amount of green energy charged into B, variable 1 to
    % numOfIntervals
    % 2. F_g(t): the amount of green energy charged into F, numOfIntervals
    % + 1 to 2 * numOfIntervals
    % 3. D_g(t): the amount of green energy to satisfy D, 2 *
    % numOfIntervals + 1 to 3 * numOfIntervals
    % 4. F_b(t): the amount of battery energy to charge F, 3 *
    % numOfIntervals + 1 to 4 * numOfIntervals
    % 5. D_b(t): the amount of battery energy to satisfy D, 4 *
    % numOfIntervals + 1 to 5 * numOfIntervals
    % 6. DoD_b(t): the Depth of Discharge of B, 5 * numOfIntervals + 1 to 6
    % * numOfIntervals
    % 7. D_f(t): the amount of flywheel energy to satisfy D, 6 *
    % numOfIntervals + 1 to 7 * numOfIntervals
    % 8. DoD_f(t): the Depth of Discharge of F, 7 * numOfIntervals + 1 to 8
    % * numOfIntervals
    % 9. E_b(t): the amount of energy stored in B, 8 * numOfIntervals + 1
    % to 9 * numOfIntervals
    % 10. E_f(t): the amount of energy stored in F, 9 * numOfIntervals + 1
    % to 10 * numOfIntervals
    % 11. B_bin(t): mutual exclusive binary variables for battery, 10 * numOfIntervals + 1 to
    % 11 * numOfIntervals
    % 12. F_bin(t): mutual exclusive binary variables for flywheel, 11 * numOfIntervals + 1 to
    % 12 * numOfIntervals
    % 13. All these variables have the unit of kWh, except #6 and #8, which are percentages, and 11, 12 are binary numbers.
    
    %% Constraints:
    % 1. D_b(t) + F_b(t) <= r_b * (Max_Capa_B / battery_rate),  discharge rate : charge rate of
    % the battery is r_b, 1200 minutes or 20 hours, THIS SHOULD BE
    % ADJUSTED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    
    % 2. B_g(t) <= Max_Capa_B / battery_rate,, charge rate of B is bounded, fully
    % charge in 20 hours or 1200 minutes, THIS SHOULD BE
    % ADJUSTED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    
    % 3. E_b(t) <= Max_Capa_B
    % 4. E_f(t) <= Max_Capa_F
    % 5. (1 - DoD_b(t)) * Max_Capa_B <= E_b(t)
    % 6. (1 - DoD_f(t)) * Max_capa_F <= E_f(t)
    % 7. Given (F_b(t) +D_b(t) > 0), B_g(t) = 0:  battery cannot be charged and discharged at the same time
    % 8. Given D_f(t) > 0, F_b(t) + F_g(t) = 0: flywheel cannot be charged and discharged at the same time
    % 9. F_g(t) + D_g(t) + B_g(t) <= G(t)
    % 10. DoD_b(t) <= DoD_max_b
    % 11. DoD_f(t) <= DoD_max_f

    % 12. D_g(t) + D_b(t) + D_f(t) = D(t)
    % 13. E_b(t) = E_b(t-1) + efficiency_b * B_g(t-1) - (F_b(t-1) + D_b(t-1)),  the energy stored in B for each time step
    % 14. E_f(t) = E_f(t-1) + efficiency_f * ( F_g(t-1) + F_b(t-1)) - D_f(t-1) - self_discharge_rate_f * E_f(t-1)
    % 15. D_b(t) + F_b(t) <= E_b(t), battery cannot discharge more than it
    % current has
    % 16. D_f(t) <= E_f(t), flywheel cannot discharge more than it
    % currenlty holds
    % 17. All variables are greater than 0

    
    properties
        renewable
        battery
        flywheel
        demand
        x                % manipulated variables
        numOfIntervals
        battery_rate
        fw_self_discharge
    end
    
    methods
        function self = Scheduler_Simple_Heurist(renewable, battery, flywheel, demand, numOfIntervals, battery_rate_interval, fw_self_discharge_interval)            
            self.renewable = renewable;
            self.battery = battery;
            self.flywheel = flywheel;
            self.demand = demand;
            self.x = zeros(12 * numOfIntervals, 1);      % There are 12 types of variables, multiplied by numOfIntervals minutes
            self.numOfIntervals = numOfIntervals;
            self.battery_rate = (self.battery.max_capacity / battery_rate_interval);   
            %For charging, again the Flywheel can be charged at any speed up to some maximum
            %and it doesn't affect anything.  Lead acid batteries are typically rated for a
            %steady C/20 charging rate, which is the rate it takes to fully charge the battery
            %in 20 hours (http://batteryuniversity.com/learn/article/charging_the_lead_acid_battery);
            %the C is the battery's capacity and the 20 is for 20 hours.
            self.fw_self_discharge = self.flywheel.self_discharge_per_day / fw_self_discharge_interval;
        end
        
        function self = getOptimalSolution(self)
           
            %% Initial conditions
            B_g = zeros(self.numOfIntervals, 1);
            F_g = zeros(self.numOfIntervals, 1);
            D_g = zeros(self.numOfIntervals, 1);
            F_b = zeros(self.numOfIntervals, 1);
            D_b = zeros(self.numOfIntervals, 1);
            D_f = zeros(self.numOfIntervals, 1);
            E_b = zeros(self.numOfIntervals, 1);
            E_f = zeros(self.numOfIntervals, 1);
            
            E_b(1) = self.battery.max_capacity;
            E_f(1) = self.flywheel.max_capacity;
            
            %% Heurisic scheduling: if renewable(t) is larger than demand(t), 
            % use renwable(t), then use renewable(t) and battery(t) to charge flywheel(t) 
            % to its full capacity, if battery is not used, then use renewable 
            % to charge battery; if renewable(t) < demand(t), use renewable(t) for demand(t), 
            % then use flywheel for demand, if not enough, use battery.
            notFeasible = false;
            for t = 1 : self.numOfIntervals
                if self.renewable(t) > self.demand(t)
                    D_g(t) = self.demand(t);      % renewable(t) for demand(t)
                    renewable_remain = self.renewable(t) - self.demand(t);
                    if renewable_remain > 0 && E_f(t) < self.flywheel.max_capacity    % if renewable has remaining, and flywheel is not full, charge flywheel
                        F_g(t) = min(renewable_remain, self.flywheel.max_capacity - E_f(t));
                        renewable_remain = renewable_remain - F_g(t);
                        E_f(t) = E_f(t) + self.flywheel.energy_efficiency * F_g(t);
                    end
                    
                    if renewable_remain <= 0 && E_f(t) < self.flywheel.max_capacity   % if renewable is out and flywheel is still not full, use battery to charge it
                        F_b(t) = min(E_b(t), self.flywheel.max_capacity - E_f(t), self.battery.charge_discharge_rate * (self.battery_rate));
                        E_b(t) = E_b(t) - F_b(t);
                        E_f(t) = E_f(t) + self.flywheel.energy_efficiency * F_b(t);
                    elseif renewable_remain > 0 && E_f(t) >= self.flywheel.max_capacity  % if flywheel is full and renewable still has remaining, charge battery
                        B_g(t) = min(renewable_remain, self.battery,max_capacity - E_b(t), self.battery_rate);
                        renewable_remain = renewable_remain - B_g(t);
                        E_b(t) = E_b(t) + self.battery.energy_efficiency * B_g(t);
                    end
                    
                else
                    D_g(t) = self.renewable(t);
                    demand_remain = self.demand(t) - D_g(t);
                    if demand_remain > 0   % if renewable(t) is not enough for demand(t), use flywheel 
                        D_f(t) = min(demand_remain, E_f(t));
                        demand_remain = demand_remain - D_f(t);
                        E_f(t) = E_f(t) - D_f(t);
                    end
                    
                    if demand_remain > 0  % if flywheel is still not enough, use battery
                        D_b(t) = min(demand_remain, E_b(t), self.battery.charge_discharge_rate * (self.battery_rate));
                        demand_remain = demand_remain - D_b(t);
                        E_b(t) = E_b(t) - D_b(t);
                    end
                        
                end
                
                if demand_remain > 0 
                    notFeasible = true;
                    break
                end
                
                %% Post process
                if t < self.numOfIntervals
                    E_b(t + 1) = E_b(t);
                    E_f(t + 1) = E_f(t) - self.fw_self_discharge * E_f(t);
                end
                        
            end    
                    
            if notFeasible == true
                self.x = 0;
                fprintf('No Feasible Solution\n');
            else
                fprintf('Solution Found\\n');
                self.x = [B_g;F_g;D_g;F_b;D_b;D_f;E_b;E_f];
            end
                    
                        
                        
            
            
        end
        
    end
    
end

