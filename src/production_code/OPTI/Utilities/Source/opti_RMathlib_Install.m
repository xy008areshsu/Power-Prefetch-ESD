%% R-Mathlub Install for OPTI Toolbox
% Copyright (C) 2014 Jonathan Currie (I2C2)

% This file will help you compile the R Standalone Mathlib for use 
% with MATLAB. 

% My build platform:
% - Windows 8 SP1 x64
% - Visual Studio 2012

% To recompile you will need to get / do the following:

% 1) Get R source
% R is available from http://cran.stat.sfu.ca/. 
% Download the source.

% 2) Compile R standalone Math library
% The easiest way to compile R-Mathlib is to use the Visual Studio Project
% Builder included with OPTI. Use the following commands, substituting the 
% required path on your computer:
%
% %% Visual Studio Builder Commands
% path = 'full path to R Source here'; %e.g. 'C:\Solvers\R'
% sdir = [path '\src\nmath']; 
% inc = [path '\src\include\R_ext'];
% name = 'libRMathlib';
% opts = [];
% opts.exPP = {'_CRT_SECURE_NO_WARNINGS','MATHLIB_STANDALONE','HAVE_HYPOT','OLD'};
% opts.exclude = {'test.c'};
% VS_WriteProj(sdir,name,inc,opts)
% %%
%
% Once complete, you will have a directory called R\libRmathlib. Open the
% Visual Studio 2012 project file, then complete the following steps:
%
%   a) Within nmath.h make the following changes:
%       - comment #include <R_ext/RS.h>
%       - comment #include <R_ext/Print.h>
%       - Modify the following defines: (may require limits.h)
%           - #define ISNAN(x) (x!=x)
%           - #define ML_POSINF	std::numeric_limits<double>::infinity()
%           - #define ML_NEGINF	-std::numeric_limits<double>::infinity()
%           - #define ML_NAN std::numeric_limits<double>::quiet_NaN()
%       - Add the following function definitions under #include <Rmath.h>
%           - inline double round(double x) { return x < 0.0 ? ceil(x - 0.5) : floor(x + 0.5); }
%           - inline double trunc(double d){ return (d>0) ? floor(d) : ceil(d) ; }
%   b) Find and replace R_ext/ to a blank string
%   c) Find and replace "isnan" to "ISNAN"
%   d) Find and replace lgamma( to lgammafn(
%   e) Delete the F77_NAME functions in d1mach and i1mach
%   f) Add "#include <nmath.h>" to sunif.c
%   g) Copy from Solvers/RMathlib/Source/Include config.h and Rmath.h to
%   the R/src/nmath folder.
%   h) Right Click the Rmathlib project, click properties, and click C/C++
%   then under the Advanced Tab, Compile as C++ Code.
%   i) Try compile, there should be a number of errors related to cannot
%   cast bool to Rboolean. For each error, manually cast the result (i.e.
%   add (Rboolean)... bit of a pain!).
%   j) Build a Win32 or x64 Release to compile the code.
%   k) Copy the generated .lib file to the following folder:
%
%   OPTI/Utilities/Source/lib/win32 or win64
%
%   You will also need to copy nmath.h to the following folder:
%
%   OPTI/Utilities/Source/Include/Rmathlib

% 3) RMathlib MEX Interface
% The R Math Library does not come with a MEX interface that I know of, so
% I wrote a simple one. Not all functions are present, but it works for my
% purposes. If there are functions you want added, let me know.

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the NLOPT MEX file. Once you have completed all 
% the above steps, simply run this file to compile NLOPT! You MUST BE in 
% the base directory of OPTI!

clear rmathlib

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('RMathlib MEX FILE INSTALL\n\n');

%Get NLOPT Libraries
post = [' -IInclude\Rmathlib -L' libdir ' -llibRMathlib -llibut -output rmathlib -DMATHLIB_STANDALONE'];

%CD to Source Directory
cdir = cd;
cd 'Utilities/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims rmathlibmex.cpp';
try
    eval([pre post])
    movefile(['rmathlib.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:rmathlib','Error Compiling RMathlib!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
