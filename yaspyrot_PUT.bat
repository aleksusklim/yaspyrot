@echo off
if not exist "%~1" echo Drop here Spyro2/3 subfile! (than one which was extracted) & pause & exit
cd /d %~dp0
set yaspyrot_table=256.256
if exist table.bat call table.bat
:start
if "_%~1_" == "__" pause & goto :eof
echo "%~nx1"
for /L %%i in (0,1,5) do call :loop %1 %%i
shift
goto :start
:loop
if exist "%~1_%2.txt" yaspyrot.exe "%~1" 0 %2 "%~1_%2.txt" %yaspyrot_table%
goto :eof
