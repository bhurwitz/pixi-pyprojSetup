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
REM ==========================================================
REM Setup testing environment and configuration files
REM ==========================================================
REM Define the config folder relative to the current directory.
set "config_dirPath=%CD%\config"

REM Create the config folder if it does not exist.
if not exist "%config_dirPath%" (
    mkdir "%config_dirPath%"
)

REM -------------------------------
REM Create placeholders.DEFAULT file (if missing)
REM -------------------------------
if not exist "%config_dirPath%\placeholders.DEFAULT" (
    echo Creating default placeholders file...
    (
      echo author=Default Author
      echo email=default@example.com
      echo parent_dirPath=C:\Default\ParentDir
      echo package=defaultpackage
      echo repo_name=defaultrepo
      echo description=Default description goes here
    ) > "%config_dirPath%\placeholders.DEFAULT"
)

REM -------------------------------
REM Create placeholders.user file (optional override)
REM -------------------------------
if not exist "%config_dirPath%\placeholders.user" (
    echo Creating user placeholder file...
    (
       echo email=useroverride@example.com
       echo repo_name=user_repo_override
    ) > "%config_dirPath%\placeholders.user"
)

REM -------------------------------
REM Create pixi_pyprojSetup_config.cmd file.
REM -------------------------------
if not exist "%config_dirPath%\pixi_pyprojSetup_config.cmd" (
    echo Creating pixi_pyprojSetup_config.cmd file...
    (
       echo @echo off
       echo set "MY_email=configoverride@example.com"
       echo set "templates_dirPath=%CD%\templates"
    ) > "%config_dirPath%\pixi_pyprojSetup_config.cmd"
)

REM Create a dummy templates folder (if needed) for demonstration.
if not exist "%CD%\templates" (
    mkdir "%CD%\templates"
)

REM ==========================================================
REM Main Script Logic
REM ==========================================================
echo.
echo --- Starting placeholder and config processing ---
echo.

REM :: Priorities:
REM :: 1. CLI argument
REM :: 2. User's prompt responses
REM :: 3. pixi_pyprojSetup_config.cmd
REM :: 4. placeholders.user, if applicable
REM :: 5. Fixed default in 'placeholders.DEFAULT'

REM -------------------------------
REM 1. Load Default Placeholder Values
REM -------------------------------
if not exist "%config_dirPath%\placeholders.DEFAULT" (
    echo ERROR: Default placeholders file not found.
    exit /b 1
)

call :debug "-----" "Reading from '%config_dirPath%\placeholders.DEFAULT'"
for /f "usebackq tokens=1* delims==" %%A in ("%config_dirPath%\placeholders.DEFAULT") do (
    set "MY_%%A=%%B"
    call :debug "Variable 'MY_%%A' set to '%%B'"
)

REM -------------------------------
REM 2. Override with User Placeholder Config (if exists)
REM -------------------------------
if exist "%config_dirPath%\placeholders.user" (
    call :debug "-----" "Reading from %config_dirPath%\placeholders.user"
    for /f "usebackq tokens=1* delims==" %%A in ("%config_dirPath%\placeholders.user") do (
        set "MY_%%A=%%B"
        call :debug "Variable 'MY_%%A' set to '%%B'"
    )
)

REM -------------------------------
REM 3. Load General Configuration Defaults
REM -------------------------------
call "%config_dirPath%\pixi_pyprojSetup_config.cmd"

REM -------------------------------
REM 4. Process CLI Parameters (highest priority)
REM -------------------------------
REM Accept parameters in the form of --key=value.
:parse_args
if "%~1"=="" goto after_args

set "arg=%~1"

if /I "!arg!"=="--repo-sameAs-package" (
  set "REPO_SAME_AS_PACKAGE=true"
  shift
  goto parse_args
)

REM Remove the leading "--" and split at "="
for /F "tokens=1,* delims==" %%A in ("%arg:--=%") do (
    set "param=%%A"
    set "val=%%B"
)

REM Override user details based on flags.
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
goto parse_args

:after_args
REM -------------------------------
REM 5. Consolidate and Debug (Collect additional user input if missing)
REM -------------------------------

if not defined PACKAGE_DEFINED (
  echo.
  echo Enter a name for the package.
  echo    (This will be the name of the root directory and for imports. Should be lowercase or snake-case.)
  echo.
  set /p "MY_package=>>> "
  set "PACKAGE_DEFINED=true"
)

if defined REPO_SAME_AS_PACKAGE (
  set "MY_repo_name=%MY_package%"
  set "REPO_DEFINED=true"
)

if not defined REPO_DEFINED (
  echo.
  echo Enter a name for the git repo.
  echo    (This will be the name of the git repo; should be lowercase or kebab-case.)
  echo.
  set /p "MY_repo_name=>>> "
  set "REPO_DEFINED=true"
)

if not defined DESCRIPTION_DEFINED (
  echo.
  echo Enter a short project description.
  echo    (This will be displayed in the .toml and the README – max 1 sentence.)
  echo.
  set /p "MY_description=>>> "
)

echo.
call :debug "Final configuration variables:" "MY_author='%MY_author%'" "MY_email='%MY_email%'" "MY_parent_dirPath='%MY_parent_dirPath%'" "templates_dirPath='%templates_dirPath%'" "MY_package='%MY_package%'" "MY_repo_name='%MY_repo_name%'" "MY_description='%MY_description%'" "MY_license_spdx='%MY_license_spdx%'"
echo.
echo --- Processing Complete ---
pause
goto :eof

:debug
REM Debug routine: it echoes each parameter prefixed with [DEBUG]
setlocal EnableDelayedExpansion
for %%D in (%*) do (
    echo [DEBUG] %%D
)
endlocal
goto :eof
