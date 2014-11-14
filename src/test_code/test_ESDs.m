classdef test_ESDs < matlab.unittest.TestCase
    %TEST_ESDS test various types of ESDs
    
    properties
        originalPath
        la              %lead_acid battery
        la1             %lead_acid battery 1
        li              %lithium-ion battery
        uc              %ultra capacitor
        fw              %flywheel
        fw1             %flywheel 1
        caes            %compressed air
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
            testCase.la = LeadAcidBattery;
            testCase.la1 = LeadAcidBattery(10);
            testCase.li = LithiumIonBattery;
            testCase.uc = UltraCapacitor;
            testCase.fw = FlyWheel;
            testCase.fw1 = FlyWheel(1);
            testCase.caes = CompressedAirEnergyStorage;
        end
    end
    
    methods (Test)
        
        function testLIInit(testCase)
            testCase.verifyEqual(testCase.li.energy_cost, 525);
            testCase.verifyEqual(testCase.li.power_cost, 175);
            testCase.verifyEqual(testCase.li.energy_density, 150);
            testCase.verifyEqual(testCase.li.power_density, 450);
            testCase.verifyEqual(testCase.li.charge_discharge_rate, 5);
            testCase.verifyEqual(testCase.li.life_cycle, 5);
            testCase.verifyEqual(testCase.li.depth_of_discharge, 0.8);
            testCase.verifyEqual(testCase.li.float_life, 8);
            testCase.verifyEqual(testCase.li.energy_efficiency, 0.85);
            testCase.verifyEqual(testCase.li.self_discharge_per_day, 0.001);
            testCase.verifyEqual(testCase.li.ramp_time, 0.001);                     
        end
        
        function testUCInit(testCase)
            testCase.verifyEqual(testCase.uc.energy_cost, 10000);
            testCase.verifyEqual(testCase.uc.power_cost, 100);
            testCase.verifyEqual(testCase.uc.energy_density, 30);
            testCase.verifyEqual(testCase.uc.power_density, 3000);
            testCase.verifyEqual(testCase.uc.charge_discharge_rate, 1);
            testCase.verifyEqual(testCase.uc.life_cycle, 1000);
            testCase.verifyEqual(testCase.uc.depth_of_discharge, 1);
            testCase.verifyEqual(testCase.uc.float_life, 12);
            testCase.verifyEqual(testCase.uc.energy_efficiency, 0.95);
            testCase.verifyEqual(testCase.uc.self_discharge_per_day, 0.2);
            testCase.verifyEqual(testCase.uc.ramp_time, 0.001);                     
        end
        
        
        function testCAESInit(testCase)
            testCase.verifyEqual(testCase.caes.energy_cost, 50);
            testCase.verifyEqual(testCase.caes.power_cost, 600);
            testCase.verifyEqual(testCase.caes.energy_density, 6);
            testCase.verifyEqual(testCase.caes.power_density, 0.5);
            testCase.verifyEqual(testCase.caes.charge_discharge_rate, 4);
            testCase.verifyEqual(testCase.caes.life_cycle, 15);
            testCase.verifyEqual(testCase.caes.depth_of_discharge, 1);
            testCase.verifyEqual(testCase.caes.float_life, 12);
            testCase.verifyEqual(testCase.caes.energy_efficiency, 0.68);
            testCase.verifyEqual(testCase.caes.self_discharge_per_day, 0.001);
            testCase.verifyEqual(testCase.caes.ramp_time, 600);                     
        end
    end
    
end

