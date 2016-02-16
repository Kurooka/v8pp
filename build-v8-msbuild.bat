cd v8
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\vcvars32.bat"
rem msbuild /m /p:Configuration=Release /p:Platform="Any CPU"  /p:TreatWarningsAsErrors=0 /p:WarningLevel=1 tools\gyp\v8.sln
msbuild tools\gyp\v8.sln
