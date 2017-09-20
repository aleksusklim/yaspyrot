@echo off
if NOT EXIST "%~1" echo Drop here your 256-byte table! & pause & exit
if NOT "%~z1" == "256" echo Table size must be exactly 256! & pause & exit
echo set yaspyrot_table="%~s1" >"%~dp0table.bat"