:: ===========================================================================
:: CLI-input_test.bat
::
:: Description: 
::     This script tests the CLI input methodology for the 'pixi_pyprojSetup.bat' script.
:: 
:: Usage:
::     Put the script into it's own folder and then run it on the command line.
::     The script will automatically generate the required folders and files.
::     Multiple flags are available for testing, including the following:
::         --repo-sameAs-package • No value required. Sets REPO_SAME_AS_PACKAGE=true.
::         --package=<value> • Sets MY_package and marks PACKAGE_DEFINED=true.
::         --repo=<value> • Sets MY_repo_name and marks REPO_DEFINED=true.
::         --description=<value> • Sets MY_description and marks DESCRIPTION_DEFINED=true.
::         --author=<value> • Sets MY_author.
::         --email=<value> • Sets MY_email.
::         --parent-dirPath=<value> • Sets MY_parent_dirPath.
::         --license-spdx=<value> • Sets MY_license_spdx and marks LICENSE_DEFINED=true.
::
::     Additional '--key=value' flag may be passed. If they are prepended with 'MY_', they will be added to the 'placeholders.config' file, and will be available for replacement (the 'key' would be replaced with the 'value'). 
:: ===========================================================================



@echo off
setlocal EnableDelayedExpansion

:: ==========================================================
:: Global Debug Flag
:: ==========================================================
set "DEBUG_ENABLED=1"


:: ==========================================================
:: Main Script
:: ==========================================================

:: --- Setup configuration folder ---
set "config_dirPath=%CD%\config"
if not exist "%config_dirPath%" (
    mkdir "%config_dirPath%"
)

:: --- Create placeholders.DEFAULT file (if missing) ---
if not exist "%config_dirPath%\placeholders.DEFAULT" (
    echo Creating default placeholders file...
    (
      echo author=Default Author
      echo email=default@example.com
      echo parent_dirPath=C:\Default\ParentDir
      echo package=defaultpackage
      echo repo_name=defaultrepo
      echo description=Default project description goes here
    ) > "%config_dirPath%\placeholders.DEFAULT"
)

:: --- Create placeholders.user file (optional override) ---
if not exist "%config_dirPath%\placeholders.user" (
    echo Creating user placeholder file...
    (
       echo email=useroverride@example.com
       echo repo_name=user_repo_override
    ) > "%config_dirPath%\placeholders.user"
)

:: --- Create pixi_pyprojSetup_config.cmd file ---
if not exist "%config_dirPath%\pixi_pyprojSetup_config.cmd" (
    echo Creating pixi_pyprojSetup_config.cmd file...
    (
       echo @echo off
       echo set "MY_email=configoverride@example.com"
       echo set "templates_dirPath=%CD%\templates"
    ) > "%config_dirPath%\pixi_pyprojSetup_config.cmd"
)

:: --- Create dummy templates folder (if needed) ---
if not exist "%CD%\templates" (
    mkdir "%CD%\templates"
)

echo.
echo --- Starting placeholder and config processing ---
echo.

:: --- 1. Load Default Placeholder Values ---
call :LoadPlaceholders "%config_dirPath%\placeholders.DEFAULT"

:: --- 2. Override with User Placeholder Config (if exists) ---
if exist "%config_dirPath%\placeholders.user" (
    call :debug "Reading from '%config_dirPath%\placeholders.user'."
    call :LoadPlaceholders "%config_dirPath%\placeholders.user"
)

:: --- 3. Load General Configuration Defaults ---
call "%config_dirPath%\pixi_pyprojSetup_config.cmd"

:: --- 4. Process CLI Parameters (highest priority) ---
call :ParseArguments %*

:: --- 5. Consolidate and Debug (Collect additional user input if missing) ---
if not defined PACKAGE_DEFINED (
  echo.
  echo Enter a name for the package (should be lowercase or snake-case):
  set /p "MY_package=>>> "
  set "PACKAGE_DEFINED=true"
)

if defined REPO_SAME_AS_PACKAGE (
  set "MY_repo_name=%MY_package%"
  set "REPO_DEFINED=true"
)

if not defined REPO_DEFINED (
  echo.
  echo Enter a name for the git repo (should be lowercase or kebab-case):
  set /p "MY_repo_name=>>> "
  set "REPO_DEFINED=true"
)

if not defined DESCRIPTION_DEFINED (
  echo.
  echo Enter a short project description (max 1 sentence):
  set /p "MY_description=>>> "
)

echo.
call :debug "Final configuration variables:" "MY_author=%MY_author%" "MY_email=%MY_email%" "MY_parent_dirPath=%MY_parent_dirPath%" "templates_dirPath=%templates_dirPath%" "MY_package=%MY_package%" "MY_repo_name=%MY_repo_name%" "MY_description=%MY_description%" "MY_license_spdx=%MY_license_spdx%"
echo.
echo --- Processing Complete ---
pause
endlocal



:: ============================================================================
::
:: SUBROUTINES
::
:: ============================================================================



:: ==========================================================
:: Centralized Error Handling
:: ==========================================================
:ErrorExit
echo [ERROR]: %~1
exit /b 1

:: ==========================================================
:: Centralized Debug/Logging Subroutine
:: ==========================================================
:debug
if "%DEBUG_ENABLED%"=="1" (
    echo [DEBUG] %*
)
goto :eof

:: ==========================================================
:: LoadPlaceholders Subroutine
:: Reads key=value pairs from a file and sets MY_<key>=value.
:: Usage: call :LoadPlaceholders "full_path_to_file"
:: ==========================================================
:LoadPlaceholders
if not exist "%~1" (
    call :ErrorExit "File '%~1' not found."
)
call :debug "Loading placeholders from '%~1'."
for /f "usebackq tokens=1* delims==" %%A in ("%~1") do (
    set "MY_%%A=%%B"
    call :debug "Set variable 'MY_%%A' to '%%B'."
)
goto :eof

:: ==========================================================
:: ParseArguments Subroutine
:: Processes CLI parameters in the form --key=value.
:: Usage: call :ParseArguments %*
:: ==========================================================
:ParseArguments
:ParseArgsLoop
if "%~1"=="" goto EndParseArgs
set "arg=%~1"

if /I "!arg!"=="--repo-sameAs-package" (
    set "REPO_SAME_AS_PACKAGE=true"
    shift
    goto ParseArgsLoop
)

:: Remove leading '--' and split at '='
for /F "tokens=1,* delims==" %%A in ("%arg:--=%") do (
    set "param=%%A"
    set "val=%%B"
)

if /I "!param!"=="package" (
    set "PACKAGE_DEFINED=true"
    set "MY_package=!val!"
)
if /I "!param!"=="repo" (
    set "REPO_DEFINED=true"
    set "MY_repo_name=!val!"
)
if /I "!param!"=="description" (
    set "DESCRIPTION_DEFINED=true"
    set "MY_description=!val!"
)
if /I "!param!"=="author" (
    set "MY_author=!val!"
)
if /I "!param!"=="email" (
    set "MY_email=!val!"
)
if /I "!param!"=="parent-dirPath" (
    set "MY_parent_dirPath=!val!"
)
if /I "!param!"=="license-spdx" (
    set "LICENSE_DEFINED=true"
    set "MY_license_spdx=!val!"
)
shift
goto ParseArgsLoop
:EndParseArgs
goto :eof