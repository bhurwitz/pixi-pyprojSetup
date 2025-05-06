:: This file is copyrighted by Ben Hurwitz <bchurwitz+pixi_pyprojSetup@gmail.com>, 2025, under the GNU GPL v3.0. 
:: Much of this file was written with the help of ChatGPT, versions GPT-4o, GPT-4o mini, and o3-mini.
:: See <https://chatgpt.com/share/67ffcd98-a7a8-800e-9dcd-8c4b78f895f8> and <https://chatgpt.com/share/68029d02-9f70-800e-a201-8765513870a8>
::
:: This file is version-controlled via git and saved on GitHub under the repository <https://github.com/bhurwitz/pixi-pyprojSetup>
::
:: TODO: Incorporate semantic-release (https://python-semantic-release.readthedocs.io/en/latest/) for versioning and changelog.

@echo off
setlocal EnableDelayedExpansion

set DEBUG=false
set "TAB=    "
for /f "usebackq delims=" %%A in (
  `powershell -NoProfile -Command "$Host.UI.RawUI.WindowSize.Width"`
) do set "COLS=%%A"

REM I'm not clear why, but if I don't clearly define these as nothing at the outset, sometimes multiple runnings of the script will cause them to be set incorrectly. 
set "CLI_package="
set "CLI_repo="
set "CLI_desc="
set "AUTHOR_DEFINED="
set "EMAIL_DEFINED="
set "LICENSE_DEFINED="

:startOfScript

call :SectionHeader "Script Start"

echo Welcome to pixi-pyprojSetup :-)
echo.
echo This script is used to setup a Python project with Pixi, the package management software.
echo.

:: Check if pixi is available
where pixi >nul 2>&1
if %errorlevel%==1 (
  echo [ERROR] Pixi is not installed! Exiting...
  exit /b    
) else (
    REM echo We're going to update Pixi first.
    REM pixi self-update
)


:setGlobalDebug

call :SubsectionHeader "Debug status"

:: ==========================================================
:: Global Debug Flag
:: ==========================================================
REM set "DEBUG=true"
set MAX_DEBUG=4

REM :: Set default if not provided
if defined DEBUG_LEVEL (
    if !DEBUG_LEVEL! LSS 1 (
        set DEBUG_LEVEL=0
        call :log "STATUS" "Debugging was DISABLED via global environmental variable."
    ) 
    if !DEBUG_LEVEL! GTR %MAX_DEBUG% (
        set DEBUG_LEVEL=%MAX_DEBUG%
        call :debug !DEBUG_LEVEL! "Debugging was ENABLED at level !DEBUG_LEVEL! via global environmental variable."
        call :log "WARNING" "DEBUG_LEVEL had been set above the maximum of %MAX_DEBUG%, so it was reset to the maximum level."
    )
    if !DEBUG_LEVEL! GTR 0 if !DEBUG_LEVEL! LEQ $MAX_DEBUG% (
        call :debug !DEBUG_LEVEL! Debugging ENABLED at level !DEBUG_LEVEL! via global environmental variable.
    )
)

REM The DEBUG_LEVEL can be overwritten by passing it through the CLI, e.g. "--debug=2", but it (like any CLI parameter for this script) must be quoted in its entirety, e.g. "debug=2" not just debug=2.
call :debug 1 "Looking for a 'debug' CLI parameter..."
for %%A in (%*) do (
    if not defined DEBUG_SET (
        set "curr=%%A"
        REM call :log "INFO" "I see '!curr!'."
        REM Remove the quotes
        set "arg=%%~A"
        call :debug 2 "I see '!arg!' (quotes removed)."
        REM Remove the leading double-dashes, if passed.
        if "!arg:~0,2!"=="--" set "arg=!arg:~2!"
        call :debug 2 "And now it's '!arg!'."
        REM Split the argument at the first '='
        for /F "tokens=1,2 delims==" %%B in ("!arg!") do (
            call :debug 2 "Now it's split into '%%B' and '%%C'."
            REM Identify the debug flag and set it. 
            if /I "%%B"=="debug" (
                call :debug 2 "There it is!"
                if defined DEBUG_LEVEL (
                    set prevDebug=!DEBUG_LEVEL!
                    set "DEBUG_LEVEL=%%C"
                    call :debug !DEBUG_LEVEL! "Debugging level ADJUSTED from !prevDebug! to !DEBUG_LEVEL! via the CLI."
                ) else (
                    set "DEBUG_LEVEL=%%C"
                    call :debug !DEBUG_LEVEL! "Debugging ENABLED at level !DEBUG_LEVEL! via CLI."
                )
                set DEBUG_SET=true
            )
        )
    )
)

if not defined DEBUG_LEVEL set DEBUG_LEVEL=0

if %DEBUG_LEVEL% LSS 1 call :log "STATUS" "Debugging was NOT ENABLED."


REM :: Check if /debug was passed
REM if /I "%~1"=="/debug" (
    REM set DEBUG=true
    REM call :debug "DEBUGGING ENABLED"
    REM shift
REM )


REM :: Process CLI first so it overrides any existing environment variable
REM call :ParseArguments %*


set "PWSH_PATH=C:\Program Files\PowerShell\7\pwsh.exe"

REM Check if PowerShell 7 exists.
if exist "%PWSH_PATH%" (
    call :debug "Running with PowerShell 7"
) else (
    call :debug "Powershell 7 does not exist. Running with PowerShell 5.1 ^(or whatever is installed^)."
    set "PWSH_PATH=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
)


REM call :WaitForEnter "load configuration files"
REM if defined ABORT_SCRIPT exit /b 1

REM ===========================================================================

REM ============== OLD METHOD

REM REM === ENVIRONMENTAL VARS

REM :: Priorities:
REM :: 1. CLI argument
REM :: 2. Config.bat
REM :: 3. placeholders.config, if applicable
REM :: 4. Fixed default

REM set "ConfigFile=%CD%\pixi-pyprojSetup.env"


REM :: %1 = USER_NAME, %2 = USER_EMAIL, %3 = DEFAULT_PARENT_DIR, %4 = TEMPLATES_DIR, %5 = PLACEHOLDERS_FILE
REM set "USER_NAME_ARG=%~1"
REM set "USER_EMAIL_ARG=%~2"
REM set "DEFAULT_PARENT_DIR_ARG=%~3"
REM set "TEMPLATES_DIR_ARG=%~4"
REM set "PLACEHOLDERS_FILE_ARG=%~5"

REM :: --- Load config.bat into a temp scope ---
REM set "CONFIG_LOADED=false"
REM if exist %ConfigFile% (
    REM call :load_config %ConfigFile%
    REM set "CONFIG_LOADED=true"
    REM call :debug "Config file loaded"
REM ) else (call :debug "Config file '%ConfigFile%' not found.")

REM :: --- Handle 'placeholders' file first
REM if not "%PLACEHOLDERS_FILE_ARG%"=="" (
    REM set "placeholders_file=%PLACEHOLDERS_FILE_ARG%"
    REM call :debug "placeholder 1"
REM ) else if defined CONFIG_PLACEHOLDERS (
    REM set "placeholders_file=%CONFIG_PLACEHOLDERS%"
    REM call :debug "placeholder 2"
REM ) else (
    REM set "placeholders_file=placeholders.config.DEFAULT"
    REM call :debug "placeholder 3"
REM )

REM REM if defined CONFIG_PLACEHOLDER_REPLACEMENT_SCRIPT (
    REM REM set "placeholder_script=%CONFIG_PLACEHOLDER_REPLACEMENT_SCRIPT%"
    REM REM call :debug "placeholder script 1"
REM REM ) else (
    REM REM set "placeholder_script=%CD%\scripts\ReplacePlaceholders.ps1"
    REM REM call :debug "placeholder script 2"
REM REM )

REM :: Load default placeholders
REM call :debug "Placeholder file set to: %placeholders_file%."

REM for /f "usebackq tokens=1* delims==" %%A in ("%placeholders_file%") do (
    REM set "license_spdx%%A=%%B"
REM )

REM call :debug "Placeholders loaded"
REM if "%DEBUG%"=="true" (
  REM for /f "tokens=* delims=" %%V in ('set license_spdx') do (
      REM echo %%V
  REM )
REM )


REM echo.
REM echo -------------------------------------------------------------------------
REM echo.



REM REM === Collect user input ===
REM set /p package=Enter a name for the package (lower- or snake-case): 
REM set /p repo_name_name=Enter a name for the repo (lower- or kebab-case): 
REM REM set /p author=Enter author name: 
REM REM set /p email=Enter email address:
REM setlocal DisableDelayedExpansion
REM echo Enter a short project description
REM echo     ^(1 sentence; what does this package do, why does it exist?^)
REM echo     [No carets, greater/less than symbols cannot be to the right of a double-quote character]
REM echo.
REM set /p "TMP_DESC=  >>> "
REM endlocal & set "description=%TMP_DESC%"


REM :: --- Assign author ---
REM if not "%USER_NAME_ARG%"=="" (
    REM set "author=%USER_NAME_ARG%"
    REM call :debug "user name 1"
REM ) else if defined CONFIG_USER_NAME (
    REM set "author=%CONFIG_USER_NAME%"
    REM call :debug "user name 2"
REM ) else if not defined author (
    REM set "author=Default Name"
    REM call :debug "user name 3"
REM )

REM :: --- Assign email ---
REM if not "%USER_EMAIL_ARG%"=="" (
    REM set "email=%USER_EMAIL_ARG%"
    REM call :debug "user email 1"
REM ) else if defined CONFIG_USER_EMAIL (
    REM set "email=%CONFIG_USER_EMAIL%"
    REM call :debug "user email 2"
REM ) else if not defined email (
    REM set "email=default@email.com"
    REM call :debug "user email 3"
REM )

REM :: --- Assign defaultDir ---
REM if not "%DEFAULT_PARENT_DIR_ARG%"=="" (
    REM set "defaultDir=%DEFAULT_PARENT_DIR_ARG%"
    REM call :debug "default parent dir 1"
REM ) else if defined CONFIG_DEFAULT_PARENT_DIR (
    REM set "defaultDir=%CONFIG_DEFAULT_PARENT_DIR%"
    REM call :debug "default parent dir 2"
REM ) else (
    REM set "defaultDir=C:\Temp\Projects"
    REM call :debug "default parent dir 3"
REM )

REM :: --- Assign templatesDir ---
REM if not "%TEMPLATES_DIR_ARG%"=="" (
    REM set "templatesDir=%TEMPLATES_DIR_ARG%"
    REM call :debug "default templates dir 1"
REM ) else if defined CONFIG_TEMPLATES_DIR (
    REM set "templatesDir=%CONFIG_TEMPLATES_DIR%"
    REM call :debug "default templates dir 2"
REM ) else (
    REM set "templatesDir=%CD%\_templates"
    REM call :debug "default templates dir 3"
REM )

REM :: Debug print
REM echo Name: '%author%'
REM echo Email: '%email%'
REM echo Parent Dir: '%defaultDir%'
REM echo Templates Dir: '%templatesDir%'
REM echo Package: '%package%'
REM echo Repo: '%repo_name%'
REM echo.

REM The config path needs to be hardcoded in so that we can actually find the configuration files. There are probably other ways of doing this, too.
REM set "config_dirPath=%CD%\config"


REM REM ================================
REM REM 1. Load Default Placeholder Values
REM REM ================================
REM if not exist "%config_dirPath%\placeholders.DEFAULT" (
    REM echo ERROR: Default placeholders file not found.
    REM exit /b 1
REM )

REM REM Load default placeholder pairs and prefix with license_spdx
REM call :debug "-----" "Reading from '%config_dirPath%\placeholders.DEFAULT'"
REM for /f "usebackq tokens=1* delims==" %%A in ("%config_dirPath%\placeholders.DEFAULT") do (
    REM set "license_spdx%%A=%%B"
    REM call :debug "Variable 'license_spdx%%A' set to '%%B'"
REM )

REM REM ================================
REM REM 2. Override with User Placeholder Config (if exists)
REM REM ================================
REM if exist "%config_dirPath%\placeholders.user" (
    REM call :debug "-----" "Reading from %config_dirPath%\placeholders.user"
    REM for /f "usebackq tokens=1* delims==" %%A in ("%config_dirPath%\placeholders.user") do (
        REM set "license_spdx%%A=%%B"
        REM call :debug "Variable 'license_spdx%%A' set to '%%B'"
    REM )
REM )

REM REM ================================
REM REM 3. Load General Configuration Defaults
REM REM ----------------
REM REM This file (projSetup.env) stores all user-specific
REM REM settings (e.g. NAME, EMAIL, PROJECT_PARENT_DIR).
REM REM It might also include additional overrides for placeholders,
REM REM e.g. set "SOMEKEY=SomeValue"
REM REM ================================
REM call "%config_dirPath%\pixi_pyprojSetup_config.cmd"
REM REM call :debug "-----" "Reading from %config_dirPath%\pixi_pyprojSetup.env"
REM REM for /F "tokens=1,* delims==" %%A in (%config_dirPath%\pixi_pyprojSetup.env) do (
    REM REM if not "%%B"=="" (
      REM REM set "license_spdx%%A=%%B"
      REM REM call :debug "Variable 'license_spdx%%A' set to '%%B'"
    REM REM )
REM REM )


REM REM ================================
REM REM 4. Process CLI Parameters (highest priority)
REM REM ----------------
REM REM Format expected: --key=value
REM REM For placeholders like name/email, both the general variable and
REM REM the license_spdx prefixed version will be set in case they're used in the templates.
REM REM ================================
REM :parse_args
REM if "%~1"=="" goto after_args

REM set "arg=%~1"

REM if "!arg!"=="--repo-sameAs-package" (
  REM set "REPO_SAME_AS_PACKAGE=true"
  REM shift
  REM goto parse_args
REM )

REM :: %%B will be everything after the delimitere
REM for /F "tokens=1,* delims==" %%A in ("%arg:--=%") do (
    REM set "param=%%A"
    REM set "val=%%B"
REM )

REM :: Override user details
REM if /I "!param!"=="package" (
  REM set "PACKAGE_DEFINED=true"
  REM set "package==!val!"
REM )
REM if /I "!param!"=="repo" (
  REM set "REPO_DEFINED=true"
  REM set "repo_name_name=!val!"
  
REM )
REM if /I "!param!"=="description" (
  REM set "DESCRIPTION_DEFINED=true"
  REM set "description=!val!"
REM )
REM if /I "!param!"=="author" set "author=!val!"
REM if /I "!param!"=="email" set "email=!val!"
REM if /I "!param!"=="parent-dirPath" set "parent_dirPath=!val!"
REM REM if /I "!param!"=="year" set "year=!val!"
REM REM if /I "!param!"=="date" set "date=!val!"
REM if /I "!param!"=="license-spdx" (
  REM set "LICENSE_DEFINED=true"
  REM set "license_spdx=!val!"
REM )
REM REM if /I "!param!"=="description" set "description=!val!"
REM REM if /I "!param!"=="project_name" set "project_name=!val!"
REM REM if /I "!param!"=="proj_root set "proj_root=!val!"
REM REM if /I "!param!"=="repo_name" set "repo_name_name=!val!"
REM REM if /I "!param!"=="version" set "version=!val!"


REM shift
REM goto parse_args

REM :after_args

REM REM ================================
REM REM 5. Consolidate and Debug
REM REM ----------------
REM REM Echo the final license_spdx* variables to a temporary file for placeholder replacement.
REM REM Optionally, call your custom debug routine to list the current configuration.
REM REM ================================


REM REM === Collect user input ===
REM if not defined PACKAGE_DEFINED (
  REM echo Enter a name for the package.
  REM echo %TAB%This will be the name of the root directory and for imports.
  REM echo %TAB%Should be lowercase or snake-case.
  REM echo.
  REM set /p "package=>>> "
  REM set "PACKAGE_DEFINED=true"
REM )

REM if defined REPO_SAME_AS_PACKAGE (
  REM set "repo_name_name=%package%"
  REM set "REPO_DEFINED=true"
REM )

REM if not defined REPO_DEFINED (
  REM echo.
  REM echo Enter a name for the git repo.
  REM echo %TAB%This will be the name of the git repo.
  REM echo %TAB%Should be lowercase or kebab-case.
  REM echo.
  REM set /p "repo_name_name=>>> "
  REM set "REPO_DEFINED=true"
REM )

REM if not defined DESCRIPTION_DEFINED (
  REM REM setlocal DisableDelayedExpansion
  REM echo.
  REM echo Enter a short project description
  REM echo %TAB%This will be displayed in the .toml and the README.
  REM echo %TAB%Max 1 sentence; what does this package do, why does it exist?
  REM echo %TAB%[Avoid exclamation points, percents, ampersands, and pipes.]
  REM echo.
  REM set /p "description=>>> "
  REM REM endlocal & set "description=%description%"
REM )

REM :: Debug print
REM call :debug "Name: '%author%'" "Email: '%email%'" "Parent Dir: '%parent_dirPath%'" "Templates Dir: '%CFG_templates_dirPath%'" "Package: '%package%'" "Repo: '%repo_name%'" "Description: '%description%'"

REM REM This is just a placeholder. Might update later. 
REM set "project_name=%package%"


:: ==========================================================
:: Parameter processing
:: ==========================================================

:ProcessParameters

set "config_dirPath=%CD%\config"

echo.
echo.
echo --- Starting placeholder and config processing ---
echo.

:: --- 1. Load General Configuration Defaults ---
REM THESE ARE IMMUTABLE AND SHOULD NOT BE CHANGED.
REM Note that we intentionally import these twice to avoid a situation in which a variable is loaded before it's required whatever-the-opposite-of-dependents-is. For example, if the file has VAR_B above VAR_A, but VAR_B depends on VAR_A (e.g. VAR_B=%VAR_A%), VAR_B won't be properly loaded (it will be empty in this case), but if we re-load the file, VAR_A will be defined when VAR_B is re-defined. 
call :debug 1 "Loading the config file next."
call "%config_dirPath%\pixi_pyprojSetup_config.cmd"
call "%config_dirPath%\pixi_pyprojSetup_config.cmd"
call :log "INFO" "Config file loaded."

REM Now we'll set the placeholders.

set PLACEHOLDER_COUNT=0

:: --- 2. Load Default Placeholder Values ---
call :LoadPlaceholders "%config_dirPath%\placeholders.DEFAULT"

:: --- 2.1 Assigning additional parameter defaults dynamically ---
for /f %%I in ('powershell -NoProfile -Command "(Get-Date).Year"') do set PH_year=%%I
call :AddPlaceholder "year" "%PH_year%"
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "PH_date=%%A"
call :AddPlaceholder "date" "%PH_date%"

call :log "INFO" "Default placeholders loaded."

:: --- 3. Override with User Placeholder Config ---
call :debug 1 "Reading from '%config_dirPath%\placeholders.USER'."
call :LoadPlaceholders "%config_dirPath%\placeholders.USER"
call :log "INFO" "User's placeholder file loaded."


:: --- 4. Process CLI Parameters (highest priority) ---
call :debug 1 "Parsing arguments..."
call :ParseArguments %*
call :log "INFO" "Arguments parsed successfully."

:: --- 5. Consolidate and Debug (Collect additional user input if missing) ---
call :debug 1 "Prompt for remaining required parameters..."
call :CollectMissingInputs
call :log "INFO" "Completed collecting missing inputs."

REM Export placeholders to environment variables for easier retrieval later.
call :ExportPlaceholders
call :debug 2 "Placeholders written to environment, including (but not limited to):" "Package = %PH_package%" "Author = %PH_author%" "Version = %PH_version%"


::=============================================================================
::=============================================================================

REM === Select a license ===
:SelectLicense

call :debug "license_spdx = %PH_license_spdx%"

if defined LICENSE_DEFINED (
  call :debug "License is defined, supposedly."
  if not exist "%CFG_license_dirPath%\license_%PH_license_spdx%.txt" (
    call :log "WARNING" "CLI-passed license SPDX code '%PH_license_spdx%' does not have a license file in the license templates directory, located at '%CFG_license_dirPath%'."
    choice M/ "Please select an existing license from the following list [Y], or quit the script and try again [N]."
    if errorlevel 2 (
        call :SafeExit "Don't forget to add a license called '%CFG_license_dirPath%\license_%PH_license_spdx%.txt'."
        exit /b 2
    )
    echo.
    set LICENSE_DEFINED=
  )
) else (call :debug "License has not been defined beyond the default.")


if defined LICENSE_DEFINED goto skipLicensePrompting

REM 1) Enumerate license templates
set count=0
for %%F in ("%CFG_license_dirPath%\license_*.txt") do (
  set /a count+=1
  rem strip off "license_" prefix
  set "fname=%%~nF"
  set "name=!fname:license_=!"
  set "license_!count!=!name!"
  echo !count!: !name!
)

REM REM -------------
REM REM 2) Prompt the user to pick one
REM echo See ^<https://choosealicense.com/licenses/^> for license summaries.
REM echo.
REM set /p "choice=Select a license by number: "
REM rem retrieve the chosen license name
REM for /f "delims=" %%L in ('echo !license_%choice%!') do set "license_spdx=%%L"
REM echo Selected license: %PH_license_spdx%


REM Ensure that at least one license template was found
if %count%==0 (
  call :log "WARNING" "No license templates found in '%CFG_license_dirPath%'."
  choice /N /M "Would you prefer to continue without a license [Y] or quit and add a license to the above directory [N] "
  if errorlevel 1 (
      call :SafeExit
      exit /b 1
  )
  call :log "INFO" 
  set "license_spdx=NO_LICENSE"
  set "LICENSE_DEFINED=true"
  goto skipLicensePrompting
  
)

echo.
echo See ^<https://choosealicense.com/licenses/^> for license summaries.
echo Note: The ^"NO_LICENSE^" option will not assign a license at all.
echo.


:promptLicense
REM -------------
REM 2) Prompt the user to pick one and validate the choice
REM I'll note here that I'm really unclear why this seems to work. It didn't for a while, and then it somehow started working. Like, I conceptually understand each line, but this sequence was not working, then I tried a bunch of alternatives, and then I went back to this and it worked. So maybe don't change anything in this block. 

REM Clear the variable before prompting
set "selection="

REM Prompt the user
set /p "selection=Select a license by number: "

REM Optional: trim leading/trailing whitespace
for /f "tokens=* delims= " %%A in ("!selection!") do set "selection=%%A"
REM set "selection=!selection: =!"

echo You entered: "[!selection!]"

REM Check that a value was actually input
if "!selection!"=="" (
    echo No input provided. Please enter a valid number.
    goto :promptLicense
)

REM Check whether the input is numeric.
REM echo pre-check error: %errorlevel%
ver >nul REM clears the errorlevel
REM echo the error should be cleared: %errorlevel%

REM Option 1 was to to an arithmetic assignment and testing the ERRORLEVEL
REM Attempting a numeric calculation on a non-number will set the errorlevel.
set /A dummy=!selection! >nul 2>&1

REM Alternative number check using a string-finding function
REM echo !selection! | findstr /R "^[0-9][0-9]*$" >nul 
REM echo post-check error: %errorlevel%

if errorlevel 1 (
    echo Invalid selection: "!selection!". Please enter a number.
    goto :promptLicense
)

REM Check if a license is defined for the given number.
if not defined license_!selection! (
    echo Invalid selection: "!selection!" is not among the listed options.
    goto :promptLicense
)

REM Retrieve the chosen license name.
REM for /f "delims=" %%L in ('echo !license_!selection!') do set "license_spdx=%%L"
call set "PH_license_spdx=!license_%selection%!"
REM for /f "delims=" %%L in ('cmd /V:ON /C "echo !license_!selection!!"') do set "license_spdx=%%L"
set "LICENSE_DEFINED=true"

:skipLicensePrompting
if "%PH_license_spdx%"=="NO_LICENSE" (
    call :log "INFO" License options declined, project will not be explicitly licensed.
) else (
    call :log "INFO" "Selected license: !PH_license_spdx!"
)

call :AddPlaceholder "license_spdx" "%PH_license_spdx%"


:CreateProjectDirectory

if not exist %PH_parent_dirPath% goto changeParent
call :log "INFO" "The project directory will be created at '%PH_parent_dirPath%\%PH_package%'.".
echo.
choice /M "Is this an acceptable location"
IF ERRORLEVEL 1 GOTO skipChangeParent

:changeParent
echo Enter the absolute path to the PARENT directory into which the project directory will be created.
set /p "new_parent=>>> "
if not exist "!new_parent!" (
    mkdir "!new_parent!"
    call :log "INFO" "A new directory has been created at '!new_parent!'."
)
set "parent_dirPath=!new_parent!"

:skipChangeParent
call :AddPlaceholder "parent_dirPath" "%PH_parent_dirPath%"
call :log "INFO" "Project will be created in '%PH_parent_dirPath%'"


:SettingsConfirmation
call :log "INFO" "Please confirm the following settings:"
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    set "k=!PLACEHOLDER_KEY_%%N!"
    set "v=!PLACEHOLDER_VALUE_%%N!"
    echo     !k! = !v!
)
echo.
choice /M "All good"
if errorlevel 2 (
  choice /N /M "Would you like to re-run the script [Y] or quit to adjust externally [N]"
  if errorlevel 2 (
      call :SafeExit
      exit /b 1
  )
  goto startOfScript
)

:InstantiatePixiDirectory
:: Create and enter project directory
call :debug 1 "Creating src-layout project directory."
set "PH_proj_root=%PH_parent_dirPath%\%PH_package%" 
pixi init %PH_proj_root% --format pyproject 
call :log "INFO" "Project directory created successfully at '%PH_proj_root%'."
cd %PH_proj_root%
call :debug "Current working directory set to '%PH_proj_root%'."
set TOML_FILE=%PH_proj_root%\pyproject.toml


:UpdateVersionFromToml
:: Get the initial version from the .toml file and set the variable.
for /f "tokens=2 delims== " %%A in ('findstr /r "^version *= *" %TOML_FILE%') do (
    set version=%%A
)
set PH_version=%version:"=%
call :AddPlaceholder "version" "%PH_version%"


:: Now that all the variables have been set, we'll write them out to a temporary file to use for string replacement.
:: The default placeholders that were loaded originally from 'placeholdes_default.env' will be written in, along with updated keys for those, along with any other keys that start with the 'license_spdx' prefix.

:GeneratePlaceholdersFile

call :debug "Generating placeholders.config project file..."

if not exist "%PH_proj_root%\config" mkdir "%PH_proj_root%\config"

set "placeholders=%PH_proj_root%\config\placeholders.config"

REM (
    REM for /f "tokens=* delims=" %%V in ('set license_spdx') do (
        REM echo %%V
    REM )
REM ) > "%placeholders%"

REM (
    REM for /f "tokens=* delims=" %%V in ('cmd /V:ON /C set license_spdx') do (
        REM echo %%V
    REM )
REM ) > "%placeholders%"


REM (
    REM for /f "tokens=1* delims==" %%A in ('set') do (
        REM echo %%A | findstr "^license_spdx" >nul && echo %%A=%%B
    REM )
REM ) > "%placeholders

REM (
    REM for /f "tokens=1* delims==" %%A in ('set') do (
        REM echo %%A | findstr "^license_spdx" >nul && (
            REM set "varname=%%A"
            REM set "value=%%B"
            REM set "stripped=!varname:license_spdx=!"
            REM echo !stripped!=!value!
        REM )
    REM )
REM ) > "%placeholders%"

(
    for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
        set "k=!PLACEHOLDER_KEY_%%N!"
        set "v=!PLACEHOLDER_VALUE_%%N!"
        echo !k!=!v!
    )
) > "%placeholders%"



:InitGit
:: Initialize Git ===
git init
echo.



:CopyLicense
:: ——————————————
:: 3) Copy the LICENSE file
if defined LICENSE_DEFINED (
  call :debug "Copying license '%PH_license_spdx%' into project."
  call :copy_fromTemplate "%CFG_license_dirPath%\license_%PH_license_spdx%.txt" "%PH_proj_root%\LICENSE.txt" "%PWSH_PATH%" "%CFG_script_prepend%" "" "%CFG_script_replacePlaceholders%" "%placeholders%" "%CFG_max_placeholder_depth%" %DEBUG_LEVEL%
) else (
  call :debug "No license defined, project will not be explicitly licensed."
)

:: --------------
:SetupBoilerplate

:: 4) Ensure a boilerplate exists in _templates
set "boilerplate_name=%CFG_boilerplate_name:{license_spdx}=!PH_license_spdx!%"
set "boilerplate_txt_template=%CFG_boilerplatesDir%\%boilerplate_name%.txt.%CFG_templateExt%"
call :debug "In boilerplate setting section" "boilerplate.txt template = '%boilerplate_txt_template%'"

if not exist "%CFG_boilerplatesDir%" (
  echo '%CFG_boilerplatesDir%' does not exist. Creating.
  mkdir "%CFG_boilerplatesDir%"
) else (call :debug "boilerplatesDir exists.")


if not exist "%boilerplate_txt_template%" (
  call :debug "boilerplate DOES NOT exist. Creating..."
  if not defined LICENSE_DEFINED (
    echo -- [ERROR] --
    echo No license was defined!
    choice /N /M "Enter [y] to continue with an empty boilerplate, or [n] to quit the script and possibly create your own boilerplate with the right naming convention."
    IF ERRORLEVEL 2 exit /b
    echo. > "%boilerplate_txt_template%"
  ) else (
    echo This file within package ^<%PH_package%^> is copyrighted by %PH_author% ^<%PH_email%^> as of %PH_year% under the %PH_license_spdx% license. > "%boilerplate_txt_template%"
  )
  call :debug "Created boilerplate. Copying..."
) else (
  call :debug "Boilerplate template exists. Copying..."
)

call :copy_fromTemplate "%boilerplate_txt_template%" "%PH_proj_root%\config\%boilerplate_name%.txt" "%PWSH_PATH%" "%CFG_script_prepend%" "" "%CFG_script_replacePlaceholders%" "%placeholders%" "%CFG_max_placeholder_depth%" %DEBUG_LEVEL%

call :debug "Boilerplate file copied."

REM pause


::=============================================================================
::=============================================================================

:: This method loops over the files in the first parameter, appends the correctly commented boilerplate text from the third parameter, replaces the string placeholders as appropriate, and then saves the resulting file into the second parameter.

REM call :debug "At the first 'copy_templates'. Parameters:" "templatesDir = %CFG_templates_dirPath%" "proj_root = %PH_proj_root%" "boilerplate = %boilerplate%" "placeholder_script = %placeholder_script%" "placeholders = %placeholders%"
REM REM pause
REM call :copy_templates "%CFG_templates_dirPath%" "%PH_proj_root%" "%boilerplate%" "%placeholder_script%" "%placeholders%"

REM call :debug "At the src-directory 'copy_templates'. Parameters:" "templatesDir = %CFG_templates_dirPath%\src" "proj_root\src\package = %PH_proj_root%\src\%PH_package%" "boilerplate = %boilerplate%" "placeholder_script = %placeholder_script%" "placeholders = %placeholders%"
REM REM pause
REM call :copy_templates "%CFG_templates_dirPath%\src" "%PH_proj_root%\src\%PH_package%" "%boilerplate%" "%placeholder_script%" "%placeholders%"

:TemplateProcessingLoop

echo.
echo --------------------------------------------------------------------------
echo --------------------------------------------------------------------------
echo.
echo        BEGIN PROCESSING FILES
echo.
echo --------------------------------------------------------------------------
echo --------------------------------------------------------------------------
echo.


REM Recursively loop through all files under the parent directory.
for /R "%CFG_templates_dirPath%" %%F in (*) do (

    set "filepath=%%F"
    set "skipFile="
    set "noBP="
    
    set "relPath=!filepath:%CFG_templates_dirPath%\=!"
    call :debug "Processing 'TEMPLATES\!relPath!'..."

    REM Check each excluded folder.
    for %%D in (%CFG_excludeFolders%) do (
        REM %%~D removes any surrounding quotes.
        REM This call uses string substitution to remove "\FolderName\" from the file path.
        call set "test=%%filepath:\%%~D\=%%%"
        if not "!test!"=="!filepath!" (
           set "skipFile=yes"
        )
    )

    if defined skipFile (
        call :debug "-- Skipping file because it is in one of the excluded folders."
    ) else (
    
        REM First we do some fancy stripping to get the relative path
        REM set "relPath=!filepath:%CFG_templates_dirPath%\=!"
        REM call :debug "Relative path: '!relPath!'"
        
        REM If the path begins with 'src\', we rebuild the 'relPath' to include the package name so it copies into '<package>\src\<package>'.
        if /I "!relPath:~0,4!"=="src\" (
            REM If yes, remove "src\" from the beginning,
            REM then rebuild the relative path with "src\<package>\" inserted.
            set "rest=!relPath:~4!"
            set "newRelPath=src\%PH_package%\!rest!"
        ) else (
            REM Otherwise, keep the relative path unchanged.
            set "newRelPath=!relPath!"
        )
        
        REM Now we can build the full path to the destination.
        set "destFile=%PH_proj_root%\!newRelPath!"
        REM set "destFile=!destFile:.TEMPLATE=!" & REM this does the stripping
        set "destFile=!destFile:.%CFG_templateExt%=!" & REM this does the stripping
        set "relDest=!destFile:%PH_proj_root%\=!"
        call :debug "Destination filepath: '!destFile!'"
        
        REM Create the destination directory tree if needed.
        REM (Use for /F to extract the directory, then mkdir)
        for %%D in ("!destFile!") do (
            mkdir "%%~dpD" 2>nul
        )
        
        REM Next, we determine if the current file is on the 'No Boilerplate' list. If so, we'll just pass an empty string for the boilerplate.
        REM Loop through each non-comment ignore line from noBoilerplateFiles.config.
        for /F "usebackq eol=# delims=" %%I in ("%config_dirPath%\noBoilerplateFiles.config") do (
            if not defined noBP (
                set "FilenameWithExt=%%~nxF"
                REM set "FilenameWithoutTemplateExt=!FilenameWithExt:.TEMPLATE=!"
                set "FilenameWithoutTemplateExt=!FilenameWithExt:.%CFG_templateExt%=!"
                call :debug "NoBP: does ignore-file '%%I' match current file '!FilenameWithoutTemplateExt!'?"
                REM Compare file names (case-insensitive).
                if /I "%%I"=="!FilenameWithoutTemplateExt!" (
                    call :debug "File is on the 'No Boilerplates' list, so no boilerplate will be appended.
                    set "noBP=true"
                )
            )
        )
        
        REM If the file was NOT on the 'No Boilerplate' list, we need to determine the correct boilerplate file to use.
        if not defined noBP (

            call :debug "Boilerplate identification..." "Boilerplate_name: %boilerplate_name%" "BoilerplatesDir: %CFG_boilerplatesDir%" "boilerplate_txt_template: %boilerplate_txt_template%"

            REM 3.1: Identify the target file's filetype via its extension.
            REM set "strippedName=!filepath:.TEMPLATE=!"
            set "strippedName=!filepath:.%CFG_templateExt%=!"
            call :debug "Stripped name: '!strippedName!'"
            for %%A in ("!strippedName!") do set "ext=%%~xA"
            call :debug "Extracted extension: '!ext!'"
            
            REM 3.2 Check the boilerplates directory for an appropriately commented boilerplate file.
            if exist %CFG_boilerplatesDir%\%boilerplate_name%!ext!.%CFG_templateExt% (
              set "boilerplate=%CFG_boilerplatesDir%\%boilerplate_name%!ext!.%CFG_templateExt%"
              call :debug "Boilerplate for '!ext!' exists."
            ) else (
                REM 3.3 Since the correctly-commented boilerplate file doesn't exist (at least, within the boilerplates directory), we'll have to make it.
                call :debug "Boilerplate file for '!ext!' does not exist. Creating." "Should be '%CFG_boilerplatesDir%\%boilerplate_name%!ext!.%CFG_templateExt%'"
                
                REM 3.3.1 Define the path for the new boilerplate file
                set "boilerplate=%CFG_boilerplatesDir%\%boilerplate_name%!ext!.%CFG_templateExt%
                
                REM 3.3.2 Append the appropriate comment character(s) by using the '.txt' boilerplate template (which was created earlier so it exists).
                "%PWSH_PATH%" -NoProfile -File "%CFG_script_BPcommenting%" -Boilerplate "%boilerplate_txt_template%" -Extension "!ext!" -OutputFile "!boilerplate!" -Debug_Level %DEBUG_LEVEL%
                
                call :debug "Boilerplate file: '!boilerplate!'"
                echo.
                choice /M "Would you like to save this new boilerplate file for future use?"
                if errorlevel 2 set "DEL_BP=true"
            )
            
        ) else (
            REM If 'noBP' was defined, it means we're not passing a BP file.
            set boilerplate=
        
        )
        
        REM 4. Then process the template
        echo Processing 'TEMPLATES\!relPath!' into '%PH_package%\!relDest!'
        call :copy_fromTemplate "!filepath!" "!destFile!" "%PWSH_PATH%" "%CFG_script_prepend%" "!boilerplate!" "%CFG_script_replacePlaceholders%" "%placeholders%" "%CFG_max_placeholder_depth%" %DEBUG_LEVEL%
        
        if defined DEL_BP (
          del "!boilerplate!"
          set "DEL_BP="
        )
        
        echo.
        echo --- Successfully processed
        echo.
        echo Press enter to move to the next file.
        echo.
        REM pause
        echo.
        echo ----------------------------------------------
        echo.
    )
)
pause




REM REM Here's the explicit code without a function.
REM REM Copy the template.
REM copy "%SOURCE%" "%DEST%" >nul
REM REM Prepend the boilerplate file text to the copied file.
REM %PWSH_PATH% -Command ^
  REM "$boilerplate = Get-Content '%BOILERPLATE%' -Raw;" ^
  REM "$target = Get-Content '%TARGET%' -Raw;" ^
  REM "$combined = $boilerplate + \"`n`n\" + $target;" ^
  REM "Set-Content '%TARGET%' $combined"
REM REM Call the placeholder replacement script on the copied file.
REM %PWSH_PATH% -NoProfile -File "%REPLACEMENT_SCRIPT%" -InputFile "%DEST%" -OutputFile "%DEST%" -EnvFile "%PLACEHOLDERS%"

::=============================================================================
::=============================================================================

REM === Create README.md from template ===
REM set file=README.md
REM call :copy_fromTemplate "%CFG_templates_dirPath%\%file%.TEMPLATE" "%file%"

::=================================================================================================
::=================================================================================================

REM === Create CHANGELOG.md from template ===
REM set file=CHANGELOG.md
REM call :copy_fromTemplate "%CFG_templates_dirPath%\%file%.TEMPLATE" "%file%"

::=================================================================================================
::=================================================================================================

REM === Create __init__.py from template ===
REM set file=__init__.py
REM call :copy_fromTemplate "%CFG_templates_dirPath%\%file%.TEMPLATE" "%srcDir%\%file%" %boilerplate%
REM (
  REM echo.
  REM echo __version__ = "%version%"
  REM echo __author__ = "%PH_author%"
REM ) >> "%srcDir%\__init__.py" 


::=================================================================================================
::=================================================================================================

REM === Create cli.py from template ===
REM set file=cli.py
REM call :copy_fromTemplate "%CFG_templates_dirPath%\%file%.TEMPLATE" "%srcDir%\%file%" "%boilerplate%"


::=================================================================================================
::=================================================================================================

REM === Create __main__.py from template ===
REM set file=__main__.py
REM call :copy_fromTemplate "%CFG_templates_dirPath%\%file%.TEMPLATE" "%srcDir%\%file%" "%boilerplate%"

::=================================================================================================
::=================================================================================================

REM === Create main.py from template ===
REM set file=main.py
REM call :copy_fromTemplate "%CFG_templates_dirPath%\%file%.TEMPLATE" "%file%" "%boilerplate%"

::=================================================================================================
::=================================================================================================

REM === Create the batch script to run the package ===
REM call :copy_fromTemplate "%CFG_templates_dirPath%\runPythonScript.bat.TEMPLATE" "run_%PH_package%.bat" "" ":: Copyright (C) %year% by %PH_author% <%email%> under %PH_license_spdx% (see LICENSE.txt for details)"

:RenameRunFile
REM === Rename the copied batch script file ===
rename "runPythonScript.bat" "run_%PH_package%.bat"
call :debug "Run.bat renamed to 'run_%PH_package%.bat'"

:: The following code is basically the prepend_boilerplate_string method put into the code. 
REM set "boilerplate=:: Copyright (C) {year}  {author} <{email}> under GNU GPL v3.0 (see LICENSE.txt for details)"
REM set "boilerplateFile=%temp%\boilerplate_%random%.txt"
REM powershell -Command "Set-Content -Path '!boilerplateFile!' -Value '!boilerplate!'"
REM call :copy_fromTemplate "%CFG_templates_dirPath%\runPythonScript.bat.TEMPLATE" "run_%PH_package%.bat" "!boilerplateFile!"


::=============================================================================
::=============================================================================

:ModifyTomlFile
REM === Insert readme and license into pyproject.toml ===

REM %PWSH_PATH% -NoProfile -File %toml_insert% -ConfigFile "%config_dirPath%\toml_insert.config" -Debug

"%PWSH_PATH%" -NoProfile -File "%CFG_script_toml_insert%" -ConfigFile "%config_dirPath%\toml_insert.config" -Debug_Level %DEBUG_LEVEL%

"%PWSH_PATH%" -NoProfile -File "%CFG_script_toml_replace%" -ConfigFile "%config_dirPath%\toml_replace.config" -Debug_Level %DEBUG_LEVEL%

"%PWSH_PATH%" -NoProfile -File "%CFG_script_replacePlaceholders%" -InputFile "%TOML_FILE%" -OutputFile "%TOML_FILE%" -EnvFile "%placeholders%" -Debug_Level %DEBUG_LEVEL%

::powershell -NoProfile -File "%REPLACEMENT_SCRIPT%" -InputFile "%DEST%" -OutputFile "%DEST%" -EnvFile "%PLACEHOLDERS%"


:: ADD CALL TO PS SCRIPT HERE

REM powershell -NoProfile -File replace.ps1 -File "my_project.toml" `
  REM -Replacements '{"description":"Updated description for the package","license":"MIT"}'


REM powershell -NoProfile -File insert.ps1 -File "my_project.toml" `
  REM -Insertions '{"readme":"README.md","license-files":"[\"LICENSE.txt\"]"}' `
  REM -Anchor "version ="


  

REM === Check if the [tool.setuptools] section exists, and append if not ===
findstr /C:"[tool.setuptools]" "%TOML_FILE%" >nul
if errorlevel 1 (
    REM No extra blank line needed; one exists at the end of the file already.
    echo [tool.setuptools]>> "%TOML_FILE%"
    echo package-dir = {"" = "src"}>> "%TOML_FILE%"
) else (
    echo [tool.setuptools] section already exists.
)


::=================================================================================================
::=================================================================================================  

:: Make the first commit
git add .
git commit -m "Initial project setup"
git tag -a v%PH_version% -m "v%PH_version%: Initial release"

REM === Push to the repo ===
echo.
choice /M "Would you like to push to GitHub?"
REM call :debug 1 "ERRORLEVEL is %errorlevel%"
IF ERRORLEVEL 2 GOTO skipGitHub

call :log "INFO" "Pushing to github"
gh repo create %PH_repo_name% --private --source=. --remote=origin
git branch -M main
git push -u origin main
git push origin v%PH_version%

:skipGitHub


echo.
call :log "INFO" "Project setup COMPLETE"
echo.
echo ^>^>^> Now you can start coding in ^<%PH_package%^>.
echo.
echo ^>^>^> Don't forget to add packages with ^'pixi add ^<package^>^'.
echo.
echo ^>^>^> You can run the package's 'main.py' by running ^'%PH_package%_run.bat^' from wherever is convenient.
echo.
echo ^>^>^> Alternative, run ^'pixi run python -m %PH_package%^' from within the project root ^(this may require some edits to function properly^).
echo.

pause

:: Cleanup
REM del %placeholders%

goto :eof



::=================================================================================================
::=================================================================================================  


REM === STRING REPLACEMENT METHOD
:replace_placeholders
:: %1 = file path to modify
:: %2 = An optional location for debugging.

call :debug "In 'replace_placeholders'" "File: '%~1'"

if "%~1"=="" (
    echo [ERROR][replace_placeholders] Missing file path. Called from: %~2
    goto :eof
)

:: BE SUPER CAREFUL ADJUSTING THIS!! Each line is very exact; don't forget the semicolons!
powershell -Command ^
  "$file = Get-Content '%~1' -Raw;" ^
  "$replacements = @{" ^
    "'{package}' = '%package%';" ^
    "'{author}' = '%author%';" ^
    "'{email}' = '%email%';" ^
    "'{year}' = '%year%';" ^
    "'{date}' = '%date%';" ^
    "'{license}' = '%license%';" ^
    "'{license-name}' = '%license_spdx%';" ^
    "'{description}' = '%description%';" ^
    "'{project_name}' = '%project_name%';" ^
    "'{projRoot_dir}' = '%proj_root%';" ^
    "'{absPath}' = '%proj_root%';" ^
    "'{repo_name}' = '%repo_name%';" ^
    "'{version}' = '%version%'" ^
  "};" ^
  "foreach ($key in $replacements.Keys) { $file = $file -replace $key, $replacements[$key] };" ^
  "Set-Content '%~1' $file"
  
call :debug "String replacement complete"

goto :eof


::=================================================================================================
::================================================================================================= 

:prepend_boilerplate
:: %1 = boilerplate file OR string
:: %2 = target file to insert into

setlocal

set "TAB=   "

set "BOILERPLATE=%~1"
set "TARGET=%~2"

call :debug "In 'prepend_boilerplate'" "Boilerplate: '%BOILERPLATE%'" "Target: '%TARGET%'"

REM echo "%~1"
:: None of the following worked to Successfully use the conditional. Sad.
REM powershell -Command ^
  REM "$path = '%~1';" ^ 
  REM "echo $path; if ((Test-Path -LiteralPath $path) -and !(Get-Item -LiteralPath $path).PSIsContainer) { exit 0 } else { exit 1 }"
REM powershell -Command ^
  REM "try { $path = '%~1'; if ((Test-Path -LiteralPath $path) -and !(Get-Item -LiteralPath $path).PSIsContainer) { exit 0 } else { exit 1 } } catch { exit 1 }"
REM powershell -Command ^
  REM "$path = \""%~1\"";" ^
  REM "if ((Test-Path -Path $path) -and !(Get-Item $path).PSIsContainer) { exit 0 } else { exit 1 }"
REM powershell -Command "if (Test-Path '%~1') { exit 0 } else { exit 1 }"
if exist "%BOILERPLATE%" (
REM if %errorlevel%==0 (
  REM echo in the file block
  echo %TAB%Prepending file ^<%BOILERPLATE%^> into ^<%TARGET%^>.
  call :prepend_boilerplate_file "%BOILERPLATE%" "%TARGET%"
) else (
  REM echo in the string block
  echo %TAB%Prepending string ^<"%BOILERPLATE%"^> into ^<%TARGET%^>.
  call :prepend_boilerplate_string "%BOILERPLATE%" "%TARGET%"
)
endlocal
goto :eof

::=================================================================================================
::=================================================================================================  


REM === PREPEND BOILERPLATE FILE
:prepend_boilerplate_file
:: %1 = boilerplate file
:: %2 = target file

REM powershell -Command ^
  REM "$boilerplate = Get-Content '%~1';" ^
  REM "$target = Get-Content '%~2';" ^
  REM "$combined = $boilerplate + '', $target;" ^
  REM "$combined | Set-Content '%~2'"
  
setlocal
set "BOILERPLATE=%~1"
set "TARGET=%~2"

call :debug "In 'prepend_boilerplate_file'" "Boilerplate: '%BOILERPLATE%'" "Target: '%TARGET%'"
  
%PWSH_PATH% -Command ^
  "$boilerplate = Get-Content '%BOILERPLATE%' -Raw;" ^
  "$target = Get-Content '%TARGET%' -Raw;" ^
  "$combined = $boilerplate + \"`n`n\" + $target;" ^
  "Set-Content '%TARGET%' $combined"
  
endlocal
goto :eof

::=================================================================================================
::=================================================================================================  


:prepend_boilerplate_string
:: This just puts the string into a temporary file, calls 'prepend_boilerplate_file', and then deletes the file. Kinda janky.
:: %~1 = Text to prepend
:: %~2 = File to insert into

:: Create temp file with string.
set "boilerplateFile=%temp%\boilerplate_%random%.txt"

:: Write the string to the temp file using PowerShell (ensures no encoding issues or weird escapes)
powershell -Command "Set-Content -Path '!boilerplateFile!' -Value '%~1'"

:: I avoided the following because it would require careful escaping of characters. The powershell method above is more reliable.
:: Write the string to the temp file
REM (
    REM echo %~1
REM ) > "!boilerplateFile!"n

call :prepend_boilerplate_file "!boilerplateFile!" "%~2"

:: Clean up temp file
del "!boilerplateFile!" >nul 2>&1

echo %TAB%Prepending string ^<"%~1"^> into ^<%~2^>.
    
goto :eof
    
    
::=================================================================================================
::=================================================================================================  


:: Function to copy a file and print a formatted message
:copy_withMsg
:: %1 = source file
:: %2 = destination file

set "SOURCE=%~1"
set "DEST=%~2"
set "TAB=   "

call :debug "In 'copy_withMsg'" "Source: '%SOURCE%'" "Destination: '%DEST%'"

copy "%SOURCE%" "%DEST%" >nul
if %errorlevel%==0 (
    echo %TAB%Successfully copied ^<%SOURCE%^> to ^<%DEST%^>.
) else (
    echo %TAB%FAILED TO COPY ^<%SOURCE%^> to ^<%DEST%^>
)
goto :eof


::=============================================================================
::============================================================================= 

:: Function for copying and filling from template
:copy_fromTemplate
:: %1 = source file (i.e. the template)
:: %2 = destination file (the full path plus new filename)
:: %3 = The path to the PowerShell instance you'll use (e.g. PS5.1, PS7, etc.)
:: %4 = Path to the PS script for prepending boilerplate text.
:: %5 = Path to boilerplate text file. 
::      NOTE: This must be a single file. Put the file together outside this method.
:: %6 = Path to the PS script for placeholder replacement.
:: %7 = Path to the file that details the placeholders and their replacements.
:: %8 = Path to the script for commenting the boilerplate
:: %9 = Debugging level (0-4)

setlocal 

set "SOURCE=%~1"
set "SOURCE_FILENAME=%~nx1"
set "DEST=%~2"
set "PWSH=%~3"
set "PREPEND_SCRIPT=%~4"
set "BOILERPLATE=%~5"
set "BOILERPLATE_NAME=%~n5"
set "REPLACEMENT_SCRIPT=%~6"
set "PLACEHOLDERS=%~7"
set "MAX_PLACEHOLDER_DEPTH=%~8"
set "_DEBUG_LEVEL=%~9"
REM set "COMMENT_BP_SCRIPT=%~8"

REM First, a debug-printing step.
call :debug "------------------------------------------------------------------" " " "In 'copy_fromTemplate'" "Source: '%SOURCE%'" "Destination: '%DEST%'" "Prepend script path: '%PREPEND_SCRIPT%'" "Boilerplate filepath: '%BOILERPLATE%'" "Replacement script path: '%REPLACEMENT_SCRIPT%'" "Placeholders filepath: '%PLACEHOLDERS%'" "Max placeholder depth: '%MAX_PLACEHOLDER_DEPTH%'" "Debug level: '%_DEBUG_LEVEL%'"


REM Second, we copy the source file (the template) into the new destination.
call :debug "Copying..."
call :copy_withMsg "%SOURCE%" "%DEST%"


REM REM Third, we need to prepend the boilerplate. This happens in a number of steps.
REM call :debug "Boilerplate identification..."

REM REM 3.1: Identify the target file's filetype via its extension.
REM set "strippedName=%SOURCE_FILENAME:.TEMPLATE%"
REM call :debug "Stripped name: '%strippedName%'"
REM for %%A in ("%strippedName%") do set "ext=%%~xA"
REM call :debug "Extracted extension: '%ext%'"


REM REM 3.2: Is the passed boilerplate file appropriate for the copied file? If so, go directly to prepending.
REM set "strippedName=%BOILERPLATE:.TEMPLATE%"
REM call :debug "Stripped boilerplate name: '%strippedName%'"
REM for %%A in ("%strippedName%") do set "BPext=%%~xA"
REM call :debug "Extracted boilerplate extension: '%BPext%'"
REM if "%BPext%"=="%ext%" (
  REM call :debug "Boilerplate was passed with the correct extension: '%ext%' vs '%BPext%'"
  REM goto prepending
REM )

REM REM If the extensions do not match (i.e. the passed boilerplate was inappropriate for the passed file), we need to check the boilerplate's directory for a correctly-named file with the correct file extension. 
REM REM To search the boilerplate directory for a correctly-named file, we pull out the directory in which the boilerplate file lives, which we assume is where other boilerplates live (or will live). 
REM REM The conditional strips the trailing '\' that's left by the %%~dpF command by using a batch trick for substitution: 
REM REM         set "variable=%otherVar:substringToReplace=replacement%"
REM for %%F in ("%BOILERPLATE%") do set "boilerplatesDir=%%~dpF"
REM if "%boilerplatesDir:~-1%"=="\" set "boilerplatesDir=%boilerplatesDir:~0,-1%"
REM call :debug "boilerplatesDir = '%boilerplatesDir%'." 

REM call :debug "The '%ext%'-specific boilerplate file should be '%BOILERPLATE_NAME%%ext%' in '%boilerplatesDir%'."

REM REM If that exists, set it and move to prepending.
REM if exist "%boilerplatesDir%\%BOILERPLATE_NAME%%ext%" (
  REM set "BOILERPLATE=%boilerplatesDir%\%BOILERPLATE_NAME%%ext%"
  REM call :debug "The appropriate boilerplate file exists in the boilerplate directory: '%BOILERPLATE%'"
  REM goto prepending
REM )

REM REM If the correct boilerplate does NOT exist, call the 'comment_boilerplate' method to append the correct comment character to each line. 
REM REM Note that the %ext% variable already has a dot as its first character, e.g. '.txt' not just 'txt'. 
REM call :debug "Boilerplate file '%boilerplatesDir%\%BOILERPLATE_NAME%%ext%' does not exist. Creating."
REM REM call :comment_boilerplate "%BOILERPLATE%" "%ext%" "%boilerplatesDir%" 
REM if defined $Debug (
  REM %PWSH% -NoProfile -File "%COMMENT_BP_SCRIPT%" -Boilerplate "%BOILERPLATE%" -Extension "%ext%" -OutputDir "%boilerplatesDir%" -Debug
REM ) else (
  REM %PWSH% -NoProfile -File "%COMMENT_BP_SCRIPT%" -Boilerplate "%BOILERPLATE%" -Extension "%ext%" -OutputDir "%boilerplatesDir%"
REM )


REM :prepending
call :debug "Prepending..."
if "%BOILERPLATE%"=="" (
  call :debug "Nothing to prepend - continuing"
) else (
    "%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%PREPEND_SCRIPT%" "%DEST%" "%BOILERPLATE%" -DEBUG_LEVEL "%_DEBUG_LEVEL%"
)


REM Finally, we call the placeholder-replacement script to replace all the placeholders.
call :debug "Running replacement script..."
"%PWSH%" -NoProfile -File "%REPLACEMENT_SCRIPT%" -InputFile "%DEST%" -OutputFile "%DEST%" -EnvFile "%PLACEHOLDERS%" -MaxIterations "%CFG_max_placeholder_depth%" -DEBUG_LEVEL "%_DEBUG_LEVEL%"


endlocal
goto :eof



REM ============ OLD VERSION OF copy_fromTemplate BELOW
REM :: Function for copying and filling from template
REM :copy_fromTemplate
REM :: %1 = source file
REM :: %2 = destination file
REM :: %3 = boilerplate file (may be empty)
REM :: %4 = boilerplate string (may be empty)
REM :: %5 = string first? (true/false, defaults to false)
REM :: By default, if a file and string are passed, the file is prepended first UNLESS %5 is set to "true".
REM :: %6 = Path to the PS script for placeholder replacement.
REM :: %7 = Path to the file that details the placeholders and their replacements.

REM setlocal

REM set "SOURCE=%~1"
REM set "DEST=%~2"
REM set "BOILERPLATE_FILE=%~3"
REM set "BOILERPLATE_STR=%~4"
REM set "STR_FIRST_FLAG=%~5"
REM set "REPLACEMENT_SCRIPT=%~6"
REM set "PLACEHOLDERS=%~7"

REM call :debug "In 'copy_fromTemplate'" "Source: '%SOURCE%'" "Destination: '%DEST%'" "Boilerplate file: '%BOILERPLATE_FILE%'" "Boilerplate string: '%BOILERPLATE_STR%'" "String-first flag: '%STR_FIRST_FLAG%'" "Replacement script path: '%REPLACEMENT_SCRIPT%'" "Placeholders path: '%PLACEHOLDERS%'"

REM call :copy_withMsg "%SOURCE%" "%DEST%"

REM :: If the string should be prepended first, else do the first first.
REM if "%STR_FIRST_FLAG%"=="true" (
  REM REM echo 5 was true
  REM call :debug "'STR_FIRST_FLAG' was set to 'true'."
  REM :: If the string passed is non-empty, write it.
  REM if not "%BOILERPLATE_STR%"=="" (
    REM REM echo and 4 was nonempty
    REM call :debug "'BOILERPLATE_STR' was non-empty."
    REM call :prepend_boilerplate_string "%BOILERPLATE_STR%" "%DEST%"
  REM ) else (call :debug "'BOILERPLATE_STR' was empty.")
  REM :: If the file pass is non-empty, write it.
  REM if not "%BOILERPLATE_FILE%"=="" (
    REM REM echo and 3 was nonempty
    REM call :debug "'BOILERPLATE_FILE' was non-empty."
    REM call :prepend_boilerplate "%BOILERPLATE_FILE%" "%DEST%"
  REM ) else (call :debug "'BOILERPLATE_FILE' was empty.")
REM ) else (
  REM REM echo 5 was NOT true
  REM call :debug "'STR_FIRST_FLAG' was NOT set to 'true'."
  REM :: If the file pass is non-empty, write it.
  REM if not "%BOILERPLATE_FILE%"=="" (
    REM REM echo and 3 was nonempty
    REM call :debug "'BOILERPLATE_FILE' was non-empty."
    REM call :prepend_boilerplate "%BOILERPLATE_FILE%" "%DEST%"
  REM ) else (call :debug "'BOILERPLATE_FILE' was empty.")
  REM :: If the string passed is non-empty, write it.
  REM if not "%BOILERPLATE_STR%"=="" (
    REM REM echo and 4 was nonempty
    REM call :debug "'BOILERPLATE_STR' was non-empty."
    REM call :prepend_boilerplate_string "%BOILERPLATE_STR%" "%DEST%"
  REM ) else (call :debug "'BOILERPLATE_STR' was empty.")
REM )

REM :: This conditional tried to pass complicated strings to prepend_boilerplate, where a conditional would test if the string existed as a path. This conditional broke with special characters and I couldn't get it working, which leads to the obnoxious conditional tree above. But now it works.
REM REM if "%BOILERPLATE_FILE%"=="" (
  REM REM call :prepend_boilerplate "%BOILERPLATE_FILE%" "%DEST%"
REM REM )

REM REM call :debug "Moving into 'replace_placeholders'"
REM REM call :replace_placeholders "%DEST%" "%DEST%"
REM call :debug "Running replacement script"
REM REM pause
REM %PWSH_PATH% -NoProfile -File "%REPLACEMENT_SCRIPT%" -InputFile "%DEST%" -OutputFile "%DEST%" -EnvFile "%PLACEHOLDERS%"

REM endlocal
REM goto :eof




::=============================================================================
::=============================================================================

:copy_templates
:: %1: The source DIRECTORY to loop over and copy from.
:: %2: The destination directory to copy into.
:: %3: The path to the PowerShell executable you're using.
:: %4: The filepath to the prepending script
:: %5: The original un-commented boilerplate file (to be prepended). NOTE! This must be a single file. Concatenate whatever text you'd like into a single file before passing it.
:: %6: Path to the PS script for placeholder replacement.
:: %7: Path to the file that details the placeholders and their replacements.


setlocal

set "SOURCE=%~1"
set "DEST=%~2"
set "PWSH=%~3"
set "PREPEND_SCRIPT=%~4"
set "BOILERPLATE=%~5"
set "BOILERPLATE_NAME=%~n5"
set "REPLACEMENT_SCRIPT=%~"
set "PLACEHOLDERS=%~7"
set "MAX_PLACEHOLDER_DEPTH=%~8"
set "_DEBUG_LEVEL=%~9"

REM First, a debugging statement.
call :debug "------------------------------------------------------------------" " " "In 'copy_templates'" "Source: '%SOURCE%'" "Destination: '%DEST%'" "Prepend script path: '%PREPEND_SCRIPT%'" "Boilerplate: '%BOILERPLATE%'" "Boilerplate name: '%BOILERPLATE_NAME%'" "Replacement script path: '%REPLACEMENT_SCRIPT%'" "Placeholders path: '%PLACEHOLDERS%'" "Max placeholder depth: '%MAX_PLACEHOLDER_DEPTH%'" "Debug level: %_DEBUG_LEVEL%"


REM Second, we pull out the directory in which the boilerplate file lives. 
REM We do this to identify where to put any new commented boilerplate files we generate here.
REM The conditional strips the trailing '\' that's left by the %%~dpF command by using a batch trick for substitution: set "variable=%otherVar:substringToReplace=replacement%"
for %%F in ("%BOILERPLATE%") do set "boilerplatesDir=%%~dpF"
if "%boilerplatesDir:~-1%"=="\" set "boilerplatesDir=%boilerplatesDir:~0,-1%"
call :debug "boilerplatesDir = '%CFG_boilerplatesDir%'." 


REM Step 2 part 2 makes sure that the boilerplate file is correctly named and located. 
REM I'm not sure, looking at this later, how this might happen, but I'm guessing it must have at some point and caused an issue.
if /I "%BOILERPLATE%" neq "%CFG_boilerplatesDir%\%BOILERPLATE_NAME%.txt" (
  move "%BOILERPLATE%" "%CFG_boilerplatesDir%\%BOILERPLATE_NAME%.txt">nul
  call :debug "Boilerplate file moved to '%CFG_boilerplatesDir%\%BOILERPLATE_NAME%.txt'."
)


REM Third, we loop over the template files within the source directory 
call :debug "Starting loop..."
for %%F in ("%SOURCE%\*.%CFG_templateExt%") do (

  set "filename=%%~nxF"
  call :debug "Looking at file '%%~nxF'"
  REM set "strippedName=!filename:.TEMPLATE=!"
  set "strippedName=!filename:.%CFG_templateExt%=!"
  call :debug "Stripped name: '!strippedName!'"
  for %%A in ("!strippedName!") do set "ext=%%~xA"
  call :debug "Extracted extension: '!ext!'"


  :: Make the file-type-specific boilerplate file, if it doesn't exist.
  :: Also note that 'ext' has a dot in front of it already.
  call :debug "The '!ext!'-specific boilerplate file should be '!BOILERPLATE_NAME!!ext!' in '!boilerplatesDir!'."
  
  if not exist "%CFG_boilerplatesDir%\%BOILERPLATE_NAME%!ext!" (
  
    call :debug "Boilerplate file '%CFG_boilerplatesDir%\%BOILERPLATE_NAME%!ext!' does not exist. Creating."
  
    call :comment_boilerplate "%BOILERPLATE%" "!ext!" "%CFG_boilerplatesDir%"
    REM :: Note that commented boilerplate files are named <license_SPDX>_boilerplate.<ext>, where the <license_SPDX> is the SPDX string for the relevant copyright license, and <ext> is the file extension (i.e. which commenting character is appended to the license-specific boilerplate text). 
  ) else (call :debug "Boilerplate file '%CFG_boilerplatesDir%\%BOILERPLATE_NAME%!ext!' exists.")
 
  REM :: The -n flag, e.g. ~nF, removes the extension, which here will be '.%CFG_templateExt%' since that's what we're copying in the 'for' loop. 
  call :copy_fromTemplate "%%F" "%DEST%\%%~nF" "%PWSH%" "%PREPEND_SCRIPT%" "%CFG_boilerplatesDir%\%BOILERPLATE_NAME%!ext!" "%REPLACEMENT_SCRIPT%" "%PLACEHOLDERS%" %MAX_PLACEHOLDER_DEPTH% %_DEBUG_LEVEL%
    
)


call :debug "Loop complete"

endlocal
exit /b


::=================================================================================================
::=================================================================================================  


:comment_boilerplate
:: Comments the boilerplate with the appropriate character.
:: %1: The boilerplate file, i.e. what's being commented.
:: %2: The extension of the file that is having this commented file inserted, i.e. what comment character is needed.
:: %3: The path to the directory to put the commented file into.

setlocal EnableDelayedExpansion

REM setlocal

REM set "char="
set "BOILERPLATE=%~1"
set "BOILERPLATE_NAME=%~n1"
set "ext=%~2"
set "outputDir=%~3"

call :debug "In 'comment_boilerplate'" "Passed boilerplate file: '%BOILERPLATE%'" "Boilerplate name: '%BOILERPLATE_NAME%'" "Passed extension: '%ext%'" "Passed output dir: '%outputDir%'" "
  
if /I "%ext%"==".py" (set "char=#")
if /I "%ext%"==".md" (
  set "char=%%%%"
  call :debug "We're in the .md conditional."
)
if /I "%ext%"==".bat" (set "char=::")
if /I "%ext%"==".yml" (set "char=#")
if /I "%ext%"==".yaml" (set "char=#")
if /I "%ext%"==".cpp" (set "char=//")
if /I "%ext%"==".c" (set "char=//")
if /I "%ext%"==".toml" (set "char=#")
if /I "%ext%"==".ini" (set "char=#")
if /I "%ext%"==".env" (set "char=#")

if not defined char (
  call :debug "char not defined, prompting for user input."
  set /p "char=Please enter the character to use for commenting in '%BOILERPLATE_NAME%%ext%': "
)

call :debug "Comment character set to '%char%' or '!char!' hopefully? Unless it's a percent sign, those are dumb."

(
  for /f "usebackq delims=" %%A in (`findstr /n "^" "%BOILERPLATE%"`) do (
    set "line=%%A"
    set "line=!line:*:=!"
    echo !char! !line!
  )
) > "%outputDir%\%BOILERPLATE_NAME%%ext%"

call :debug "Finished writing '%outputDir%\%BOILERPLATE_NAME%!ext!'."

endlocal
exit /b


::=================================================================================================
::=================================================================================================  

:: USEAGE: 
  REM set DEBUG=true
  REM call :debug "Starting process..." "Step 1 complete." "Step 2 complete."
:: OUTPUT:
  REM [DEBUG] Starting process...
  REM [DEBUG] Step 1 complete.
  REM [DEBUG] Step 2 complete.


REM :debug
REM if /I not "%DEBUG%"=="true" exit /b
REM echo.

REM setlocal EnableDelayedExpansion

REM set "i=1"
REM :debug_loop
REM call set "arg=%%~%i%%"
REM if "!arg!"=="" (
  REM echo.
  REM exit /b
REM )
REM echo [DEBUG] !arg!
REM REM shift
REM set /a i+=1
REM goto debug_loop

REM :debug
REM if /I not "%DEBUG%"=="true" exit /b
REM echo.
REM :debug_loop
REM if "%~1"=="" goto :eof
REM echo [DEBUG] %~1
REM shift
REM goto debug_loop

::=================================================================================================
::================================================================================================= 


:: --- Helper to load config values safely ---
:: %1: the config file
:load_config

call "%~1"
set "CONFIG_USER_NAME=%USER_NAME%"
set "CONFIG_USER_EMAIL=%USER_EMAIL%"
set "CONFIG_DEFAULT_PARENT_DIR=%DEFAULT_PARENT_DIR%"
set "CONFIG_TEMPLATES_DIR=%TEMPLATES_DIR%"
set "CONFIG_PLACEHOLDERS=%PLACEHOLDERS%"
set "CONFIG_PLACEHOLDER_REPLACEMENT_SCRIPT=%PLACEHOLDER_REPLACEMENT_SCRIPT%"
goto :eof



:: ==========================================================
:: Centralized Safe-Exit Handling
:: ==========================================================
:SafeExit
:: Safely exits with a standard format.
:: Accepts any number of strings to print before exiting.
:: Pauses right before exiting as well. 

setlocal EnableDelayedExpansion

echo.

:safeExitLoop
if "%~1"=="" goto safeExitEnd
echo [EXITING] %~1 1>&2
shift
goto safeExitLoop

:safeExitEnd
echo [EXITING] Goodbye for now 1>&2
endlocal
set "ABORT_SCRIPT=1"
pause
exit /b 1


:: ==========================================================
:: Centralized Debug/Logging Subroutine
:: Method for printing debugging statements.
:: Optionally takes a numeric level as the first parameter.
:: If the first parameter does not start with a digit then level defaults to 1.
:: Usage: call :_debug [level] "Message 1" "Message 2" ...
:: ==========================================================

:: MAJOR NOTE!! I originally wanted to write wrappers for this functionality (e.g. 'debug1') and make this into an internal helper function. The issue is that passing an arbitrary number of arguments from 'debug1' to 'debug' would have been fragile. The "obvious" way to do is to call, from within 'debug1', 'call :debug 1 %*', where the '%*' would pass all the subsequent arguments. The issue is that this notation doesn't work within certain contexts (e.g. loops or other blocks wih extra parsing) and 'DelayedExpansion' interferes with it. There is way to avoid it - you loop over all the passed arguments to build a single string and pass that - but that kind of defeats the purpose of the wrapper since each of the wrappers would need this nearly-identical code. So instead, it's preferred here to use a single method that's a bit more flexible at the expense of an extra subroutine parameter.
:: All this is to say, don't try breaking this up into wrappers. 

:debug
setlocal EnableDelayedExpansion

REM call :debug 4 "Inside the 'debug' subroutine."

:: If global debugging is off, exit this gracefully and early.
if "!DEBUG_LEVEL!"=="0" (
    REM call :debug 4 "Debugging is disabled. No printing."
    endlocal
    goto :eof
)

:: Check if the first argument is non-empty and if its first character is a digit.
set "firstArg=%~1"
REM call :debug 4 "firstArg: !firstArg!"
if defined firstArg (
    set "firstChar=%firstArg:~0,1%"
    REM call :debug 4 "firstChar: !firstChar!"
) else (
    REM call :debug 4 "firstArg was not defined, so neither is firstChar."
    set "firstChar="
)

:: If firstChar is a digit (between "0" and "9"), use it as the debug level.
:: Otherwise, default to level 0.
if defined firstChar (
  if "!firstChar!" gtr "0" if "!firstChar!" leq "9" (
      REM call :debug 4 "firstChar is between 0 and 9, so setting level to %~1."
      set "level=%~1"
      shift
  ) else (
      REM call :debug 4 "firstChar was not between 0 and 9 (or wasn't an int at all). Level set to 0."
      set "level=0"
  )
)

:: Only output debug messages if the global DEBUG_LEVEL is at least as high as the message level.
if !DEBUG_LEVEL! LSS !level! (
    REM call :debug 4 "The debugging level, !DEBUG_LEVEL!, was less than the level, !level!. Returning."
    endlocal
    goto :eof
)

echo.
:debug_loop
if "%~1"=="" goto after_debug
REM call :debug 4 "Next argument: '%~1'"
echo [DEBUG] %~1 1>&2
shift
goto debug_loop

:after_debug
REM call :debug 4 "End of debugging subroutine - no more arguments."
endlocal
goto :eof


:: ==========================================================
:: Centralized logging method
::
:: Method for printing non-debugging statements with some sort of standard.
:: ('Logging' here doesn't mean it logs to a file. Only the 'ERROR' level will output to the stderr stream.)
::
:: Parameters:
::      %1: The severity. This should be 'INFO', 'WARNING', or 'ERROR', but technically it could be anything (within reason, giving the limitations of Batch).
::      %2... %N: Any number of strings. These will be printed in order, each on it's own line with it's own severity indicator.
::
:: Usage: 
::      call :log "INFO" "This is some information."
::
:: Notes:
::      I originally wanted to write wrappers for this functionality (e.g. 'warn', or 'info') and make this into an internal helper function. The issue is that passing an arbitrary number of arguments from 'info' to 'log' would have been fragile. The "obvious" way to do is to call, from within 'info', 'call :log "INFO" %*', where the '%*' would pass all the subsequent arguments. The issue is that this notation doesn't work within certain contexts (e.g. loops or other blocks wih extra parsing) and 'DelayedExpansion' interferes with it. There is way to avoid it - you loop over all the passed arguments to build a single string and pass that - but that kind of defeats the purpose of the wrapper since each of the wrappers would need this nearly-identical code. So instead, it's preferred here to use a single method that's a bit more flexible at the expense of an extra subroutine parameter.
:: All this is to say, don't try breaking this up into wrappers. 
:: ==========================================================

:log
call :debug 4 "Inside the 'log' subroutine."

set "severity=%~1"
call :debug 4 "Severity set to '%~1'."
if /I "%severity%"=="ERROR" (
  call :debug 4 "This will send messages to stderr."
) else (
  call :debug 4 "This is NOT an error (it was '%severity%'), so will print normally."
)
shift

REM Print first argument on same line as severity.
REM Subsequent arguments will be on intended unlabeled lines.

set "msg=%~1"
if /I "%severity%"=="ERROR" (
  echo.
  echo --[ERROR]-- %msg%1>&2
) else (
    if "%severity%"=="WARNING" (
      echo.
      echo -[WARNING]- %msg%
    ) else (
        echo [%severity%]: %msg%
    )
)
shift

setlocal EnableDelayedExpansion

:log_loop
if "%~1"=="" goto log_done
call :debug 4 "Next argument: '%~1'"
REM set "msg=!msg! %~1"
REM call :debug 4 "Message is now: '!msg!'"
REM shift
REM goto log_loop

set "msg=%~1"
if /I "%severity%"=="ERROR" (
  echo     !msg! 1>&2
) else (
  echo     !msg!
)
shift
goto log_loop


:log_done
REM Basic example: errors go to stderr.
call :debug 4 "End of 'log' subroutine - no more arguements."

endlocal
goto :eof


:: ==========================================================
:: LoadPlaceholders Subroutine
:: Reads key=value pairs from a file and sets them as plain variables.
:: Also records each key in the PLACEHOLDERS variable.
:: Usage: call :LoadPlaceholders "full_path_to_file"
:: ==========================================================
:LoadPlaceholders
if not exist "%~1" (
    call :log "WARNING" File "%~1" not found.
    goto :eof
)
for /F "usebackq tokens=1* delims==" %%A in ("%~1") do (
    if not "%%A"=="" (
        set "lineKey=%%A"
        if not "!lineKey:~0,1!"=="#" (
            call :AddPlaceholder "%%A" "%%B"
        )
    )
)
goto :eof



:: ==========================================================
:: AddPlaceholder Subroutine
:: Adds a key to the PLACEHOLDERS list if not already present.
:: Usage: call :AddPlaceholder "key"
:: ==========================================================
:AddPlaceholder
set "key=%~1"
set "value=%~2"

call :debug 2 "In AddPlaceholder with key=%~1 and value=%~2"
call :debug 2 "How many placeholders do we have so far? %PLACEHOLDER_COUNT%"

:: Check if key already exists
call :debug 3 "Checking for duplicate keys..."
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    call :debug 3 "Is '!PLACEHOLDER_KEY_%%N!' equal to '%key%'?"
    if "!PLACEHOLDER_KEY_%%N!"=="%key%" (
        call :debug 3 "Updating existing placeholder: '!PLACEHOLDER_KEY_%%N!' is now '%value%'."
        set "PLACEHOLDER_VALUE_%%N=%value%"
        goto :eof
    )
)

:: Key was not found, add a new entry
call :debug 2 "Key %key% was not found in the placeholders set."
set /A PLACEHOLDER_COUNT+=1
set "PLACEHOLDER_KEY_!PLACEHOLDER_COUNT!=%key%"
set "PLACEHOLDER_VALUE_!PLACEHOLDER_COUNT!=%value%"
call :debug 3 "Added new placeholder: mapped '!key!' to '!value!'."
goto :eof



:: ==========================================================
:: ParseArguments Subroutine
:: Processes CLI parameters in the form --key=value (or key=value).
:: Unknown parameters (which are valid key/value pairs) are added as placeholders.
:: Also, explicitly handled keys (package, repo, description, etc.) update corresponding flags.
:: Priority: CLI overrides previous settings.
:: Usage: call :ParseArguments %*
:: ==========================================================
:ParseArguments
call :debug 2 "In ParseArguments"
:ParseArgsLoop
call :debug 3 "At the top of the 'ParseArgsLoop'"
if "%~1"=="" goto EndParseArgs

set "arg=%~1"
call :debug 2 "Arg = !arg!"

:: Remove leading '--' if present
if "!arg:~0,2!"=="--" set "arg=!arg:~2!"

:: Split at '=' to extract key (param) and value (val)
for /F "tokens=1,* delims==" %%A in ("!arg!") do (
    set "param=%%A"
    set "val=%%B"
    call :debug 3 "Arg parsed as '!param!' and '!val!'."
)

:: Check for known parameters and update variables accordingly.
if /I "!param!"=="debug" (
    call :debug 3 "Param identified as 'debug', previously identified and set. Skipping."
    shift 
    goto ParseArgsLoop
)


REM Some potential keys need a bit of special handling.
if /I "%param%"=="package" (
    set "CLI_package=1"
    call :debug 3 "CLI_package set"
    pause
)
if /I "%param%"=="repo_name" (
    set "CLI_repo=1"
    call :debug 3 "CLI_repo set"
)
if /I "%param%"=="repo-name" (
    set "param=repo_name"
    set "CLI_repo=1"
    call :debug 3 "CLI_repo set"
)
if /I "%param%"=="description" (
    set "CLI_desc=1"
    call :debug 3 "CLI_desc set"
)
if /I "%param%"=="author" (
    set "AUTHOR_DEFINED=1"
    call :debug 3 "author set in CLI"
)
if /I "%param%"=="email" (
    set "EMAIL_DEFINED=1"
    call :debug 3 "email defined in CLI"
)
if /I "%param%"=="license_spdx" (
    set "LICENSE_DEFINED=1"
    call :debug 3 "License defined in CLI"
)
if /I "%param%"=="license-spdx" (
    set "param=license_spdx"
    set "LICENSE_DEFINED=1"
    call :debug 3 "License defined in CLI"
)
if /I "%param%"=="parent-dirPath" set "param=parent_dirPath"


REM All parameters that are passed are added to the Placeholders "list" for later processing.
REM These will be accessible later as well via 'PH_%param%'. 
call :AddPlaceholder "%param%" "%val%"


shift
goto ParseArgsLoop
:EndParseArgs
call :debug 2 "End of 'ParseArgsLoop' - no more arguments."
goto :eof


:: ==========================================================
:: CollectMissingInputs Subroutine
:: Prompts for any required inputs not supplied via CLI/config.
:: Explicitly handled keys (package, repo, description) are prompted for.
:: Usage: call :CollectMissingInputs
:: ==========================================================
:CollectMissingInputs
call :debug 2 "In CollectMissingInputs"

REM if not defined CLI_package (
  REM call :debug 2 "CLI argument not provided for package; prompting."
  REM echo.
  REM echo Enter a name for the package ^(should be lowercase or snake-case^).
  REM set /p "package=>>> "
  REM REM call :AddPlaceholder "package"
  REM call :AddPlaceholder "package" "!package!"
  REM set "PACKAGE_DEFINED=true"
  REM call :debug 3 "package set to '!package!'."
REM ) else (
    REM call :debug 2 "Package was already defined, no prompt needed."
REM )

REM call :EnsurePlaceholderSet CLI_package PH_package "Enter a name for the package." "Should be lower-case or snake-case."
REM Parameters: %1 = CLI Variable, %2 = Placeholder Key, %3 = Prompt Message, %4 = Additional Instructions (Optional)


if not defined CLI_package (
    call :debug 2 "CLI argument not provided for package; prompting."
    call :PromptForInput package "Enter a name for the package." "Should be lower-case or snake-case."
    call :AddPlaceholder "package" "!package!"
    call :debug 3 "package set to '!package!'." 
) else (
    call :debug 2 "Package was already defined as '!package!', no prompt needed."
)

pause

REM if "!REPO_SAME_AS_PACKAGE!"=="true" (
  REM call :debug 2 "The '--repo-sameAs-package' flag was passed. Naming the repo '%package%'."
  REM set "repo_name=%package%"
  REM REM call :AddPlaceholder "repo_name"
  REM call :AddPlaceholder "repo_name" "%package%"
  REM set "REPO_DEFINED=true"
REM ) else (
    REM call :debug 2 "REPO_SAME_AS_PACKAGE was NOT defined."
REM )

REM if not defined CLI_repo (
  REM call :debug 2 "CLI argument not provided for repo; prompting."
  REM echo.
  REM echo Enter a name for the git repo ^(should be lowercase or kebab-case^).
  REM set /p "repo_name=>>> "
  REM REM call :AddPlaceholder "repo_name"
  REM call :AddPlaceholder "repo_name" "!repo_name!"
  REM set "REPO_DEFINED=true"
  REM call :debug 3 "Repo name set to '!repo_name!'."
REM ) else (
    REM call :debug 2 "Repo was already defined, no prompt needed."
REM )

if not defined CLI_repo (
    call :debug 2 "CLI argument not provided for the repo_name; prompting."
    call :PromptForInput repo_name "Enter a name for the repo." "Should be lower-case or kebab-case."
    call :AddPlaceholder "repo_name" "!repo_name!"
    call :debug 3 "repo set to '!repo_name!'." 
) else (
    call :debug 2 "Repo_name was already defined as '!repo_name!', no prompt needed."
)

REM if not defined CLI_desc (
  REM call :debug 2 "CLI argument not provided for description; prompting."
  REM echo.
  REM echo Enter a short project description.
  REM echo     - This should be one ^(1^) sentence that tackles the 'what' and 'why' for this package.
  REM echo     - This will be displayed in the .toml and the README.
  REM echo     - [RESTRICTIONS]: No exclamation marks, percent signs, carets, ampersands, pipes, or angle brackets. The CLI really hates them.
  REM echo.
  REM set /p "description=>>> "
  REM call :AddPlaceholder "description" "!description!"
  REM REM call :AddPlaceholder "description"
  REM call :debug 3 "description set to '!description!'."
REM ) else (
    REM call :debug 2 "Description was already defined, no prompt needed."
REM )

if not defined CLI_desc (
    call :debug 2 "CLI argument not provided for description; prompting."
    call :PromptForInput description "Enter a description." "This should be one (1) sentence that tackles the 'what' and 'why' for this package." "This will be displayed in the .toml and the README." "[RESTRICTIONS]: No exclamation marks, percent signs, carets, ampersands, pipes, or angle brackets. The CLI really hates them."
    call :AddPlaceholder "description" "!description!"
    call :debug 3 "description set to '!description!'." 
) else (
    call :debug 2 "A description was already provided as '!description!', no prompt needed."
)

REM Sort of a hacky way to check for additional prompts that may be needed.
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    if "!PLACEHOLDER_KEY_%%N!"=="author" set AUTHOR_DEFINED=true
    if "!PLACEHOLDER_KEY_%%N!"=="email" set EMAIL_DEFINED=true
)

if not defined AUTHOR_DEFINED (
    call :debug 2 "CLI argument not provided for author; prompting."
    call :PromptForInput author "Enter a name for an author of this package."
    call :AddPlaceholder "author" "!author!"
    call :debug 3 "author set to '!author!'." 
) else (
    call :debug 2 "Author was already defined as '!author!', no prompt needed."
)

if not defined EMAIL_DEFINED (
    call :debug 2 "CLI argument not provided for email; prompting."
    call :PromptForInput email "Enter a contact email address." "No validation is done here."
    call :AddPlaceholder "email" "!email!"
    call :debug 3 "email set to '!email!'." 
) else (
    call :debug 2 "Email was already defined as '!email!', no prompt needed."
)

call :debug 2 "End of CollectMissingInputs."
goto :eof


REM Define subroutine for checking and setting placeholders
:EnsurePlaceholderSet
REM REM Parameters: %1 = CLI Variable, %2 = Placeholder Key, %3 = Prompt Message, %4 = Additional Instructions (Optional)
REM setlocal EnableDelayedExpansion
set "CLI_var=%~1"
call set "CLI_var_val=%%%CLI_var%%%"
set "PH_key=%~2"
call set "PH_val=%%%PH_key%%%"
set "msg=%~3"
set "addlMsg=%~4"
call :debug 3 "In EnsurePlaceholderSet" "CLI_var = %CLI_var%" "CLI_var_val = %CLI_var_val%" "PH key = %PH_key%" "PH_val = !PH_val!" "Message = %msg%" "Additional message = %addlMsg%"
REM endlocal
if not defined %CLI_var% (
    call :debug 2 "CLI argument not provided for '%PH_key%'; prompting."
    call :PromptForInput %PH_key% "%msg%" "%addlMsg%"
    call :AddPlaceholder "%PH_key%" "!PH_val!"
    call :debug 3 "%PH_key% set to '!PH_val!'."
) else (
    call :debug 2 "%PH_key% was already defined, no prompt needed."
)
if not "!CLI_var!"=="" (
    call :debug 3 "In the check of the delayed expansion of CLI_var, it appears to be !CLI_var!."
) else (
    call :debug 3 "In the check of the delayed expansion of CLI_var, it appears to be null or empty."
)
call :debug 3 "Exiting 'EnsurePlaceholderSet'"
exit /b

:: ==========================================================
:: This subroutine exports the placeholders to environment variables.
:: For instance, after calling this, %package% will contain the finalized package name.
:: ==========================================================
:ExportPlaceholders
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    set "k=!PLACEHOLDER_KEY_%%N!"
    set "v=!PLACEHOLDER_VALUE_%%N!"
    call set "PH_%%k%%=!v!"
)
goto :eof


:PromptForInput
rem ====================================================
rem %1 - The name of the variable to return the value into.
rem %2 - The prompt message to display.
rem ====================================================
setlocal EnableDelayedExpansion

set "varName=%~1"
call :debug 3 "VarName = %varName%"
shift
echo.

if "%~1"=="" (
    call :debug "Second argument was empty, using default prompt string."
    echo Enter a value for !varName!.
    goto InputPrompt
)

set "TAB="
:InputLoop
set "msg=%~1"
echo !TAB!!msg!
set "TAB=    "
shift
if "%~1"=="" goto InputPrompt
call :debug 3 "Third argument was NOT empty, looping."
goto InputLoop

:InputPrompt
call :debug 3 "End of arguments; prompting."
echo.
set /p "temp=    >>> "
echo.
echo You entered: "!temp!".
REM set /p "confirm=Is this correct? (Y/N): "
REM if /I "!confirm!" neq "Y" (
choice /M "Is this correct "
if errorlevel 2 (
    echo Let's try again...
    goto InputPrompt
) else (
    call :debug 3 "Confirmed"
)
(
    endlocal
    rem Use a block to pass the value back. The variable name is provided in %~1.
    set "%varName%=%temp%"
)
REM I wanted to add a debug call here but none of these worked.
REM It's tricky because %varName% is the name of the variable but I want the value of the variable without accessing %temp%. 
REM call :debug 3 "Variable '%varName%' set to '%%%varName%%%'"
REM call echo You entered: %%!varName!%%
REM call set "result=%%%varName%%%"
REM call set "result=%%!varName!%%"
REM echo You entered: %result%
goto :EOF





:WaitForEnter
rem -------------------------------------------------
rem Displays a custom pause message, which also allows the user to safely quit.
rem The two-line trick is used:
rem   1. Print the custom message without waiting (via <nul set /p ...).
rem   2. Then wait for the user to press Enter (via set /p dummy="").
REM   3. The user can also press 'q' to quit the script.
rem 
rem %1 - The custom message to display. NOTE that the custom messae comes AFTER 'Press enter to ', so customize appropriately. 
REM
REM Notes:
REM  - One-line set /p (without <nul): Displays the prompt and then waits for the user’s input. → This is a simple way to pause with a custom message, but remember it will wait at that prompt. E.g. set /p dummy="Your custom message: Press Enter to continue..."
REM  - Two-line approach: First line prints a custom message immediately (without pausing), and the second line then waits for the user to press Enter. → This is useful if you want to control exactly how the output appears (for instance, without a newline between the message and the input prompt). E.g. used in this subroutine.
rem -------------------------------------------------


echo.
<nul set /p "=Press 'Enter' to %~1, or 'Q' to quit."
set /p dummy=""
if /I "%dummy%"=="q" call :SafeExit

call :linebreak

echo.
goto :eof


:linebreak
rem -------------------------------------------------
rem Prints a horizontal line made up of the passed character in %1,
rem the length of which equals the width of this console.
rem Uses PowerShell to retrieve the window width.
rem -------------------------------------------------

if "%~1"=="" (
    set "linechar=-"
) else (
    set "linechar=%~1"
)

REM for /f "usebackq delims=" %%B in (`powershell -NoProfile -Command "$cols=$Host.UI.RawUI.WindowSize.Width; Write-Output (New-Object string($env:linechar, $cols))"`) do ( 
  REM echo %%B 
REM )

REM Note: The 'COLS' variable is set globally at the beginnning of the script in order to reduce overhead.

for /f "usebackq delims=" %%B in (
  `powershell -NoProfile -Command "Write-Output ($env:LINECHAR * $env:COLS)"`
) do (
  echo %%B
)
goto :EOF



:SectionHeader
:: %1 is the text of the header
echo.
call :linebreak "="
call :linebreak "="
echo.
echo ---- %~1 ----
echo.
call :linebreak "="
call :linebreak "="
echo.

goto :eof


:SubsectionHeader
:: %1 is the text of the subheader
echo.
call :linebreak "-"
echo.
echo %~1 
echo.
call :linebreak "-"
echo.