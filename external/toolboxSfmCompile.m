function toolboxSfmCompile()
% Compiles all the private routines
%
% assumes located in toolbox root directory
%
% if you get warnings on linux because yourgcc istoo old/new, you can
% force the gcc version this way
%  opts = {'CXX=g++-4.1' 'CC=g++-4.1' 'LD=g++-4.1' etc
% USAGE
%  toolboxCompile
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%
% See also
%
% Done

disp('Compiling.......................................');
savepwd=pwd; cd(fileparts(mfilename('fullpath'))); cd('../');

dirSBA = [ pwd '/external/sba/'];

cd(dirSBA);

% delete previous object files
fileList = {'sba_levmar.o', 'sba_levmar_wrap.o', 'sba_lapack.o', ...
  'sba_crsm.o', 'sba_chkjac.o', 'libsba.a', 'sba.lib', ...
  'matlab/sba.mexw32'};
for i=1:length(fileList)
  if exist(fileList{i}, 'file'), delete(fileList{i}); end
end

switch computer
  case 'PCWIN',
    % Matlab on Windows 32 (not sure about 64)
    % You need this variable as an environment variable
    %       set INCLUDE="C:\Program Files\Microsoft Visual Studio
    %       8\VC\include"
    system('nmake /f Makefile.vc sba.lib');
  case {'GLNX86', 'GLNXA64', 'i686-pc-linux-gnu', 'x86_64-pc-linux-gnu'},
    % Matlab and Octave on Linux
    system([ 'gcc -w -O3 -fPIC -c sba.h sba_chkjac.h compiler.h ' ...
      'sba_levmar.c sba_levmar_wrap.c sba_lapack.c sba_crsm.c ' ...
      'sba_chkjac.c' ]);
    system([ 'ar crv libsba.a sba_levmar.o sba_levmar_wrap.o ' ...
      'sba_lapack.o sba_crsm.o sba_chkjac.o' ]);
    system('ranlib libsba.a');
end

cd matlab
switch computer
  case 'PCWIN',
    % Matlab on Windows 32 (not sure about 64)
    system('nmake /f Makefile.w32 sba.mexw32');
  case {'GLNX86', 'GLNXA64'},
	% Matlab on Linux
	mex -I../ -O sba.c ../libsba.a /usr/lib/libblas.a ...
	  /usr/lib/liblapack.a;
  case {'i686-pc-linux-gnu', 'x86_64-pc-linux-gnu'},
	% Octave on Linux
    mkoctfile -v --mex ./sba.c -I../ -lsba -L../
end

cd ../../..

cd sfm/private/sba
switch computer
  case 'PCWIN',
    % Matlab on Windows 32 (not sure about 64)
    system('cl /nologo /O2 sbaProjection.c /link /dll /out:sbaProjection.dll');
  case {'GLNX86','GLNXA64','i686-pc-linux-gnu', 'x86_64-pc-linux-gnu'},
    % Matlab and Octave on Linux
    system('gcc -Wall -fPIC -O3 -shared -o sbaProjection.so sbaProjection.c');
end
cd ../../..

rd=fileparts(mfilename('fullpath')); rd=rd(1:end-9);

% general compile options (can make architecture specific)
optsAfter={};
switch computer
  case 'PCWIN',
    % Matlab on Windows 32 (not sure about 64)
	lapacklib = fullfile(matlabroot, 'extern', 'lib', 'win32', ...
	  'microsoft', 'libmwlapack.lib');
	blaslib = fullfile(matlabroot, ...
	  'extern', 'lib', 'win32', 'microsoft', 'libmwblas.lib');
	opts={'-output'};
	optsAfter = {lapacklib, blaslib};
  case {'GLNX86', 'GLNXA64'},
    % Matlab on Linux
	% if you get warnings on linux, you could force the gcc version by
	% adding those options: 'CXX=g++-4.1' 'CC=g++-4.1' 'LD=g++-4.1'
	opts = {'-l' 'mwlapack' '-l' 'mwblas' '-output' };
  case {'i686-pc-linux-gnu', 'x86_64-pc-linux-gnu'},
	% Octave on Linux
	opts = {'-o'};
end

% general compile options
fs={'computeCsfmInfimumMex','refineExteriorOrientationMex', ...
  'msfmRotationDerivativeMex'};
ds={'nrsfm', 'sfm', 'msfm'};
for i=1:length(fs)
  mex(opts{:},[rd '/' ds{i} '/private/' fs{i} '.' mexext], ...
    [rd '/' ds{i} '/private/' fs{i} '.c'], optsAfter{:});
end

cd(savepwd); disp('..................................Done Compiling');

end
