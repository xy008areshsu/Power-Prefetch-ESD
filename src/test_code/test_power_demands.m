classdef test_power_demands < matlab.unittest.TestCase
    %TEST_ESDS test power demands functions of various types of ESDs
    
    properties
        originalPath
        demand
        demand_list
        tol;
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
            testCase.demand = Demand(500, 60, 1, 120);
            testCase.tol = 0.0001;
            demand1 = Demand(300, 1, 0.05);
            demand2 = Demand(500, 1, 0.05);
            demand3 = Demand(300, 1, 0.5);
            demand4 = Demand(500, 1, 0.5);
            demand5 = Demand(300, 10, 0.5);
            demand6 = Demand(500, 10, 0.5);
            demand7 = Demand(300, 10, 5);
            demand8 = Demand(500, 10, 5);
            demand9 = Demand(300, 100, 5);
            demand10 = Demand(500, 100, 5);
            demand11 = Demand(300, 100, 24);
            demand12 = Demand(500, 100, 24);
            
            testCase.demand_list = [demand1;demand2;demand3; demand4; demand5;demand6;demand7;demand8;demand9;demand10;demand11;demand12];
        end
    end
    
    methods (Test)
        function testPeakFrequency(testCase)
            expected_f_peak = 0.3333;
            testCase.verifyEqual(testCase.demand.peakFrequency(), expected_f_peak, 'AbsTol', testCase.tol); 
        end
        
        function testPeakPeriodAfterInit(testCase)
           expected_p_peak = 3;
           testCase.verifyEqual(testCase.demand.p_peak, expected_p_peak, 'AbsTol', testCase.tol);
        end
        
        function testArrayOfObjectsAndAlternativeContructor(testCase)
            expected_demand1_h_peak = 300;
            expected_demand1_h_valley = 1;
            expected_demand1_w_peak = 1;
            expected_demand1_w_valley = 2;
            expected_demand1_p_peak = 0.05;
            
            testCase.verifyEqual(testCase.demand_list(1).h_peak, expected_demand1_h_peak);
            testCase.verifyEqual(testCase.demand_list(1).h_valley, expected_demand1_h_valley);
            testCase.verifyEqual(testCase.demand_list(1).w_peak, expected_demand1_w_peak);
            testCase.verifyEqual(testCase.demand_list(1).w_valley, expected_demand1_w_valley);
            testCase.verifyEqual(testCase.demand_list(1).p_peak, expected_demand1_p_peak);
        end
        
        function testPowerDemandDistribution(testCase)
           expected_power_demand = zeros(1, 1440);  % 1440 min per day
           expected_power_demand(1 : 100) = 500;
           expected_power_demand(101 : 1440) = 1;
           actual_power_demand = testCase.demand_list(12).dailyDemand();
           plot_diag = PlotDiagnostic('Power Demand Daily', actual_power_demand, expected_power_demand, 'Minutes', 'Power (W)');
           testCase.verifyEqual(actual_power_demand, expected_power_demand, plot_diag);
           plot_diag.diagnose()
           figure
           hours = 0 : 24/ 1440: 24;
           hours = hours(1 : end - 1);
           d = testCase.demand_list(6).dailyDemand();
           plot(hours, d, 'b','LineWidth', 1);
           
        end
        
    end
    
end

