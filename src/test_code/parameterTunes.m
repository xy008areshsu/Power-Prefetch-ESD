%% Tune every parameter in the ESD hierarchy: battery capacity, battery cost
%  flywheel capacity, flywheel cost, flywheel float lifetime.
clear; clc; close all
addpath('../production_code')

noise = 0 + 0.02.*randn(48,1); 

%% Initialization, battery capa list
battery_capa_list = 0:0.2:10; % kwh
battery_cost_list = [350];     % $/kwh
flywheel_capa_list = 3.5;   % kwh
flywheel_cost_list = [1200];  % $/kwh
flywheel_life_list = [14];  % years

grid_charge = 0.1;   % grid cost $0.1/kWh


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
demand_minute_real = (load('./data/073114_demand_minute.csv')./2)./60;
demand_15_minute_real = zeros(size(demand_minute_real, 1) / 15, 1);
j = 1;
for i = 1 : 15 : size(demand_minute_real, 1)
    demand_15_minute_real(j) = sum(demand_minute_real(i: i + 14, 1));
    j = j + 1;
end

demand_15_minute_real_corsed = load('./data/demand_15_minute_real_data_corsed.csv');
green_15_minute_real_data_corsed = load('./data/green_15_minute_real_data_corsed.csv');
green_15_minute_real_data_corsed(green_15_minute_real_data_corsed > green_15_minute_real) = green_15_minute_real(green_15_minute_real_data_corsed > green_15_minute_real);
renewable_15_minute_real_corsed = Renewable(green_15_minute_real_data_corsed); 

%% Batch experiments
% data = [battery_capa, battery_cost, flywheel_capa, flywheel_cost, flywheel_life,
%  total_cost_with_flywheel, total_cost_without_flywheel] 
 data = zeros(size(battery_capa_list, 2) * size(battery_cost_list, 2) * size(flywheel_capa_list, 2)...
    * size(flywheel_cost_list, 2) * size(flywheel_life_list, 2), 7);
 data_corsed = zeros(size(battery_capa_list, 2) * size(battery_cost_list, 2) * size(flywheel_capa_list, 2)...
    * size(flywheel_cost_list, 2) * size(flywheel_life_list, 2), 7);

i = 1;
for battery_capa = battery_capa_list
    for battery_cost = battery_cost_list
        for flywheel_capa = flywheel_capa_list
            for flywheel_cost = flywheel_cost_list
                for flywheel_life = flywheel_life_list
                    battery = LeadAcidBattery(battery_capa, battery_cost);
                    flywheel = FlyWheel(flywheel_capa, flywheel_cost, flywheel_life);
                    no_flywheel = FlyWheel(0, flywheel_cost, flywheel_life);
                    scheduler_15_minute_real = Scheduler_Linprog(renewable_15_minute_real, ...
                        battery, flywheel, demand_15_minute_real, 48, 80, 96);
                    scheduler_15_minute_no_flywheel = Scheduler_Linprog(renewable_15_minute_real,...
                        battery, no_flywheel, demand_15_minute_real, 48, 80, 96);
                    scheduler_15_minute_real_corsed = Scheduler_Linprog(renewable_15_minute_real_corsed, ...
                        battery, flywheel, demand_15_minute_real_corsed, 48, 80, 96);
                    scheduler_15_minute_no_flywheel_corsed = Scheduler_Linprog(renewable_15_minute_real_corsed,...
                        battery, no_flywheel, demand_15_minute_real_corsed, 48, 80, 96);                    

                    scheduler_15_minute_real = scheduler_15_minute_real.getOptimalSolution();
                    scheduler_15_minute_no_flywheel = scheduler_15_minute_no_flywheel.getOptimalSolution();
                    scheduler_15_minute_real_corsed = scheduler_15_minute_real_corsed.getOptimalSolution();
                    scheduler_15_minute_no_flywheel_corsed = scheduler_15_minute_no_flywheel_corsed.getOptimalSolution();
                    
                    data(i, :) = [battery_capa, battery_cost, flywheel_capa, ...
                        flywheel_cost, flywheel_life, scheduler_15_minute_real.total_amortized_cost, ...
                        scheduler_15_minute_no_flywheel.total_amortized_cost];
                    data_corsed(i, :) = [battery_capa, battery_cost, flywheel_capa, ...
                        flywheel_cost, flywheel_life, scheduler_15_minute_real_corsed.total_amortized_cost, ...
                        scheduler_15_minute_no_flywheel_corsed.total_amortized_cost];                    
                    
                    % the remaining demand with predicted demand will be
                    % satisfied with grid meters
                    extra_demand = scheduler_15_minute_real.demand - scheduler_15_minute_real_corsed.demand;
                    extra_demand(extra_demand < 0) = 0;
                    extra_grid_cost = grid_charge * sum(extra_demand);
                    data_corsed(i, 6) = data_corsed(i, 6) + extra_grid_cost;
                    data_corsed(i, 7) = data_corsed(i, 7) + extra_grid_cost;
                                        
                    i = i + 1;
                end
            end
        end
    end
end




csvwrite('./simResults/data_uncorsed_batt_cap.csv', data)
csvwrite('./simResults/data_corsed_batt_cap.csv', data_corsed)


figure
hold on
plot(data(:, 1), data(:, 6), 'r', 'LineWidth', 2);
plot(data(:, 1), data(:, 7), 'b', 'LineWidth', 2);
plot(data_corsed(:, 1), data_corsed(:, 6), 'g', 'LineWidth', 2);
plot(data_corsed(:, 1), data_corsed(:, 7), 'c', 'LineWidth', 2);

grid
xlabel('Battery Capacity (kWh)')
ylabel('Amortized Cost ($/kWh/day)')
legend('With Flywheel', 'Without Flywheel', 'With Flywheel Predicted', 'Without Flywheel Predicted', 'location', 'SouthEast')

set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, './simResults/amortized_cost_batt_cap.pdf' , 'pdf') %Save figure



%% Initialization, flywheel capa list
battery_capa_list = 5; % kwh
battery_cost_list = [350];     % $/kwh
flywheel_capa_list = 0 : 0.2 : 5;   % kwh
flywheel_cost_list = [1200];  % $/kwh
flywheel_life_list = [14];  % years

grid_charge = 0.1;   % grid cost $0.1/kWh


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
demand_minute_real = (load('./data/073114_demand_minute.csv')./2)./60;
demand_15_minute_real = zeros(size(demand_minute_real, 1) / 15, 1);
j = 1;
for i = 1 : 15 : size(demand_minute_real, 1)
    demand_15_minute_real(j) = sum(demand_minute_real(i: i + 14, 1));
    j = j + 1;
end

demand_15_minute_real_corsed = load('./data/demand_15_minute_real_data_corsed.csv');
green_15_minute_real_data_corsed = load('./data/green_15_minute_real_data_corsed.csv');
green_15_minute_real_data_corsed(green_15_minute_real_data_corsed > green_15_minute_real) = green_15_minute_real(green_15_minute_real_data_corsed > green_15_minute_real);
renewable_15_minute_real_corsed = Renewable(green_15_minute_real_data_corsed); 

%% Batch experiments
% data = [battery_capa, battery_cost, flywheel_capa, flywheel_cost, flywheel_life,
%  total_cost_with_flywheel, total_cost_without_flywheel] 
 data = zeros(size(battery_capa_list, 2) * size(battery_cost_list, 2) * size(flywheel_capa_list, 2)...
    * size(flywheel_cost_list, 2) * size(flywheel_life_list, 2), 7);
 data_corsed = zeros(size(battery_capa_list, 2) * size(battery_cost_list, 2) * size(flywheel_capa_list, 2)...
    * size(flywheel_cost_list, 2) * size(flywheel_life_list, 2), 7);

i = 1;
for battery_capa = battery_capa_list
    for battery_cost = battery_cost_list
        for flywheel_capa = flywheel_capa_list
            for flywheel_cost = flywheel_cost_list
                for flywheel_life = flywheel_life_list
                    battery = LeadAcidBattery(battery_capa, battery_cost);
                    flywheel = FlyWheel(flywheel_capa, flywheel_cost, flywheel_life);
                    no_flywheel = FlyWheel(0, flywheel_cost, flywheel_life);
                    scheduler_15_minute_real = Scheduler_Linprog(renewable_15_minute_real, ...
                        battery, flywheel, demand_15_minute_real, 48, 80, 96);
                    scheduler_15_minute_no_flywheel = Scheduler_Linprog(renewable_15_minute_real,...
                        battery, no_flywheel, demand_15_minute_real, 48, 80, 96);
                    scheduler_15_minute_real_corsed = Scheduler_Linprog(renewable_15_minute_real_corsed, ...
                        battery, flywheel, demand_15_minute_real_corsed, 48, 80, 96);
                    scheduler_15_minute_no_flywheel_corsed = Scheduler_Linprog(renewable_15_minute_real_corsed,...
                        battery, no_flywheel, demand_15_minute_real_corsed, 48, 80, 96);                    

                    scheduler_15_minute_real = scheduler_15_minute_real.getOptimalSolution();
                    scheduler_15_minute_no_flywheel = scheduler_15_minute_no_flywheel.getOptimalSolution();
                    scheduler_15_minute_real_corsed = scheduler_15_minute_real_corsed.getOptimalSolution();
                    scheduler_15_minute_no_flywheel_corsed = scheduler_15_minute_no_flywheel_corsed.getOptimalSolution();
                    
                    data(i, :) = [battery_capa, battery_cost, flywheel_capa, ...
                        flywheel_cost, flywheel_life, scheduler_15_minute_real.total_amortized_cost, ...
                        scheduler_15_minute_no_flywheel.total_amortized_cost];
                    data_corsed(i, :) = [battery_capa, battery_cost, flywheel_capa, ...
                        flywheel_cost, flywheel_life, scheduler_15_minute_real_corsed.total_amortized_cost, ...
                        scheduler_15_minute_no_flywheel_corsed.total_amortized_cost];                    
                    
                    % the remaining demand with predicted demand will be
                    % satisfied with grid meters
                    extra_demand = scheduler_15_minute_real.demand - scheduler_15_minute_real_corsed.demand;
                    extra_demand(extra_demand < 0) = 0;
                    extra_grid_cost = grid_charge * sum(extra_demand);
                    data_corsed(i, 6) = data_corsed(i, 6) + extra_grid_cost;
                    data_corsed(i, 7) = data_corsed(i, 7) + extra_grid_cost;
                                        
                    i = i + 1;
                end
            end
        end
    end
end




csvwrite('./simResults/data_uncorsed_flywheel_cap.csv', data)
csvwrite('./simResults/data_corsed_flywheel_cap.csv', data_corsed)


figure
hold on
plot(data(:, 3), data(:, 6), 'r', 'LineWidth', 2);
plot(data(:, 3), data(:, 7), 'b', 'LineWidth', 2);
plot(data_corsed(:, 3), data_corsed(:, 6), 'g', 'LineWidth', 2);
plot(data_corsed(:, 3), data_corsed(:, 7), 'c', 'LineWidth', 2);

grid
xlabel('Flywheel Capacity (kWh)')
ylabel('Amortized Cost ($/kWh/day)')
legend('With Flywheel', 'Without Flywheel', 'With Flywheel Predicted', 'Without Flywheel Predicted', 'location', 'NorthEast')

set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, './simResults/amortized_cost_flywheel_cap.pdf' , 'pdf') %Save figure
