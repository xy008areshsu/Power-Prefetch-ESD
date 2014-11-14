%% Main test suite script. Call this script to invoke the test suite. 

clear; clc; close all

import matlab.unittest.TestRunner;
import matlab.unittest.TestSuite;


suite = TestSuite.fromFolder(pwd);
result = run(suite);
disp(result);



