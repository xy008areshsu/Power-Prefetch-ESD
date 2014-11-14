classdef test_Renewable < matlab.unittest.TestCase
    %TEST_ESDS test various types of renewable energy

    
    properties
        originalPath
        green_energy
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
            % HARD CODED green power predicted for every hour, in kWh, Should BE DONE USING ML!!!
            % OR USING the FORMULA: E_t = B_t * (1 - CloudCover)
            green = [0; 0; 0; 0; 0; 0; 0.1; 0.2; 0.8; 1.2; 2.0; 2.5; 2.7; 3.2; 3.0;
                2.5; 2.3; 1.7; 1.2; 0.5; 0; 0; 0; 0];
            testCase.green_energy = Renewable(green);
        end
    end
    
    methods (Test)
        function testLAInit(testCase)
            testCase.verifyEqual(testCase.green_energy.distribution, ...
                [0; 0; 0; 0; 0; 0; 0.1; 0.2; 0.8; 1.2; 2.0; 2.5; 2.7; 3.2; 3.0;
                2.5; 2.3; 1.7; 1.2; 0.5; 0; 0; 0; 0]);                    
        end

    end
    
end

