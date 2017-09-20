@echo off
if not exist "%~1" echo Drop here Spyro2/3 subfile! & pause & exit
cd /d %~dp0
:start
if "_%~1_" == "__" pause & goto :eof
echo "%~nx1"
for /L %%i in (0,1,5) do call :loop %1 %%i
call :test "%~1_0.txt" "%~1_1.txt"
shift
goto :start
:loop
yaspyrot.exe "%~1" 0 %2 "%~1_%2.txt"
call :size "%~1_%2.txt"
goto :eof
:size
if "%~z1" == "0" del /f /q %1 0>nul 1>nul
goto :eof
:test
if not exist %1 goto :eof
if not exist %2 goto :eof
if %~z1 lss %~z2 ( del /f /q %1 ) else ( del /f /q %2 )
goto :eof

