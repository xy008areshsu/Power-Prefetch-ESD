classdef Scheduler_Linprog
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
    % 13 Grid(t), use grid meter  12 * numOfIntervals + 1 to 13 * numOfIntervals
    % 14. All these variables have the unit of kWh, except #6 and #8, which are percentages, and 11, 12 are binary numbers.
    %
    %% Objective function:
    % The objective for now is to:
    % 1. maximize the expected life time of the battery: Period_Of_Peak_Power * Life_Cycle * (DoD_max_b / DoD_b), in the unit of year
    % The period of peak power is assumed to be 1 minute, the life cycle of the battery is 2 ( 2000 numbers of discharge), DoD_max is 0.8
    % 2. minimize the discharge of battery
    % 3. maximize the battery storage at each time step. 
    % These three objective functions can be represetned using different
    % weights. 
    %
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

    % 12. D_g(t) + D_b(t) + D_f(t) + Grid(t) = D(t)
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
        intcon           % vector of integer constraints
        A                % A*x <= b
        b
        A_eq             % A_eq * x = b_eq
        b_eq
        lb               % lb <= x <= ub
        ub
        f                % objective function f: min(f' * x)
        numOfIntervals
        battery_rate
        fw_self_discharge
        battery_life
        battery_amortized_cost
        flywheel_amortized_cost
        total_amortized_cost
    end
    
    methods
        function self = Scheduler_Linprog(renewable, battery, flywheel, demand, numOfIntervals, battery_rate_interval, fw_self_discharge_interval)
            num_of_inequality = 12 * numOfIntervals;
            num_of_equality = 3 * numOfIntervals;
            
           self.renewable = renewable;
           self.battery = battery;
           self.flywheel = flywheel;
           self.demand = demand;
           self.x = zeros(13 * numOfIntervals, 1);      % There are 13 types of variables, multiplied by numOfIntervals minutes
           self.A = zeros(num_of_inequality, size(self.x, 1));
           self.b = zeros(num_of_inequality, 1);
           self.A_eq = zeros(num_of_equality, size(self.x, 1));
           self.b_eq = zeros(num_of_equality, 1);
           self.lb = zeros(size(self.x, 1), 1);
           self.ub = inf * ones(size(self.x, 1), 1);
           self.intcon = [];
           self.f = zeros(size(self.x, 1), 1);
           self.numOfIntervals = numOfIntervals;
           self.battery_rate = (self.battery.max_capacity / battery_rate_interval);   %For charging, again the Flywheel can be charged at any speed up to some maximum 
                                                                                      %and it doesn't affect anything.  Lead acid batteries are typically rated for a
                                                                                      %steady C/20 charging rate, which is the rate it takes to fully charge the battery
                                                                                      %in 20 hours (http://batteryuniversity.com/learn/article/charging_the_lead_acid_battery); 
                                                                                      %the C is the battery's capacity and the 20 is for 20 hours.
           self.fw_self_discharge = self.flywheel.self_discharge_per_day / fw_self_discharge_interval;
        end
        
        
        
        function self = setInequalityConstraints(self)
            infVal = 10000;
            
            % Constraint #1, 1 to numOfIntervals total constraints
            for i = 1 : self.numOfIntervals
                self.A(i, 3 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i, 4 * self.numOfIntervals + 1 + i - 1) = 1;
            end
            self.b(1 : self.numOfIntervals, :) = self.battery.charge_discharge_rate * (self.battery_rate);
            
            % Constraint #5, 721 to 1440 total constraints
            for i = 1 : self.numOfIntervals
                self.A(i + self.numOfIntervals, 5 * self.numOfIntervals + 1 + i - 1) = -self.battery.max_capacity;
                self.A(i + self.numOfIntervals, 8 * self.numOfIntervals + 1 + i - 1) = -1;
            end
            self.b(self.numOfIntervals + 1 : 2 * self.numOfIntervals, :) = -self.battery.max_capacity;
            
            % Constraint #6, 1441 to 2160 total constraints
            for i = 1 : self.numOfIntervals
                self.A(i + 2 * self.numOfIntervals, 7 * self.numOfIntervals + 1 + i - 1) = -self.flywheel.max_capacity;
                self.A(i + 2 * self.numOfIntervals, 9 * self.numOfIntervals + 1 + i - 1) = -1;
            end
            self.b(2 * self.numOfIntervals + 1 : 3 * self.numOfIntervals, :) = -self.flywheel.max_capacity;
            
            % Constraint #9, 2161 to 2880 total constraints
            for i = 1 : self.numOfIntervals
                self.A(i + 3 * self.numOfIntervals, 1 + i - 1) = 1;
                self.A(i + 3 * self.numOfIntervals, self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 3 * self.numOfIntervals, 2 * self.numOfIntervals + 1 + i - 1) = 1;
                self.b(i + 3 * self.numOfIntervals, :) = self.renewable.distribution(i);
            end
            
            % Constraint #7-1, 2881 to 3600 total constraints, B_g(t) - inf*
            % B_bin(t) <= 0
            for i = 1 : self.numOfIntervals
                self.A(i + 4 * self.numOfIntervals, 1 + i - 1) = 1;
                self.A(i + 4 * self.numOfIntervals, 10 * self.numOfIntervals + 1 + i - 1) = -infVal;
            end
            % Constraint #7-2, 3601 to 4320 total constraints, -inf * B_g(t)
            % + B_bin(t) <= 0
            for i = 1 : self.numOfIntervals
                self.A(i + 5 * self.numOfIntervals, 1 + i - 1) = -infVal;
                self.A(i + 5 * self.numOfIntervals, 10 * self.numOfIntervals + 1 + i - 1) = 1;
            end
            % Constraint #7-3, 4321 to 5040 total constraints, F_b(t) +
            % D_b(t) + inf * B_bin(t) <= inf
            for i = 1 : self.numOfIntervals
                self.A(i + 6 * self.numOfIntervals, 3 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 6 * self.numOfIntervals, 4 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 6 * self.numOfIntervals, 10 * self.numOfIntervals + 1 + i - 1) = infVal;
            end
            self.b(6 * self.numOfIntervals + 1 : 7 * self.numOfIntervals, :) = infVal;
            
            % Constrain #8-1, 5041 to 5760 total constraints, D_f(t) - inf *
            % F_bin(t) <= 0
            for i = 1 : self.numOfIntervals
                self.A(i + 7 * self.numOfIntervals, 6 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 7 * self.numOfIntervals, 11 * self.numOfIntervals + 1 + i - 1) = -infVal;
            end
            % Constraint #8-2, 5761 to 6480 total constraints, -inf * D_f(t)
            % + F_bin(t) <= 0
            for i = 1 : self.numOfIntervals
                self.A(i + 8 * self.numOfIntervals, 6 * self.numOfIntervals + 1 + i - 1) = -infVal;
                self.A(i + 8 * self.numOfIntervals, 11 * self.numOfIntervals + 1 + i - 1) = 1;
            end
            % Constraint #8-3, 6481 to 7200 total constraints, F_b(t) +
            % F_g(t) + inf * F_bin(t) <= inf
            for i = 1 : self.numOfIntervals
                self.A(i + 9 * self.numOfIntervals, 3 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 9 * self.numOfIntervals, self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 9 * self.numOfIntervals, 11 * self.numOfIntervals + 1 + i - 1) = infVal;
            end
            self.b(9 * self.numOfIntervals + 1 : 10 * self.numOfIntervals, :) = infVal;
            
            % Constraint #15, 7201 to 7920 total constraints
            for i = 1 : self.numOfIntervals
                self.A(i + 10 * self.numOfIntervals, 3 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 10 * self.numOfIntervals, 4 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 10 * self.numOfIntervals, 8 * self.numOfIntervals + 1 + i - 1) = -1;
            end
            
            % Constraints #16, 7921 to 8640 total constratins
            for i = 1 : self.numOfIntervals
                self.A(i + 11 * self.numOfIntervals, 6 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A(i + 11 * self.numOfIntervals, 9 * self.numOfIntervals + 1 + i - 1) = -1;
            end
           
        end
        
        function self = setEqualityConstraints(self)
            % Constraint #12, 1 to numOfIntervals total constraints
            for i = 1 : self.numOfIntervals
                self.A_eq(i, 2 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A_eq(i, 4 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A_eq(i, 6 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A_eq(i, 12 * self.numOfIntervals + 1 + i - 1) = 1;
                self.b_eq(i, :) = self.demand(i);
            end
            
            % Constraint #13, 721 to 1440 total constraints, assume E_b(1) =
            % 1 * max_capacity
            self.A_eq(self.numOfIntervals + 1, 8 * self.numOfIntervals + 1) = 1;
            self.b_eq(self.numOfIntervals + 1, :) = self.battery.max_capacity;
            for i = 2 : self.numOfIntervals
                self.A_eq(i + self.numOfIntervals, 8 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A_eq(i + self.numOfIntervals, 8 * self.numOfIntervals + 1 + i - 2) = -1;
                self.A_eq(i + self.numOfIntervals, 1 + i - 2) = -self.battery.energy_efficiency;
                self.A_eq(i + self.numOfIntervals, 3 * self.numOfIntervals + 1 + i - 2) = 1;
                self.A_eq(i + self.numOfIntervals, 4 * self.numOfIntervals + 1 + i - 2) = 1;
            end
           
            % Constraint #14, 1441 to 2160 total constraints, assume E_f(1) =
            % 1 * max_capacity
            self.A_eq(2 * self.numOfIntervals + 1, 9 * self.numOfIntervals + 1) = 1;
            self.b_eq(2 * self.numOfIntervals + 1, :) = self.flywheel.max_capacity;
            for i = 2 : self.numOfIntervals
                self.A_eq(i + 2 * self.numOfIntervals, 9 * self.numOfIntervals + 1 + i - 1) = 1;
                self.A_eq(i + 2 * self.numOfIntervals, 9 * self.numOfIntervals + 1 + i - 2) = -1 + self.fw_self_discharge;
                self.A_eq(i + 2 * self.numOfIntervals, self.numOfIntervals + 1 + i - 2) = -self.flywheel.energy_efficiency;
                self.A_eq(i + 2 * self.numOfIntervals, 3 * self.numOfIntervals + 1 + i - 2) = -self.flywheel.energy_efficiency;
                self.A_eq(i + 2 * self.numOfIntervals, 6 * self.numOfIntervals + 1 + i - 2) = 1;
            end
            
        end
        
        function self = setObjectiveFunction(self)
%             period_peak_power = 1;  
%             weight_DoD_B = 0.5;
             weight_Discharge_B = 1;
            weight_Storage_B = -1;
            grid_charge = 20;
%             self.f(5 * self.numOfIntervals + 1 : 6 * self.numOfIntervals, :) = weight_DoD_B * (1 / (period_peak_power * self.battery.life_cycle * self.battery.depth_of_discharge));   % DoD_b from 121 to 144
                                                                     % Minimize
                                                                     % the
                                                                     % inverse
                                                                     % of Lief cycle of battery: sum(DoD_b) * [1/(Period_Of_Peak_Power * Life_Cycle * DoD_max_b)]
            self.f(3 * self.numOfIntervals + 1 : 5 * self.numOfIntervals, :) = weight_Discharge_B;
            self.f(8 * self.numOfIntervals + 1 : 9 * self.numOfIntervals, :) = weight_Storage_B;
            self.f(12 * self.numOfIntervals + 1 : 13 * self.numOfIntervals, :) = grid_charge;
            
%             self.f(5761:6480,:) = -10;
            
            %debug
%             self.f(1:2160, :) = 10;
%             self.f(4321:5040, :) = -10;
        end
        
        function self = setBounds(self)
            self.ub(1:self.numOfIntervals, :) = self.battery_rate;   % constraint #2
            self.ub(8 * self.numOfIntervals + 1 : 9 * self.numOfIntervals, :) = self.battery.max_capacity;     % constraint #3
            self.ub(9 * self.numOfIntervals + 1 : 10 * self.numOfIntervals, :) = self.flywheel.max_capacity;     % constraint #4
            self.ub(5 * self.numOfIntervals + 1 : 6 * self.numOfIntervals, :) = self.battery.depth_of_discharge;  % constraint #10
            self.ub(7 * self.numOfIntervals + 1 : 8 * self.numOfIntervals, :) = self.flywheel.depth_of_discharge;  % constraint #11
            self.ub(10 * self.numOfIntervals + 1 : 11 * self.numOfIntervals, :) = 1;     % B_bin(t) is either 0 or 1
            self.ub(11 * self.numOfIntervals + 1 : 12 * self.numOfIntervals, :) = 1;    % F_bin(t) is either 0 or 1
            self.ub(5 * self.numOfIntervals + 1 : 6 * self.numOfIntervals, :) = 1;    % DoD <= 1
            self.ub(7 * self.numOfIntervals + 1 : 8 * self.numOfIntervals, :) = 1;    % DoD <= 1
            
            self.lb(5 * self.numOfIntervals + 1 : 6 * self.numOfIntervals, :) = 0.0001;  % DoD >= 0.1, in case of inf and NaN
            self.lb(7 * self.numOfIntervals + 1 : 8 * self.numOfIntervals, :) = 0.0001; 
            
            %debug
%             self.lb(5761:6480, :) = 10;
        end
        
        function self = setIntConstraints(self)
            self.intcon = 10 * self.numOfIntervals + 1 : 12 * self.numOfIntervals;    % B_bin and F_bin are integers
        end
        
        function self = getOptimalSolution(self)
            self = self.setIntConstraints();
            self = self.setBounds();
            self = self.setEqualityConstraints();
            self = self.setInequalityConstraints();
            self = self.setObjectiveFunction();
            [self.x,fval] = intlinprog(self.f, self.intcon, self.A, self.b, self.A_eq, self.b_eq, self.lb, self.ub);
            self.x(self.x < 1e-5) = 0;
            battery_dod_actual = (self.x(3 * self.numOfIntervals + 1 : 4 * self.numOfIntervals) + self.x(4 * self.numOfIntervals + 1 : 5 * self.numOfIntervals)) / self.battery.max_capacity;
            battery_discharge = self.x(3 * self.numOfIntervals + 1 : 4 * self.numOfIntervals) + self.x(4 * self.numOfIntervals + 1 : 5 * self.numOfIntervals);
            battery_discharge_time = (battery_discharge ~= 0);
            green_charge_battery = self.x(1 : self.numOfIntervals);
            %split to get the cycles
            spliter = [];
            i = 2;
            while i < size(battery_discharge_time, 1)
%             for i = 2: size(battery_discharge_time, 1)
                if battery_discharge_time(i-1) == 1 && battery_discharge_time(i) == 0
                    j = i;
                    while(green_charge_battery(j) == 0 && j < size(battery_discharge_time, 1))
                        j = j + 1;
                    end
                    i = j + 1;
                    spliter= [spliter, i-1];
                else
                    i = i + 1;
                end
                
            end
            if battery_discharge_time(end) == 1
                spliter = [spliter, size(battery_discharge_time, 1)];
            end
            spliter;
            battery_energy_storage = self.x(8 * self.numOfIntervals + 1 : 9 * self.numOfIntervals);           
            if size(spliter, 2) == 0
                battery_left = self.battery.max_capacity;
            else
                battery_left = battery_energy_storage(spliter);
            end
            
            battery_dod = ((self.battery.max_capacity - battery_left)/ self.battery.max_capacity) .* 100;
            p = [-0.000261655011655013,0.0485120435120438,-1.95961538461540,-77.4898989898990,5256.43356643357];  % This is got from polyfit function

            
            
            battery_expected_life_cycles = mean(polyval(p, battery_dod));
            battery_expected_life_days = battery_expected_life_cycles / size(spliter, 2);
            battery_amortized_cost = self.battery.energy_cost / battery_expected_life_days  ;      % $/kwh/day
            battery_cost_per_day = battery_amortized_cost * sum(battery_discharge);
            battery_lifetime_energy = self.battery.max_capacity * battery_expected_life_cycles;
            
            flywheel_amortized_cost = self.flywheel.energy_cost / (self.flywheel.float_life * 365);
            flywheel_discharge = self.x(6 * self.numOfIntervals + 1 : 7 * self.numOfIntervals);
            flywheel_cost_per_day = flywheel_amortized_cost * sum(flywheel_discharge);
            
            total_cost_per_day = flywheel_cost_per_day + battery_cost_per_day;
            
            self.battery_life = battery_expected_life_days;
            self.battery_amortized_cost = battery_amortized_cost;
            self.flywheel_amortized_cost = flywheel_amortized_cost;
            self.total_amortized_cost = total_cost_per_day;
            
        end
        
    end
    
end

