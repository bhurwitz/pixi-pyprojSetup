@echo off
setlocal

REM Set the path to PowerShell 7 (if installed).
set PWSH_PATH="C:\Program Files\PowerShell\7\pwsh.exe"

REM Check if PowerShell 7 exists.
if exist %PWSH_PATH% (
    echo Running with PowerShell 7...
) else (
    echo Running with PowerShell 5.1...
    set PWSH_PATH="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
)

REM Step 1: Create a dummy TOML file.
set TOML_FILE=test_toml_file.toml
(
echo [package]
echo name = "example_package"
echo version = "0.1.0"
) > %TOML_FILE%

REM Step 2: Display the original TOML file.
echo.
echo Original TOML file:
type %TOML_FILE%

REM Step 3: Test with configuration file.
%PWSH_PATH% -NoProfile -File toml_insert.ps1 -ConfigFile "toml_insert.config"
REM powershell -NoProfile -File toml_insert.ps1 -ConfigFile "toml_insert.config" -Debug

REM Step 4: Display the resulting TOML file.
echo.
echo Resulting TOML file from config-file method:
type %TOML_FILE%

echo.
echo Press enter to move the to direct-pass method.
pause

REM Step 5: Remake the dummy TOML file.
set TOML_FILE=test_toml_file.toml
(
echo [package]
echo name = "example_package"
echo version = "0.1.0"
) > %TOML_FILE%

REM Step 6: Test with direct arguments.
echo.
echo Attempting the direct-passing method.
echo.
powershell -NoProfile -File toml_insert.ps1 ^
  -File "test_toml_file.toml" ^
  -Insertions "{\"readme\":\"README.md\",\"license-files\":\"[\\\"LICENSE.txt\\\"]\"}" ^
  -Anchor "version =" ^
  -Debug

REM Step 7: Display the resulting TOML file.
echo.
echo Resulting TOML file from direct-pass method:
type %TOML_FILE%

REM Step 8: Cleanup.
echo.
pause
REM del %TOML_FILE%
endlocal
