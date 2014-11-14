classdef test_Scheduler < matlab.unittest.TestCase
    %TEST_ESDS test various types of schedulers
    
    
    properties
        originalPath
        scheduler
        scheduler_minute
        scheduler_minute_stochastic
        scheduler_linprog
        scheduler_linprog_hour_based
        scheduler_minute_real
        scheduler_hour_real
        scheduler_hour_no_flywheel
        scheduler_minute_no_flywheel
        scheduler_15_minute_real
        scheduler_15_minute_no_flywheel
        HEIGHT
        WIDTH
    end
    
    methods(TestClassSetup)
        function addESDClassToPath(testCase)
            testCase.originalPath = path;
            addpath(fullfile(pwd, '../production_code'));
        end
    end
    
    methods(TestClassTeardown)
        function restorePath(testCase)
            path(testCase.originalPath)
        end
    end
    
    methods(TestMethodSetup)
        function createESDInstances(testCase)
            green_minute_real = (load('./data/073114_green_minute.csv')./2)./60;
            green_15_minute_real = zeros(size(green_minute_real, 1) / 15, 1);
            j = 1;
            for i = 1 : 15 : size(green_minute_real, 1)
                green_15_minute_real(j) = sum(green_minute_real(i: i + 14, 1));
                j = j + 1;
            end
            
            renewable_minute_real = Renewable(green_minute_real);
            renewable_15_minute_real = Renewable(green_15_minute_real);
            battery = LeadAcidBattery(5);
            flywheel = FlyWheel(0.5);
            demand_minute_real = mean(green_minute_real) * ones(720, 1);
            demand_15_minute_real = zeros(size(demand_minute_real, 1) / 15, 1);
            j = 1;
            for i = 1 : 15 : size(demand_minute_real, 1)
                demand_15_minute_real(j) = sum(demand_minute_real(i: i + 14, 1));
                j = j + 1;
            end
            
            testCase.scheduler_minute_real = Scheduler_Linprog(renewable_minute_real, ...
                battery, flywheel, demand_minute_real, 720, 1200, 1440);
            testCase.scheduler_minute_no_flywheel = Scheduler_Linprog_NoFlywheel(renewable_minute_real, ...
                battery, flywheel, demand_minute_real, 720, 1200, 1440);
            testCase.scheduler_15_minute_real = Scheduler_Linprog(renewable_15_minute_real, ...
                battery, flywheel, demand_15_minute_real, 48, 80, 96);
            testCase.scheduler_15_minute_no_flywheel = Scheduler_Linprog_NoFlywheel(renewable_15_minute_real, ...
                battery, flywheel, demand_15_minute_real, 48, 80, 96);
            
            testCase.HEIGHT = 400;
            testCase.WIDTH = 480;
        end
    end
    
    methods (Test)
        
        function testSchedulerLinprogMinuteBasedReal(testCase)
            testCase.scheduler_minute_real = testCase.scheduler_minute_real.getOptimalSolution();
            
            h = figure;
            set_fig_position(h,0, 0, testCase.HEIGHT, testCase.WIDTH);
            hold on
            grid
            t = 0 : 719;
            xlabel('Minutes (min)')
            ylabel('Energy Usage (kWh)')
            plot(t, testCase.scheduler_minute_real.demand, 'y', 'LineWidth', 8)
            plot(t, testCase.scheduler_minute_real.x(1441:2160), 'g', 'LineWidth', 2)
            plot(t, testCase.scheduler_minute_real.x(2881:3600), 'b', 'LineWidth', 2)
            plot(t, testCase.scheduler_minute_real.x(4321:5040), 'm', 'LineWidth', 2)
            legend('Demand','Renewable Usage','Battery Usage', 'Flywheel Usage', 'Location', 'NorthOutside')
            set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
            set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
            saveas(gcf, './simResults/ESD_Usage_Minute_Based_Linprog_Real.pdf' , 'pdf') %Save figure
            
            h = figure;
            set_fig_position(h,0, 481, testCase.HEIGHT, testCase.WIDTH);
            hold on
            grid
            xlabel('Minutes (min)')
            ylabel('Battery Actual DoD (1x)')
            plot(t, (testCase.scheduler_minute_real.battery.max_capacity - ...
                testCase.scheduler_minute_real.x(8 * testCase.scheduler_minute_real.numOfIntervals + ...
                1 : 9 * testCase.scheduler_minute_real.numOfIntervals))...
                / testCase.scheduler_minute_real.battery.max_capacity, 'b+-', 'LineWidth', 2)
            set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
            set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
            saveas(gcf, './simResults/Battery_Actual_DoD_Minute_Based_Linprog_Real.pdf' , 'pdf') %Save figure
            
        end
        
        function testSchedulerLinprogMinuteBasedRealNoFlywheel(testCase)
            testCase.scheduler_minute_no_flywheel = testCase.scheduler_minute_no_flywheel.getOptimalSolution();
            
            h=figure;
            set_fig_position(h,0, 961, testCase.HEIGHT, testCase.WIDTH);
            hold on
            grid
            t = 0 : 719;
            xlabel('Minutes (min)')
            ylabel('Energy Usage (kWh)')
            plot(t, testCase.scheduler_minute_no_flywheel.demand, 'y', 'LineWidth', 8)
            plot(t, testCase.scheduler_minute_no_flywheel.x(1441:2160), 'g', 'LineWidth', 2)
            plot(t, testCase.scheduler_minute_no_flywheel.x(2881:3600), 'b', 'LineWidth', 2)
            plot(t, testCase.scheduler_minute_no_flywheel.x(4321:5040), 'm', 'LineWidth', 2)
            legend('Demand','Renewable Usage','Battery Usage', 'Flywheel Usage', 'Location', 'NorthOutside')
            set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
            set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
            saveas(gcf, './simResults/ESD_Usage_Minute_Based_Linprog_Real_No_Flywheel.pdf' , 'pdf') %Save figure
            
            h = figure;
            set_fig_position(h,0, 1441, testCase.HEIGHT, testCase.WIDTH);
            hold on
            grid
            xlabel('Minutes (min)')
            ylabel('Battery Actual DoD (1x)')
            plot(t, (testCase.scheduler_minute_no_flywheel.battery.max_capacity ...
                - testCase.scheduler_minute_no_flywheel.x(8 * testCase.scheduler_minute_no_flywheel.numOfIntervals ...
                + 1 : 9 * testCase.scheduler_minute_no_flywheel.numOfIntervals))...
                / testCase.scheduler_minute_no_flywheel.battery.max_capacity, 'b+-', 'LineWidth', 2)
            set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
            set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
            saveas(gcf, './simResults/Battery_Actual_DoD_Minute_Based_Linprog_Real_No_Flywheel.pdf' , 'pdf') %Save figure
            
        end
        
        
        function testSchedulerLinprog15MinuteBasedReal(testCase)
            testCase.scheduler_15_minute_real = testCase.scheduler_15_minute_real.getOptimalSolution();
            
            h= figure;
            set_fig_position(h,500, 0, testCase.HEIGHT, testCase.WIDTH);
            hold on
            grid
            t = 0 : 47;
            xlabel('15-Minutes (15-min)')
            ylabel('Energy Usage (kWh)')
            plot(t, testCase.scheduler_15_minute_real.demand, 'y', 'LineWidth', 8)
            plot(t, testCase.scheduler_15_minute_real.x(2 * testCase.scheduler_15_minute_real.numOfIntervals ...
                + 1 : 3 * testCase.scheduler_15_minute_real.numOfIntervals), 'g', 'LineWidth', 2)
            plot(t, testCase.scheduler_15_minute_real.x(4 * testCase.scheduler_15_minute_real.numOfIntervals ...
                + 1 : 5 * testCase.scheduler_15_minute_real.numOfIntervals), 'b', 'LineWidth', 2)
            plot(t, testCase.scheduler_15_minute_real.x(6 * testCase.scheduler_15_minute_real.numOfIntervals ...
                + 1 : 7 * testCase.scheduler_15_minute_real.numOfIntervals), 'm', 'LineWidth', 2)
            legend('Demand','Renewable Usage','Battery Usage', 'Flywheel Usage', 'Location', 'NorthOutside')
            set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
            set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
            saveas(gcf, './simResults/ESD_Usage_15_Minute_Based_Linprog_Real.pdf' , 'pdf') %Save figure
            
            h=figure;
            set_fig_position(h,500, 481, testCase.HEIGHT, testCase.WIDTH);
            hold on
            grid
            xlabel('15 Minutes (15-min)')
            ylabel('Battery Actual DoD (1x)')
            plot(t, (testCase.scheduler_15_minute_real.battery.max_capacity ...
                - testCase.scheduler_15_minute_real.x(8 * testCase.scheduler_15_minute_real.numOfIntervals ...
                + 1 : 9 * testCase.scheduler_15_minute_real.numOfIntervals))...
                / testCase.scheduler_15_minute_real.battery.max_capacity, 'b+-', 'LineWidth', 2)
            set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
            set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
            saveas(gcf, './simResults/Battery_Actual_DoD_15_Minute_Based_Linprog_Real.pdf' , 'pdf') %Save figure
            
        end
        
        function testSchedulerLinprog15MinuteBasedRealNoFlywheel(testCase)
            testCase.scheduler_15_minute_no_flywheel = testCase.scheduler_15_minute_no_flywheel.getOptimalSolution();
            
            h=figure;
            set_fig_position(h,500, 961, testCase.HEIGHT, testCase.WIDTH);
            hold on
            grid
            t = 0 : 47;
            xlabel('15-Minutes (15-min)')
            ylabel('Energy Usage (kWh)')
            plot(t, testCase.scheduler_15_minute_no_flywheel.demand, 'y', 'LineWidth', 8)
            plot(t, testCase.scheduler_15_minute_no_flywheel.x(2 * testCase.scheduler_15_minute_no_flywheel.numOfIntervals ...
                + 1 : 3 * testCase.scheduler_15_minute_no_flywheel.numOfIntervals), 'g', 'LineWidth', 2)
            plot(t, testCase.scheduler_15_minute_no_flywheel.x(4 * testCase.scheduler_15_minute_no_flywheel.numOfIntervals ...
                + 1 : 5 * testCase.scheduler_15_minute_no_flywheel.numOfIntervals), 'b', 'LineWidth', 2)
            plot(t, testCase.scheduler_15_minute_no_flywheel.x(6 * testCase.scheduler_15_minute_no_flywheel.numOfIntervals ...
                + 1 : 7 * testCase.scheduler_15_minute_no_flywheel.numOfIntervals), 'm', 'LineWidth', 2)
            legend('Demand','Renewable Usage','Battery Usage', 'Flywheel Usage', 'Location', 'NorthOutside')
            set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
            set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
            saveas(gcf, './simResults/ESD_Usage_15_Minute_Based_Linprog_Real_No_Flywheel.pdf' , 'pdf') %Save figure
            
            h=figure;
            set_fig_position(h,500, 1441, testCase.HEIGHT, testCase.WIDTH);
            hold on
            grid
            xlabel('15 Minutes (15-min)')
            ylabel('Battery Actual DoD (1x)')
            plot(t, (testCase.scheduler_15_minute_no_flywheel.battery.max_capacity ...
                - testCase.scheduler_15_minute_no_flywheel.x(8 * testCase.scheduler_15_minute_no_flywheel.numOfIntervals ...
                + 1 : 9 * testCase.scheduler_15_minute_no_flywheel.numOfIntervals))...
                / testCase.scheduler_15_minute_no_flywheel.battery.max_capacity, 'b+-', 'LineWidth', 2)
            set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
            set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
            saveas(gcf, './simResults/Battery_Actual_DoD_15_Minute_Based_Linprog_Real_No_Flywheel.pdf' , 'pdf') %Save figure
            
        end
        
    end
    
end

