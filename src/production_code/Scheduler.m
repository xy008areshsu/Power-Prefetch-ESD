classdef Scheduler
    %% Assumptions:
    % 1. Time series are 24 hours, and time step is 1 hour
    % 2. renewable energy pattern for each hour is given, as G(t)
    % 3. Energy/power Demand for each hour is given, as D(t), in the unit of kWh, and for now it is constant at each time step.
    % 4. There are three ESDs in the hierarchy, from top to bottom are: renewable(G), battery(B), and flywheel(F)
    % 5. At the beginning of the time series, the energy stored in battery(B) and flywheel(F) are full, equal to their corresponding max capacities.
    % 6. The way this ESD hierarchy works is: G can charge B and F, as well as satisfy D; B can charge F, and D; F can only satisfy D.
    % 7. The self discharge of B(Loss rate of B) can be ignored, whereas that of F cannot.
    % 8. If, at each time step, G cannot be used fully, it is wasted(cannot be used for later time steps)
    %
    %% Variables that can be controlled, for each time step t:
    % 1. B_g(t): the amount of green energy charged into B, variable 1 to 24
    % 2. F_g(t): the amount of green energy charged into F, 25 to 48
    % 3. D_g(t): the amount of green energy to satisfy D, 49 to 72
    % 4. F_b(t): the amount of battery energy to charge F, 73 to 96
    % 5. D_b(t): the amount of battery energy to satisfy D, 97 to 120
    % 6. DoD_b(t): the Depth of Discharge of B, 121 to 144
    % 7. D_f(t): the amount of flywheel energy to satisfy D, 145 to 168
    % 8. DoD_f(t): the Depth of Discharge of F, 169 to 192
    % 9. E_b(t): the amount of energy stored in B, 193 to 216
    % 10. E_f(t): the amount of energy stored in F, 217 to 240
    % 11. B_bin(t): mutual exclusive binary variables for battery, 241 to 264
    % 12. F_bin(t): mutual exclusive binary variables for flywheel, 265 to 288
    % 13. All these variables have the unit of kWh, except #6 and #8, which are percentages, and 11, 12 are binary numbers.
    %% Objective function:
    % The objective for now is to:
    % 1. maximize the expected life time of the battery: Period_Of_Peak_Power * Life_Cycle * (DoD_max_b / DoD_b), in the unit of year
    % The period of peak power is assumed to be 1 hour, the life cycle of the battery is 2 ( 2000 numbers of discharge), DoD_max is 0.8
    % 2. minimize the discharge of battery
    % 3. maximize the battery storage at each time step. 
    % These three objective functions can be represetned using different
    % weights. 
    %
    %% Constraints:
    % 1. D_b(t) + F_b(t) <= r_b * (Max_Capa_B / 20),  discharge rate : charge rate of
    % the battery is r_b
    % 2. B_g(t) <= Max_Capa_B / 20,, charge rate of B is bounded, fully
    % charge in 20 hours
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
        intcon           % vector of integer constraints
        A                % A*x <= b
        b
        A_eq             % A_eq * x = b_eq
        b_eq
        lb               % lb <= x <= ub
        ub
        f                % objective function f: min(f' * x)
    end
    
    methods
        function self = Scheduler(renewable, battery, flywheel, demand)
            num_of_inequality = 288;
            num_of_equality = 24 * 3;
            
           self.renewable = renewable;
           self.battery = battery;
           self.flywheel = flywheel;
           self.demand = demand;
           self.x = zeros(24 * 12, 1);      % There are 12 types of variables, multiplied by 24 hours
           self.A = zeros(num_of_inequality, size(self.x, 1));
           self.b = zeros(num_of_inequality, 1);
           self.A_eq = zeros(num_of_equality, size(self.x, 1));
           self.b_eq = zeros(num_of_equality, 1);
           self.lb = zeros(size(self.x, 1), 1);
           self.ub = inf * ones(size(self.x, 1), 1);
           self.intcon = [];
           self.f = zeros(size(self.x, 1), 1);
        end
        
        
        
        function self = setInequalityConstraints(self)
            infVal = 10000;
            
            % Constraint #1, 1 to 24 total constraints
            for i = 1 : 24
                self.A(i, 73 + i - 1) = 1;
                self.A(i, 97 + i - 1) = 1;
            end
            self.b(1 : 24, :) = self.battery.charge_discharge_rate * (self.battery.max_capacity / 20);
            
            % Constraint #5, 25 to 48 total constraints
            for i = 1 : 24
                self.A(i + 24, 121 + i - 1) = -self.battery.max_capacity;
                self.A(i + 24, 193 + i - 1) = -1;
            end
            self.b(25 : 48, :) = -self.battery.max_capacity;
            
            % Constraint #6, 49 to 72 total constraints
            for i = 1 : 24
                self.A(i + 48, 169 + i - 1) = -self.flywheel.max_capacity;
                self.A(i + 48, 217 + i - 1) = -1;
            end
            self.b(49 : 72, :) = -self.flywheel.max_capacity;
            
            % Constraint #9, 73 to 96 total constraints
            for i = 1 : 24
                self.A(i + 72, 1 + i - 1) = 1;
                self.A(i + 72, 25 + i - 1) = 1;
                self.A(i + 72, 49 + i - 1) = 1;
                self.b(i + 72, :) = self.renewable.distribution(i);
            end
            
            % Constraint #7-1, 97 to 120 total constraints, B_g(t) - inf*
            % B_bin(t) <= 0
            for i = 1 : 24
                self.A(i + 96, 1 + i - 1) = 1;
                self.A(i + 96, 241 + i - 1) = -infVal;
            end
            % Constraint #7-2, 121 to 144 total constraints, -inf * B_g(t)
            % + B_bin(t) <= 0
            for i = 1 : 24
                self.A(i + 120, 1 + i - 1) = -infVal;
                self.A(i + 120, 241 + i - 1) = 1;
            end
            % Constraint #7-3, 145 to 168 total constraints, F_b(t) +
            % D_b(t) + inf * B_bin(t) <= inf
            for i = 1 : 24
                self.A(i + 144, 73 + i - 1) = 1;
                self.A(i + 144, 97 + i - 1) = 1;
                self.A(i + 144, 241 + i - 1) = infVal;
            end
            self.b(145 : 168, :) = infVal;
            
            % Constrain #8-1, 169 to 192 total constraints, D_f(t) - inf *
            % F_bin(t) <= 0
            for i = 1 : 24
                self.A(i + 168, 145 + i - 1) = 1;
                self.A(i + 168, 265 + i - 1) = -infVal;
            end
            % Constraint #8-2, 193 to 216 total constraints, -inf * D_f(t)
            % + F_bin(t) <= 0
            for i = 1 : 24
                self.A(i + 192, 145 + i - 1) = -infVal;
                self.A(i + 192, 265 + i - 1) = 1;
            end
            % Constraint #8-3, 217 to 240 total constraints, F_b(t) +
            % F_g(t) + inf * F_bin(t) <= inf
            for i = 1 : 24
                self.A(i + 216, 73 + i - 1) = 1;
                self.A(i + 216, 25 + i - 1) = 1;
                self.A(i + 216, 265 + i - 1) = infVal;
            end
            self.b(217 : 240, :) = infVal;
            
            % Constraint #15, 241 to 264 total constraints
            for i = 1 : 24
                self.A(i + 240, 73 + i - 1) = 1;
                self.A(i + 240, 97 + i - 1) = 1;
                self.A(i + 240, 193 + i - 1) = -1;
            end
            
            % Constraints #16, 265 to 288 total constratins
            for i = 1 : 24
                self.A(i + 264, 145 + i - 1) = 1;
                self.A(i + 264, 217 + i - 1) = -1;
            end
           
        end
        
        function self = setEqualityConstraints(self)
            % Constraint #12, 1 to 24 total constraints
            for i = 1 : 24
                self.A_eq(i, 49 + i - 1) = 1;
                self.A_eq(i, 97 + i - 1) = 1;
                self.A_eq(i, 145 + i - 1) = 1;
                self.b_eq(i, :) = self.demand(i);
            end
            
            % Constraint #13, 25 to 48 total constraints, assume E_b(1) =
            % 0.5 * max_capacity
            self.A_eq(25, 193) = 2;
            self.b_eq(25, :) = self.battery.max_capacity;
            for i = 2 : 24
                self.A_eq(i + 24, 193 + i - 1) = 1;
                self.A_eq(i + 24, 193 + i - 2) = -1;
                self.A_eq(i + 24, 1 + i - 2) = -self.battery.energy_efficiency;
                self.A_eq(i + 24, 73 + i - 2) = 1;
                self.A_eq(i + 24, 97 + i - 2) = 1;
            end
           
            % Constraint #14, 49 to 72 total constraints, assume E_f(1) =
            % 0.5 * max_capacity
            self.A_eq(49, 217) = 2;
            self.b_eq(49, :) = self.flywheel.max_capacity;
            for i = 2 : 24
                self.A_eq(i + 48, 217 + i - 1) = 1;
                self.A_eq(i + 48, 217 + i - 2) = -1 + self.flywheel.self_discharge_per_day / 24;
                self.A_eq(i + 48, 25 + i - 2) = -self.flywheel.energy_efficiency;
                self.A_eq(i + 48, 73 + i - 2) = -self.flywheel.energy_efficiency;
                self.A_eq(i + 48, 145 + i - 2) = 1;
            end
            
        end
        
        function self = setObjectiveFunction(self)
%             period_peak_power = 1;  
%             weight_DoD_B = 0.5;
            weight_Discharge_B = 1;
%             weight_Storage_B = 0.1;
%             self.f(121:144, :) = weight_DoD_B * (1 / (period_peak_power * self.battery.life_cycle * self.battery.depth_of_discharge));   % DoD_b from 121 to 144
                                                                     % Minimize
                                                                     % the
                                                                     % inverse
                                                                     % of Lief cycle of battery: sum(DoD_b) * [1/(Period_Of_Peak_Power * Life_Cycle * DoD_max_b)]
            self.f(73:120, :) = weight_Discharge_B;
%             self.f(193:216,:) = -weight_Storage_B;
        end
        
        function self = setBounds(self)
            self.ub(1:24, :) = self.battery.max_capacity / 20;   % constraint #2
            self.ub(193:216, :) = self.battery.max_capacity;     % constraint #3
            self.ub(217:240, :) = self.flywheel.max_capacity;     % constraint #4
            self.ub(121:144, :) = self.battery.depth_of_discharge;  % constraint #10
            self.ub(169:192, :) = self.flywheel.depth_of_discharge;  % constraint #11
            self.ub(241:264, :) = 1;     % B_bin(t) is either 0 or 1
            self.ub(265:288, :) = 1;    % F_bin(t) is either 0 or 1
            self.ub(121:144, :) = 1;    % DoD <= 1
            self.ub(169:192, :) = 1;    % DoD <= 1
            
            self.lb(121:144, :) = 0.1;  % DoD >= 0.1, in case of inf and NaN
            self.lb(169:192, :) = 0.1;  
        end
        
        function self = setIntConstraints(self)
            self.intcon = 241 : 288;    % B_bin and F_bin are integers
        end
        
        function self = getOptimalSolution(self)
            self = self.setIntConstraints();
            self = self.setBounds();
            self = self.setEqualityConstraints();
            self = self.setInequalityConstraints();
            self = self.setObjectiveFunction();
            [self.x,fval] = intlinprog(self.f, self.intcon, self.A, self.b, self.A_eq, self.b_eq, self.lb, self.ub);
            battery_dod_actual = (self.x(73 : 96) + self.x(97 : 120)) / self.battery.max_capacity;
            
        end
        
    end
    
end

