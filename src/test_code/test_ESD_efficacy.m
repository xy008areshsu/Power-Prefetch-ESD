classdef test_ESD_efficacy < matlab.unittest.TestCase
    %TEST_ESD_efficacy test energy efficacy of various types of ESDs
    
    properties
        originalPath
        demand
        la              %lead_acid battery
        li              %lithium-ion battery
        uc              %ultra capacitor
        fw              %flywheel
        caes            %compressed air
        fw_efficacy
        uc_efficacy
        caes_efficacy
        la_efficacy
        li_efficacy
        h_shave
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
            testCase.la = LeadAcidBattery;
            testCase.li = LithiumIonBattery;
            testCase.uc = UltraCapacitor;
            testCase.fw = FlyWheel;
            testCase.caes = CompressedAirEnergyStorage;
            testCase.h_shave = 50;
            testCase.fw_efficacy = ESDEfficacy(testCase.fw, testCase.demand, testCase.h_shave);
            testCase.uc_efficacy = ESDEfficacy(testCase.uc, testCase.demand, testCase.h_shave);
            testCase.caes_efficacy = ESDEfficacy(testCase.caes, testCase.demand, testCase.h_shave);
            testCase.li_efficacy =ESDEfficacy(testCase.li, testCase.demand, testCase.h_shave);
            testCase.la_efficacy =ESDEfficacy(testCase.la, testCase.demand, testCase.h_shave);

        end
    end
    
    methods (Test)
        function testESDEfficacy(testCase)
            fw_cost = testCase.fw_efficacy.amortizedCost();
            uc_cost = testCase.uc_efficacy.amortizedCost();
            caes_cost = testCase.caes_efficacy.amortizedCost();
            li_cost = testCase.li_efficacy.amortizedCost();
            la_cost = testCase.la_efficacy.amortizedCost();

        end
        
    end
    
end

