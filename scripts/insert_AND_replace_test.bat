:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Tests the insertion (toml_insert.ps1) and replacement (toml_replace.ps1) sctips using external configuration files on a dummy TOML file and in conjuction with placeholder replacements (ReplacePlaceholders.ps1).
::
:: Make sure all three scripts reside in the same directory as this script. 
::
:: The test TOML and config files will be overwritten with each run of this script, but they will not be deleted.
::
:: PowerShell 7 will be used by default, and 5.1 will be the fallback.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off
setlocal

:: Check if /debug was passed
if /I "%~1"=="/debug" (
    set DEBUG=true
    echo.
    echo --- DEBUGGING ENABLED ---
    echo.
    shift
)

REM Set the path to PowerShell 7 (if installed).
set PWSH_PATH="C:\Program Files\PowerShell\7\pwsh.exe"

REM Check if PowerShell 7 exists.
if exist %PWSH_PATH% (
    echo Running with PowerShell 7.
) else (
    echo Running with PowerShell 5.1.
    set PWSH_PATH="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
)

REM Step 1: Create a dummy TOML file.
set TOML_FILE=test_toml_file.toml
(
echo [package]
echo name = "{package}"
echo version = "0.1.0"
echo description = "{description}"
echo authors = [{name = "Default Name", email = "default@name.com"}]
) > %TOML_FILE%

echo.
echo Original TOML file:
type %TOML_FILE%

echo.
echo Generating the insertion config file...

REM Test 'Insert' with configuration file.
(
    echo // A comment above the brace.
    echo {
    echo     // Test comment for insertion config.
    echo     "File": "test_toml_file.toml",
    echo     "Insertions": {
    echo         "readme": "README.md",   // Add readme and license info
    echo         "license-files": "[\"LICENSE.txt\"]",
    echo         "license-name": "{license_spdx}",
    echo     },
    echo     "Anchor": "version =",
    echo     /* a block comment, not inline */
    echo }
    echo // A comment below the brace.
) > toml_insert_test.config

echo.
echo 'toml_insert_test.config':
type toml_insert_test.config
echo.
echo Press enter to run the insertion script.
echo.
pause

echo.
echo Running the insertion script 'toml_insert.ps1'

if defined DEBUG (
    %PWSH_PATH% -NoProfile -File toml_insert.ps1 -ConfigFile "toml_insert_test.config" -Debug
) else (
    %PWSH_PATH% -NoProfile -File toml_insert.ps1 -ConfigFile "toml_insert_test.config"
)

echo.
echo Completed

echo.
echo TOML file, post-insertion:
type %TOML_FILE%
echo.
echo.
echo Press enter to move to replacement.
echo.
pause

echo.
echo Generating the config file for the replacement script...

REM Test 'Replace' with configuration file
(
    echo // A comment above the brace.
    echo {
    echo     // Test comment for replacement config.
    echo     "File": "test_toml_file.toml",
    echo     "Replacements": {
    echo         "authors": "[{name = \"{author}\", email = \"{email}\"}]",
    echo     },
    echo }
    echo // A comment below the brace.
) > toml_replace_test.config

echo.
echo 'toml_replace_test.config':
type toml_replace_test.config
echo.
echo.
echo Press enter to run the replacement script.
echo.
pause

echo.
echo Running the replacement script 'toml_replace.ps1'

if defined DEBUG (
    %PWSH_PATH% -NoProfile -File toml_replace.ps1 -ConfigFile "toml_replace_test.config" -Debug
) else (
    %PWSH_PATH% -NoProfile -File toml_replace.ps1 -ConfigFile "toml_replace_test.config"
)

echo.
echo Complete

echo.
echo TOML file, post-replacement:
type %TOML_FILE%
echo.
echo.
echo Press enter to move to placeholders.
echo.
pause


echo.
echo Building the placeholder environmental file

REM Build a placeholders file to use
(
    echo description=The description for 'insert_AND_replace_test.bat'.
    echo package=insert_AND_replace_test
    echo license_spdx=MIT
    echo author=Ben H.
    echo email=bch+{package}@gmail.com
) > placeholders_test.env

echo.
echo The placeholders file:
type placeholders_test.env
echo.
echo.
echo Press enter to run the placeholders script.
echo.
pause

echo.
echo Running the placeholders replacements script...

if defined DEBUG (
    %PWSH_PATH% -NoProfile -File ReplacePlaceholders.ps1 -InputFile "%TOML_FILE%" -OutputFile "%TOML_FILE%" -EnvFile "placeholders_test.env" -Debug
) else (
    %PWSH_PATH% -NoProfile -File ReplacePlaceholders.ps1 -InputFile "%TOML_FILE%" -OutputFile "%TOML_FILE%" -EnvFile "placeholders_test.env"
)    
    
echo.
echo Completed

echo.
echo Finalized TOML file:
type %TOML_FILE%
echo.
echo.
echo Press enter to exit.
echo.
pause