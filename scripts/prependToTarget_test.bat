@echo off
REM ---------------------------------------------------------------------
REM This batch file demonstrates calling the prependToTarget.ps1 PowerShell script.
REM It creates a sample target file and a sample boilerplate file, then calls
REM the PS script to prepend both a file and literal text.
REM This is function for both PS5.1 and PS7.
REM ---------------------------------------------------------------------

REM Change these paths as needed.
set "SCRIPT=PrependToTarget.ps1"
set "TARGET_FILE=PrependToTarget_test_arget.txt"
set "BOILERPLATE_FILE=PrependToTarget_test_Boilerplate.txt"

REM Create a sample target file.
echo This is the original content. > "%TARGET_FILE%"

REM Create a sample boilerplate file.
echo THIS IS THE BOILERPLATE FILE. > "%BOILERPLATE_FILE%"

REM Call the PS script:
REM The first parameter is the target file.
REM The remaining parameters are:
REM   - a file (the boilerplate file)
REM   - literal text (an additional line)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" "%TARGET_FILE%" "%BOILERPLATE_FILE%" "This is literal prepended text."

echo.
echo Updated target file content:
type "%TARGET_FILE%"
echo.
echo Press enter to re-run it with PS7.
pause

pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" "%TARGET_FILE%" "%BOILERPLATE_FILE%" "This is literal prepended text."

echo.
echo Updated target file content:
type "%TARGET_FILE%"
echo.
echo Press enter to exit script. 
pause