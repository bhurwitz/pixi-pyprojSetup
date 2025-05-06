@echo off

set "script_dirpath=C:\Users\bchur\Desktop\Projects\pixi_pyprojSetup\scripts"
set "input_filename=replaceNestedPlaceholders_test_input.txt"
set "output_filename=replaceNestedPlaceholders_test_output.txt"

echo.
echo ----------------------------------------------------------------------------
echo --- TEST 1 - PS7, no maxIterations, debugging enabled
echo. 

set PWSH_PATH="C:\Program Files\PowerShell\7\pwsh.exe"

%PWSH_PATH% -NoProfile -File %script_dirpath%\ReplacePlaceholders.ps1 -InputFile "%input_filename%" -OutputFile "%output_filename%" -EnvFile "env.txt" -Debug

pause

echo.
echo ----------------------------------------------------------------------------
echo TEST 2 - PS7, maxIterations set to 3, debugging enabled
echo.

%PWSH_PATH% -NoProfile -File %script_dirpath%\ReplacePlaceholders.ps1 -InputFile "%input_filename%" -OutputFile "%output_filename%" -EnvFile "env.txt" -maxIterations 3 -Debug

pause

echo.
echo ----------------------------------------------------------------------------
echo TEST 3 - PS7, no maxIterations, debugging DISABLED
echo.

%PWSH_PATH% -NoProfile -File %script_dirpath%\ReplacePlaceholders.ps1 -InputFile "%input_filename%" -OutputFile "%output_filename%" -EnvFile "env.txt" 

pause



set PWSH_PATH="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

echo.
echo ----------------------------------------------------------------------------
echo TEST 4 - PS5.1, no maxIterations, debugging enabled
echo.

%PWSH_PATH% -NoProfile -File %script_dirpath%\ReplacePlaceholders.ps1 -InputFile "%input_filename%" -OutputFile "%output_filename%" -EnvFile "env.txt" -Debug

pause

echo.
echo ----------------------------------------------------------------------------
echo TEST 5 - PS5.1, maxIterations set to 3, debugging enabled
echo.

%PWSH_PATH% -NoProfile -File %script_dirpath%\ReplacePlaceholders.ps1 -InputFile "%input_filename%" -OutputFile "%output_filename%" -EnvFile "env.txt" -maxIterations 3 -Debug

pause

echo.
echo ----------------------------------------------------------------------------
echo TEST 6 - PS5.1, no maxIterations, debugging DISABLED
echo.

%PWSH_PATH% -NoProfile -File %script_dirpath%\ReplacePlaceholders.ps1 -InputFile "%input_filename%" -OutputFile "%output_filename%" -EnvFile "env.txt" -NoDebug

pause