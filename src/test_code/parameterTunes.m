%% Tune every parameter in the ESD hierarchy: battery capacity, battery cost
%  flywheel capacity, flywheel cost, flywheel float lifetime.
clear; clc; close all
addpath('../production_code')

%% Initialization
battery_capa_list = [5, 6, 7, 8, 9, 10]; % kwh
battery_cost_list = [250];     % $/kwh
flywheel_capa_list = [0.5, 1, 1.5, 2];   % kwh
flywheel_cost_list = [1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000];  % $/kwh
flywheel_life_list = [12, 13, 14];  % years

green_minute_real = (load('./data/073114_green_minute.csv')./2)./60;
green_15_minute_real = zeros(size(green_minute_real, 1) / 15, 1);
j = 1;
for i = 1 : 15 : size(green_minute_real, 1)
    green_15_minute_real(j) = sum(green_minute_real(i: i + 14, 1));
    j = j + 1;
end

green_hour_real = load('./data/073114_green_hour.csv');
renewable_15_minute_real = Renewable(green_15_minute_real);
renewable_hour_real = Renewable(green_hour_real);
demand_minute_real = mean(green_minute_real) * ones(720, 1);
demand_15_minute_real = zeros(size(demand_minute_real, 1) / 15, 1);
j = 1;
for i = 1 : 15 : size(demand_minute_real, 1)
    demand_15_minute_real(j) = sum(demand_minute_real(i: i + 14, 1));
    j = j + 1;
end

%% Batch experiments
% data = [battery_capa, battery_cost, flywheel_capa, flywheel_cost, flywheel_life,
%  total_cost_with_flywheel, total_cost_without_flywheel] 
 data = zeros(size(battery_capa_list, 2) + size(battery_cost_list, 2) + size(flywheel_capa_list, 2)...
    + size(flywheel_cost_list, 2) + size(flywheel_life_list, 2), 7);
i = 1;
for battery_capa = battery_capa_list
    for battery_cost = battery_cost_list
        for flywheel_capa = flywheel_capa_list
            for flywheel_cost = flywheel_cost_list
                for flywheel_life = flywheel_life_list
                    battery = LeadAcidBattery(battery_capa, battery_cost);
                    flywheel = FlyWheel(flywheel_capa, flywheel_cost, flywheel_life);
                    scheduler_15_minute_real = Scheduler_Linprog(renewable_15_minute_real, ...
                        battery, flywheel, demand_15_minute_real, 48, 80, 96);
                    scheduler_15_minute_no_flywheel = Scheduler_Linprog_NoFlywheel(renewable_15_minute_real,...
                        battery, flywheel, demand_15_minute_real, 48, 80, 96);

                    scheduler_15_minute_real = scheduler_15_minute_real.getOptimalSolution();
                    scheduler_15_minute_no_flywheel = scheduler_15_minute_no_flywheel.getOptimalSolution();
                    
                    data(i, :) = [battery_capa, battery_cost, flywheel_capa, ...
                        flywheel_cost, flywheel_life, scheduler_15_minute_real.total_amortized_cost, ...
                        scheduler_15_minute_no_flywheel.total_amortized_cost];
                    i = i + 1;
                end
            end
        end
    end
end

csvwrite('/simResults/data.csv', data)



