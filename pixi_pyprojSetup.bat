@echo off
setlocal EnableDelayedExpansion

:: ====================================================================================================================
:: ====================================================================================================================
:: File: 'pixi-pyprojSetup.bat'

:: Description: A CLI-based Python project creation script that uses templates and a set of placeholders to generate the required src-layout directory structure with basic files for a barebone Python package. See the README.md for a more complete discussion of the setup and usage.

:: Fixed parameters:

::     "debug=<VALUE>": Sets the script's debugging level (0 being no debugging, 4 being more debugging than you probably need). This will overwrite the level set on the CLI externally (via 'set "DEBUG_LEVEL=<LEVEL>"'). If nothing is passed and no environmental variable is set, it will default to 0. If nothing is passed but an environmental variable is set, it will confirm the level with you before proceeding.

::     "validate=<path-to-baseline-root>": If this is passed, a directory-validation script will run at the end of the script against the <path-to-baseline-root> directory structure. If no path is provided, it will be prompted for.

::     "<PLACEHOLDER>=<VALUE>": Any placeholder can be passed via CLI with a specific replacement value using this format. See README.md for how this works.
  
  
:: Notes:

::     - Parameters MUST be fully quoted. The internal Batch parsing algorithm seems to require it. If you know a way around it, please contact me. 
::     - PowerShell must be installed. If version 7 if available, then that will be used; otherwise, whatever is installed at "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" will be used. I've tested this with 5.1, but not prior versions.
 

:: Licensing and Versioning Notice

::    - This file is copyrighted by Ben Hurwitz <bchurwitz+pixi_pyprojSetup@gmail.com>, 2025, under the GNU GPL v3.0. 
::    - Much of this file was written with the help of ChatGPT, versions GPT-4o, GPT-4o mini, and o3-mini, and Microsoft Copilot.
::        - See <https://chatgpt.com/share/67ffcd98-a7a8-800e-9dcd-8c4b78f895f8> and <https://chatgpt.com/share/68029d02-9f70-800e-a201-8765513870a8>
::        - Unforutnately, the Copilot chats cannot seem to be shared.
::    - This file is version-controlled via git and saved on GitHub under the repository <https://github.com/bhurwitz/pixi-pyprojSetup>

:: ====================================================================================================================
:: ====================================================================================================================

:: ====================================================================================================================
:: =========== Global Parameters
:: ====================================================================================================================
set "TAB=    "
set "TTAB=%TAB%%TAB%"
set "ERR_STR="
for /f "usebackq delims=" %%A in (
  `powershell -NoProfile -Command "$Host.UI.RawUI.WindowSize.Width"`
) do set "COLS=%%A"

REM Sets the directory path to the '\config' subdirectory where the configuration files are located. This needs to be known immediately.
set "config_dirPath=%CD%\config"



:: ====================================================================================================================
:: =========== Start of script
:: ====================================================================================================================
:startOfScript

call :SectionHeader "Welcome to pixi-pyprojSetup :-)" "This script is used to setup a Python project with Pixi, the package management software."

:: Check if pixi is available
where pixi >nul 2>&1
if "%errorlevel%"=="1" (
  call :Log "ERROR" Pixi is not installed! Exiting...
  exit /b 1
) else (
    REM echo We're going to update Pixi first.
    REM pixi self-update
)

:: ====================================================================================================================
:: =========== Set debugging parameter
:: ====================================================================================================================
:setGlobalDebug

REM set "DEBUG=true"
set MAX_DEBUG=4

REM :: Set default if not provided
if defined DEBUG_LEVEL (

    if !DEBUG_LEVEL! LSS 1 (
        set DEBUG_LEVEL=0
        REM call :Log "STATUS" "Debugging was DISABLED via global environmental variable."
    ) 
    if !DEBUG_LEVEL! GTR %MAX_DEBUG% (
        set DEBUG_LEVEL=%MAX_DEBUG%
        call :Log "WARNING" "DEBUG_LEVEL had been set above the maximum of %MAX_DEBUG%, so it was reset to the maximum level."
    )
    if !DEBUG_LEVEL! GTR 0 if !DEBUG_LEVEL! LEQ %MAX_DEBUG% (
        call :Log "STATUS" "Debugging ENABLED at level !DEBUG_LEVEL! via global environmental variable."
        choice /M "Did you intend to set that debugging level?"
        if !errorlevel! equ 2 (
            choice /C:01234Q /M "Enter [0] for no debugging, [1-4] to select a debugging level, or [Q] to quit."
            if !errorlevel! EQU 6 (
                call :SafeExit
                exit /b 1
            )
            if !errorlevel! EQU 1 (
                call :log "STATUS" "Debugging has been DISABLED."
            )
            set /a "DEBUG_LEVEL=!errorlevel!-1"
        )
    )
)


REM The DEBUG_LEVEL can be overwritten by passing it through the CLI, e.g. "--debug=2", but it (like any CLI parameter for this script) must be quoted in its entirety, e.g. "debug=2" not just debug=2.
set "DEBUG_SET="
call :Log "debug1" "Looking for a 'debug' CLI parameter..."
REM echo %*
for %%A in (%*) do (
    if not defined DEBUG_SET (
        set "curr=%%A"
        call :Log "debug2" "I see '!curr!'."
        REM Remove the quotes
        set "arg=%%~A"
        call :Log "debug2" "I see '!arg!', quotes removed."
        REM Remove the leading double-dashes, if passed.
        if "!arg:~0,2!"=="--" set "arg=!arg:~2!"
        call :Log "debug2" "And now it's '!arg!'."
        REM Split the argument at the first '='
        for /F "tokens=1,2 delims==" %%B in ("!arg!") do (
            call :Log "debug2" "Now it's split into '%%B' and '%%C'."
            REM Identify the debug flag and set it. 
            if /I "%%B"=="debug" (
                call :Log "debug2" "There it is!"
                if defined DEBUG_LEVEL (
                    set prevDebug=!DEBUG_LEVEL!
                    set "DEBUG_LEVEL=%%C"
                    call :Log "debug!DEBUG_LEVEL!" "Debugging level ADJUSTED from !prevDebug! to !DEBUG_LEVEL! via the CLI."
                ) else (
                    set "DEBUG_LEVEL=%%C"
                    call :Log "debug!DEBUG_LEVEL!" "Debugging ENABLED at level !DEBUG_LEVEL! via CLI."
                )
                set "DEBUG_SET=true"
            )
        )
    )
)

if not defined DEBUG_LEVEL set "DEBUG_LEVEL=0"

if !DEBUG_LEVEL! GTR 0 call :Log "STATUS" "Debugging ENABLED at level !DEBUG_LEVEL!."


REM call :WaitForEnter "load configuration files"
REM if defined ABORT_SCRIPT exit /b 1

:: ====================================================================================================================
:: =========== Loading configuration and placeholder parameters
:: ====================================================================================================================

:processParameters


:: --- 1. Load General Configuration Defaults ---
REM THESE ARE IMMUTABLE AND SHOULD NOT BE CHANGED.
REM Note that we intentionally import these twice to avoid a situation in which a variable is loaded before it's required whatever-the-opposite-of-dependents-is. For example, if the file has VAR_B above VAR_A, but VAR_B depends on VAR_A (e.g. VAR_B=%VAR_A%), VAR_B won't be properly loaded (it will be empty in this case), but if we re-load the file, VAR_A will be defined when VAR_B is re-defined. 
REM call :Log "debug1" "Loading the config file next."
<nul set /p="[INFO] Loading general configuration file... "
call "%config_dirPath%\pixi_pyprojSetup_config.cmd"
if errorlevel 1 (
    echo.
    call :Log "ERROR" "Something went wrong with loading the general configuration defaults." "Make sure that the config file exists at '\config\pixi_pyprojSetup_config.cmd"
    echo.
    call :SafeExit "The script can't continue without these variables."
    exit /b 1
)
call "%config_dirPath%\pixi_pyprojSetup_config.cmd"
if errorlevel 1 (
    echo.
    call :Log "ERROR" "Something went wrong with re-loading the general configuration defaults to fill in some paths." "Make sure that the config file exists at '\config\pixi_pyprojSetup_config.cmd"
    echo.
    call :SafeExit "The script can't continue without these variables."
    exit /b 1
)
REM call :Log "INFO" "Config file loaded."
echo success.

:: --- 1.1 Setup PowerShell details
REM Set the proper PowerShell path - 7 if it exists, 5.1 if not. 
set "PWSH_PATH=C:\Program Files\PowerShell\7\pwsh.exe"

REM Check if PowerShell 7 exists.
if exist "%PWSH_PATH%" (
    call :Log "STATUS" "Running with PowerShell 7"
) else (
    call :Log "STATUS" "Powershell 7 does not exist. Running with PowerShell 5.1 ^(or whatever is installed^)."
    set "PWSH_PATH=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
)

REM Add the scripts directory path to the PSModulePath so that PS can find modules from within it's scripts. 
set "PSModulePath=%PSModulePath%;%CFG_scripts_dirPath%\PSModules"
REM "%PWSH_PATH%" -NoProfile -Command "echo $env:PSModulePath"
REM "%PWSH_PATH%" -NoProfile -Command "Get-Module -ListAvailable"

REM Now we'll set the placeholders and null some definitions.
set PLACEHOLDER_COUNT=0
set "CLI_package="
set "CLI_repo="
set "CLI_desc="
set "AUTHOR_DEFINED="
set "EMAIL_DEFINED="
set "LICENSE_DEFINED="
set "VALIDATE="

:: --- 2. Load Default Placeholder Values ---
if %DEBUG_LEVEL% LEQ 1 (
    <nul set /p="[INFO] Loading default placeholders... "
) else (
    call :Log "INFO" "Loading default placeholders"
)
call :LoadPlaceholders "%config_dirPath%\placeholders.DEFAULT"
if errorlevel 1 (
    call :Log "ERROR" "Something went wrong with loading the placeholder defaults." "Make sure that the config file exists at '\config\placeholders.DEFAULT"
    echo.
    choice /C:CQ /N /M "Would you like to continue without these values (any placeholders not in the user file will fail to be replace) [C] or quit [Q]?"
    if errorlevel 2 (
        call :SafeExit
        exit /b 1
    ) else (
        call :Log "INFO" "%TAB%Continuing without loading the default placeholders."
    )
    call :ResetError
) else (
    REM call :Log "INFO" "Default placeholders loaded."
    echo success.
)


:: --- 2.1 Assigning additional parameter defaults dynamically ---
for /f %%I in ('powershell -NoProfile -Command "(Get-Date).Year"') do set PH_year=%%I
call :AddPlaceholder "year" "%PH_year%"
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "PH_date=%%A"
call :AddPlaceholder "date" "%PH_date%"



:: --- 3. Override with User Placeholder Config ---
REM call :Log "debug1" "Reading from '%config_dirPath%\placeholders.USER'."
if %DEBUG_LEVEL% LEQ 1 (
    <nul set /p="[INFO] Loading user-defined placeholders... "
) else (
    call :Log "INFO" "Loading user-defined placeholders"
)
call :LoadPlaceholders "%config_dirPath%\placeholders.USER"
if errorlevel 1 (
    echo.
    call :Log "WARNING" "User's 'placeholders' file failed to load!"
    choice /C:CQ /N /M "Would you like to continue without these [C] or quit [Q]?"
    if ERRORLEVEL 2 call :SafeExit
    if defined ABORT_SCRIPT exit /b 1
    call :Log "INFO" "%TAB%Continuing without the user's placeholders."
    call :ResetError
) else (
    echo success.
)


:: --- 4. Process CLI Parameters (highest priority) ---
if %DEBUG_LEVEL% LEQ 1 (
    <nul set /p="[INFO] Parsing CLI arguments... " 
) else (
    call :Log "INFO" "Parsing CLI arguments"
)
call :ParseArguments %*
if errorlevel 1 (
    echo.
    call :Log "WARNING" "CLI parameter parsing failed!" "The critical parameters can be set manually later in the script."
    choice /C:CQ /N /M "Would you like to continue without these [C] or quit [Q]?"
    if ERRORLEVEL 2 call :SafeExit
    if defined ABORT_SCRIPT exit /b 1
    call :Log "INFO" "%TAB%Continuing without the CLI parameters."
    call :ResetError
) else (
    echo success.
)

:: --- 5. Consolidate and Debug (Collect additional user input if missing) ---
REM call :Log "debug1" "Prompt for remaining required parameters..."
if %DEBUG_LEVEL% LEQ 1 (
    <nul set /p="[INFO] Verifying final parameters... "
) else (
    call :Log "INFO" "Parsing CLI arguments"
)
call :CollectMissingInputs
set "ERR=%ERRORLEVEL%"
if "%ERR%"=="0" (
    echo success - no missing inputs.
) else (
    if "%ERR%"=="1" (
        echo success - all missing inputs collected.
    ) else (
        echo.
        call :Log "WARNING" "Something is odd - 'MISSING_INPUTS' in 'CollectMissingInputs' was neither true nor false. Continuing."
    )
)
call :ResetError

REM Export placeholders to environment variables for easier retrieval later.
call :ExportPlaceholders
call :Log "debug2" "Placeholders written to environment, including but not limited to:" "Package = %PH_package%" "Author = %PH_author%" "Version = %PH_version%"


:: ====================================================================================================================
:: =========== Licensing selection
:: ====================================================================================================================

:selectLicense

REM call :Log "debug1" "license_spdx = %PH_license_spdx%"
echo. 
if defined LICENSE_DEFINED (
  call :Log "debug1" "License is defined as '%PH_license_spdx%', supposedly."
  if not exist "%CFG_license_dirPath%\license_%PH_license_spdx%.txt" (
    call :Log "WARNING" "CLI-passed license SPDX code '%PH_license_spdx%' does not have a license file in the license templates directory, located at '%CFG_license_dirPath%'."
    choice M/ "Please select an existing license from the following list [Y], or quit the script and try again [N]."
    if errorlevel 2 (
        call :SafeExit "Don't forget to add a license called '%CFG_license_dirPath%\license_%PH_license_spdx%.txt'."
        exit /b 2
    )
    echo.
    set LICENSE_DEFINED=
  )
) else (call :Log "debug1" "License has not been defined beyond the default.")


if defined LICENSE_DEFINED goto skipLicensePrompting

echo.
echo The following licenses are available ^(as pulled from 'Templates\Licenses'^):

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

REM Ensure that at least one license template was found
if %count%==0 (
  call :Log "WARNING" "No license templates found in '%CFG_license_dirPath%'."
  choice /N /M "Would you prefer to continue without a license [Y] or quit and add a license to the above directory [N] "
  if errorlevel 2 (
      call :SafeExit
      exit /b 1
  )
  call :Log "INFO" 
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
REM Prompt the user to pick one and validate the choice

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
    call :ResetError
    goto :promptLicense
)

REM Attempting a numeric calculation on a non-number will set the errorlevel. Supposedly.
set /A dummy=!selection! >nul 2>&1
if errorlevel 1 (
    echo Invalid selection: "!selection!". Please enter a number.
    call :ResetError
    goto :promptLicense
)

REM Check if a license is defined for the given number.
if not defined license_!selection! (
    echo Invalid selection: "!selection!" is not among the listed options.
    call :ResetError
    goto :promptLicense
)

REM Retrieve the chosen license name.
REM for /f "delims=" %%L in ('echo !license_!selection!') do set "license_spdx=%%L"
call set "PH_license_spdx=!license_%selection%!"
REM for /f "delims=" %%L in ('cmd /V:ON /C "echo !license_!selection!!"') do set "license_spdx=%%L"
set "LICENSE_DEFINED=true"

:skipLicensePrompting
if "%PH_license_spdx%"=="NO_LICENSE" (
    call :Log "INFO" "License options declined, project will not be explicitly licensed."
    set "LICENSE_DEFINED="
) else (
    call :Log "INFO" "Project will be licensed under '!PH_license_spdx!'."
)

call :AddPlaceholder "license_spdx" "%PH_license_spdx%"


:: ====================================================================================================================
:: =========== Settings validation and confirmation
:: ====================================================================================================================


:is_ParentDir_OK

if not exist %PH_parent_dirPath% goto changeParent
echo.
call :Log "INFO" "The project directory will be created at: " "'%PH_parent_dirPath%\%PH_package%'" "Is this acceptable? [Y/N]"
echo.
choice /N
IF ERRORLEVEL 2 GOTO changeParent

:does_PackageDir_Exist
if exist "!PH_parent_dirPath!\!PH_package!" (
    set "selection="
    echo.
    call :Log "WARNING" "The package '!PH_package!' already exist in that parent directory."
    echo Would you like to:
    echo     1. Select a new package name.
    echo     2. Select a new parent directory.
    echo     3. Overwrite the package ^(WARNING -- The old package directory will be entirely deleted.^)
    echo     4. Quit the script entirely.
    echo.
    choice /C:1234 /N /M ">>>"
    set "selection=!ERRORLEVEL!"
    if "!selection!"=="1" goto changePackage
    if "!selection!"=="2" goto changeParent
    if "!selection!"=="3" goto delPackage
    if "!selection!"=="3" goto delPackage
    if "!selection!"=="4" goto SafeExit
    if defined ABORT_SCRIPT exit /b
) else (
    goto assignParentDir
)

:changePackage
echo.
call :PromptForInput package "Enter a new name for the package." "(Should be lower-case or snake-case.)"
call :AddPlaceholder "package" "!package!"
call :Log "INFO" "Package renamed to '!package!'." 
goto Does_PackageDir_Exist


:changeParent
echo.
echo Enter the absolute path to the PARENT directory into which the project directory will be created.
set /p "new_parent=>>> "
if not exist "!new_parent!" (
    mkdir "!new_parent!"
    call :Log "INFO" "A new directory has been created at '!new_parent!'."
)
set "PH_parent_dirPath=!new_parent!"
goto :Does_PackageDir_Exist


:delPackage
choice /M "To confirm, you would like to DELETE the ENTIRE current package directory tree rooted at '!PH_parent_dirPath!\!PH_package!' and create a new package directory in its place"
if ERRORLEVEL 2 goto Does_PackageDir_Exist
rmdir /s /q "!PH_parent_dirPath!\!PH_package!"
echo     ^> Old directory deleted.
goto assignParentDir



:assignParentDir
call :AddPlaceholder "parent_dirPath" "!PH_parent_dirPath!"
echo.
call :Log "INFO" "Project will be created in '!PH_parent_dirPath!'"


:settingsConfirmation
call :Log "INFO" "Please confirm the following settings:"
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    set "k=!PLACEHOLDER_KEY_%%N!"
    set "v=!PLACEHOLDER_VALUE_%%N!"
    echo     !k! = !v!
)
echo.
choice /N /M "Enter 'Y' to confirm and move to processing or 'N' to quit or rerun the script. "
if errorlevel 2 (
  choice /N /M "Would you like to re-run the script [Y] or quit to adjust externally [N]"
  if errorlevel 2 (
      call :SafeExit
      exit /b 1
  )
  goto startOfScript
)



:: ====================================================================================================================
:: =========== Begin generating project directory structure
:: ====================================================================================================================



:instantiatePixiDirectory
:: Create and enter project directory
set "PH_proj_root=!PH_parent_dirPath!\!PH_package!" 
echo.
call :Log "INFO" "Creating src-layout project directory in '%PH_proj_root%'."
pixi init "%PH_proj_root%" --format pyproject 
if errorlevel 1 (
  call :Log "ERROR" "FAILED TO GENERATE PIXI DIR AT '%PH_proj_root%'. Oops." "Exiting"
  pause
  exit /b 1
)
call :Log "INFO" "Project directory created successfully."
cd %PH_proj_root%
call :Log "debug1" "Current working directory set to '%PH_proj_root%'."
set "TOML_FILE=%PH_proj_root%\pyproject.toml"


:updateVersionFromToml
:: Get the initial version from the .toml file and set the variable.
for /f "tokens=2 delims== " %%A in ('findstr /r "^version *= *" %TOML_FILE%') do (
    set version=%%A
)
set PH_version=%version:"=%
call :AddPlaceholder "version" "%PH_version%"


:: Now that all the variables have been set, we'll write them out to a temporary file to use for string replacement.
:: The default placeholders that were loaded originally from 'placeholdes_default.env' will be written in, along with updated keys for those, along with any other keys that start with the 'license_spdx' prefix.

:generatePlaceholdersFile
echo.
call :Log "debug1" "Generating placeholders.config project file..."

if not exist "%PH_proj_root%\config" mkdir "%PH_proj_root%\config"

set "placeholders=%PH_proj_root%\config\placeholders.config"

(
    for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
        set "k=!PLACEHOLDER_KEY_%%N!"
        set "v=!PLACEHOLDER_VALUE_%%N!"
        echo !k!=!v!
    )
) > "%placeholders%"
if errorlevel 1 (
    call :Log "ERROR" "Failed to write placeholders file."
    choice /C:CQ /N /M "Would you like to continue without replacing placeholders [C] or quit [Q]?"
    if ERRORLEVEL 2 (
        call :SafeExit
        exit /b 1
    )
) else (
    call :Log "INFO" "Placeholders file written."
)


:initGit
:: Initialize Git === 
set "noGit="
<nul set /p="[INFO] Initializing git... "
git config --global core.safecrlf false
git init > nul
if errorlevel 1 (
    echo.
    call :Log "ERROR" "Git failed to initialize - continuing."
    set "noGit=true"
) else (
    echo success.
)



:: ====================================================================================================================
:: =========== Begin file copying and processing
:: ====================================================================================================================


call :SubsectionHeader

:: ===== Copy and process the license file
:copyLicense
if defined LICENSE_DEFINED (
  if "%DEBUG_LEVEL%"=="0" <nul set /p="[INFO] Adding license '%PH_license_spdx%' into project... "
  if %DEBUG_LEVEL% GTR 0 call :Log "INFO" "Adding license '%PH_license_spdx%' into project."
  call :ProcessTemplate "%CFG_license_dirPath%\license_%PH_license_spdx%.txt" "%PH_proj_root%\LICENSE.txt" "%PWSH_PATH%" "%CFG_script_prepend%" "" "%CFG_script_replacePlaceholders%" "%placeholders%" "%CFG_max_placeholder_depth%" %DEBUG_LEVEL%
  if "%DEBUG_LEVEL%"=="0" echo success
  if "%ERRORLEVEL%"=="1" (
    echo.
    call :Log "ERROR" "Failed to add license to the project ^(%ERR_STR%^)"
  )
) else (
  call :Log "INFO" "No license defined, project will not be explicitly licensed."
)

call :SubsectionHeader

:: Confirm proper boilerplate template exists, and if not, generate it.
:setupBoilerplate
set "boilerplate_name=%CFG_boilerplate_name:{license_spdx}=!PH_license_spdx!%"
set "boilerplate_txt_template=%CFG_boilerplatesDir%\%boilerplate_name%.txt.%CFG_templateExt%"
call :Log "debug1" "Setting up boilerplate" 
call :Log "debug2" "boilerplate template = '%boilerplate_txt_template%'"

if not exist "%CFG_boilerplatesDir%" (
  echo '%CFG_boilerplatesDir%' does not exist. Creating.
  mkdir "%CFG_boilerplatesDir%"
) else (call :Log "debug1" "boilerplatesDir exists.")

if not exist "%boilerplate_txt_template%" (
  call :Log "debug1" "boilerplate DOES NOT exist. Creating..."
  if not defined LICENSE_DEFINED (
    echo -- [ERROR] --
    echo No license was defined!
    choice /N /M "Enter [y] to continue with an empty boilerplate, or [n] to quit the script and possibly create your own boilerplate with the right naming convention."
    IF ERRORLEVEL 2 exit /b
    echo. > "%boilerplate_txt_template%"
  ) else (
    echo This file within package ^<%PH_package%^> is copyrighted by %PH_author% ^<%PH_email%^> as of %PH_year% under the %PH_license_spdx% license. > "%boilerplate_txt_template%"
  )
  call :Log "debug1" "Created boilerplate. Copying..."
) else (
  call :Log "debug1" "Boilerplate template exists. Copying..."
)

call :ProcessTemplate "%boilerplate_txt_template%" "%PH_proj_root%\config\%boilerplate_name%.txt" "%PWSH_PATH%" "%CFG_script_prepend%" "" "%CFG_script_replacePlaceholders%" "%placeholders%" "%CFG_max_placeholder_depth%" %DEBUG_LEVEL%

call :Log "INFO" "%PH_license_spdx% boilerplate file processed successfully."

REM pause

:: Loop over all the files within the template directory
:: Skip them if they're in the list of skipped files or folders.
:: If it needs boilerplate AND there's not an appropriately-commented boilerplate template, make one.
:: Process the template file into the new directory.
:templateProcessingLoop

REM Recursively loop through all files under the parent directory.
for /R "%CFG_templates_dirPath%" %%F in (*) do (

    set "filepath=%%F"
    set "filename=%%~nxF"
    set "skipFile="
    set "skipFolder="
    set "noBP="
    
    set "relPath=!filepath:%CFG_templates_dirPath%\=!"
    if %DEBUG_LEVEL% LSS 1 (
        <nul set /p="[INFO] Processing '!relPath!'... "
    ) else (
        call :SubsectionHeader
        call :Log "INFO" "Processing '!relPath!'..."
    )
    

    REM Check each excluded folder.
    for %%D in (%CFG_excludeFolders%) do (
        REM %%~D removes any surrounding quotes.
        REM This call uses string substitution to remove "\FolderName\" from the file path.
        call set "test=%%filepath:\%%~D\=%%%"
        if not "!test!"=="!filepath!" (
           set "skipFolder=yes"
        )
    )

    REM Check each excluded file.
    for %%E in (%CFG_excludeFiles%) do (
        REM %%~E removes surrounding quotes.
        if /I "%%~E"=="!filename!" (
            set "skipFile=yes"
        )
    )

    if defined skipFile (
        if "%DEBUG_LEVEL%"=="0" (
            echo SKIPPED
        ) else (
            echo "%TAB%SKIPPED - this filename is on the exclusions list.
        )
    )
    if defined skipFolder (
        if "%DEBUG_LEVEL%"=="0" (
            echo SKIPPED
        ) else (
            echo %TAB%SKIPPED - this file resides in an excluded folder
        )
    )
    if not defined skipFile if not defined skipFolder (
    
        REM First we do some fancy stripping to get the relative path
        REM set "relPath=!filepath:%CFG_templates_dirPath%\=!"
        REM call :Log "debug1" "Relative path: '!relPath!'"
        
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
        call :Log "debug1" "Destination filepath: '!destFile!'"
        
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
                call :Log "debug3" "NoBP: does ignore-file '%%I' match current file '!FilenameWithoutTemplateExt!'?"
                REM Compare file names (case-insensitive).
                if /I "%%I"=="!FilenameWithoutTemplateExt!" (
                    call :Log "debug1" "!FilenameWithoutTemplateExt! is on the 'No Boilerplates' list, so no boilerplate will be appended.
                    set "noBP=true"
                )
            )
        )
        
        REM If the file was NOT on the 'No Boilerplate' list, we need to determine the correct boilerplate file to use.
        if not defined noBP (

            call :Log "debug1" "Boilerplate identification..." 
            call :Log "debug2""Boilerplate_name: %boilerplate_name%" "BoilerplatesDir: %CFG_boilerplatesDir%" "boilerplate_txt_template: %boilerplate_txt_template%"

            REM 3.1: Identify the target file's filetype via its extension.
            REM set "strippedName=!filepath:.TEMPLATE=!"
            set "strippedName=!filepath:.%CFG_templateExt%=!"
            call :Log "debug2" "Stripped name: '!strippedName!'"
            for %%A in ("!strippedName!") do set "ext=%%~xA"
            call :Log "debug1" "Extracted extension: '!ext!'"
            
            REM 3.2 Check the boilerplates directory for an appropriately commented boilerplate file.
            if exist %CFG_boilerplatesDir%\%boilerplate_name%!ext!.%CFG_templateExt% (
              set "boilerplate=%CFG_boilerplatesDir%\%boilerplate_name%!ext!.%CFG_templateExt%"
              call :Log "debug1" "Boilerplate for '!ext!' exists."
            ) else (
                REM 3.3 Since the correctly-commented boilerplate file doesn't exist (at least, within the boilerplates directory), we'll have to make it.
                call :Log "debug1" "Boilerplate file for '!ext!' does not exist. Creating." "Should be '%CFG_boilerplatesDir%\%boilerplate_name%!ext!.%CFG_templateExt%'"
                
                REM 3.3.1 Define the path for the new boilerplate file
                set "boilerplate=%CFG_boilerplatesDir%\%boilerplate_name%!ext!.%CFG_templateExt%
                
                REM 3.3.2 Append the appropriate comment character(s) by using the '.txt' boilerplate template (which was created earlier so it exists).
                "%PWSH_PATH%" -NoProfile -File "%CFG_script_BPcommenting%" -TargetFile "%boilerplate_txt_template%" -Extension "!ext!" -OutputFile "!boilerplate!" -Debug_Level %DEBUG_LEVEL%
                
                call :Log "debug2" "Boilerplate file: '!boilerplate!'"
                echo.
                choice /M "Would you like to save this new boilerplate file for future use?"
                if errorlevel 2 set "DEL_BP=true"
            )
            
        ) else (
            REM If 'noBP' was defined, it means we're not passing a BP file.
            set boilerplate=
        
        )
        
        REM 4. Then process the template
        call :ProcessTemplate "!filepath!" "!destFile!" "%PWSH_PATH%" "%CFG_script_prepend%" "!boilerplate!" "%CFG_script_replacePlaceholders%" "%placeholders%" "%CFG_max_placeholder_depth%" %DEBUG_LEVEL%
        
        if defined DEL_BP (
          del "!boilerplate!"
          set "DEL_BP="
        )
        
        if %DEBUG_LEVEL% LSS 1 (
            echo success.
        ) else (
            call :Log "INFO" "Successfully processed to '%PH_package%\!relDest!'."
            echo.
        )
        call :ResetError
    )
)




:: ====================================================================================================================
:: =========== File cleanup
:: ====================================================================================================================

:renameRunFile
REM === Rename the copied batch script file ===
rename "runPythonScript.bat" "run_%PH_package%.bat"
if errorlevel 1 (
    call :Log "WARNING" "FAILED TO RENAME 'runPythonScript.bat'."
) else (
    call :Log "debug1" "runPythonScript.bat renamed to 'run_%PH_package%.bat'"
)


:: The default 'pyproject.toml' file needs some updating after all this setup work.
:modifyTomlFile

"%PWSH_PATH%" -NoProfile -File "%CFG_script_toml_insert%" -ConfigFile "%config_dirPath%\toml_insert.config" -Debug_Level %DEBUG_LEVEL%

"%PWSH_PATH%" -NoProfile -File "%CFG_script_toml_replace%" -ConfigFile "%config_dirPath%\toml_replace.config" -Debug_Level %DEBUG_LEVEL%

"%PWSH_PATH%" -NoProfile -File "%CFG_script_replacePlaceholders%" -InputFile "%TOML_FILE%" -OutputFile "%TOML_FILE%" -PlaceholdersFile "%placeholders%" -Debug_Level %DEBUG_LEVEL%


REM === Check if the [tool.setuptools] section exists, and append if not ===
findstr /C:"[tool.setuptools]" "%TOML_FILE%" >nul
if errorlevel 1 (
    REM No extra blank line needed; one exists at the end of the file already.
    echo [tool.setuptools]>> "%TOML_FILE%"
    echo package-dir = {"" = "src"}>> "%TOML_FILE%"
    call :Log "INFO" "'tools.setuptools' section added to 'pyproject.toml'."
) else (
    call :Log "debug1" "'tool.setuptools' section already exists in 'pyproject.toml'.
)


:: ====================================================================================================================
:: =========== Wrap-up
:: ====================================================================================================================

call :SubsectionHeader "Wrapping up"

if defined noGit goto skipGitHub

:gitCommit
git add .
git add --renormalize .
git commit -m "Initial project setup." >nul 2>&1
if errorlevel 1 (
    call :Log "ERROR" "Git commit failed"
    goto skipGitHub
)
git tag -a v%PH_version% -m "v%PH_version%: Initial release"
call :Log "INFO" "New project committed to git."

REM === Push to the repo ===
echo.
choice /M "Would you like to push to GitHub?"
REM call :Log "debug1" "ERRORLEVEL is %errorlevel%"
IF ERRORLEVEL 2 GOTO skipGitHub

call :Log "INFO" "Pushing to github"
gh repo create %PH_repo_name% --private --source=. --remote=origin
git branch -M main
git push -u origin main
git push origin v%PH_version%

:skipGitHub

:validate
if not defined VALIDATE goto scriptWrapup

:validateCheckPath
if not exist "%VALIDATE_BASELINE_DIR%" (
    call :Log "ERROR" "Validation path '%VALIDATE_BASELINE_DIR%' does not exist."
    choice /M "Would you like to set another"
    if ERRORLEVEL EQU 2 goto scriptWrapup
    call :PromptForInput VALIDATE_BASELINE_DIR "Please enter a new path to the root directory that you'd like to compare the generated directory with."
    goto validateCheckPath
) 
call :Log "INFO" "Checking generated structure against '%VALIDATE_BASELINE_DIR%'..."

"%PWSH_PATH%" -NoProfile -ExecutionPolicy Bypass -File "%CFG_scripts_dirPath%\Compare-FolderTreesAdvanced.ps1" -BaselineDirectory "%VALIDATE_BASELINE_DIR%" -GeneratedDirectory "%PH_proj_root%" -ExcludeFolderNames "" -ExcludeFileNames "" -PreviewStructure -DebugLevel %DEBUG_LEVEL%


:scriptWrapup
echo.
call :Log "INFO" "Project setup COMPLETE"
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

:endOfScript

:: Cleanup
REM del %placeholders%

goto :eof

:: ====================================================================================================================
:: ====================================================================================================================
:: ===========
:: ===========          SUBROUTINES (alphabetic order)
:: ===========
:: ====================================================================================================================
:: ====================================================================================================================

:: ====================================================================================================================
:: AddPlaceholder subroutine
:: Assigns the placeholder name and value to numbered variables, or updates the appropriate value if the key exists.
:: Parameters:
::      1. The key to be assigned.
::      2. The value to be mapped to the key.
:: Exit levels:
::  0 -> New key added.
::  1 -> Key overwritten
::  2 -> Error in 'for' loop, key not added.
:: ====================================================================================================================
:AddPlaceholder
set "key=%~1"
set "value=%~2"

call :Log "debug2" "In AddPlaceholder with key='%~1' and value='%~2'"
call :Log "debug2" "There are %PLACEHOLDER_COUNT% placeholders so far."

:: Check if key already exists
call :Log "debug3" "Checking for duplicate keys..."
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    call :Log "debug3" "Is '!PLACEHOLDER_KEY_%%N!' equal to '%key%'?"
    if "!PLACEHOLDER_KEY_%%N!"=="%key%" (
        call :Log "debug2" "Updating existing placeholder: '!PLACEHOLDER_KEY_%%N!' is now '%value%'."
        set "PLACEHOLDER_VALUE_%%N=%value%"
        exit /b 0
    )
)

:: Key was not found, add a new entry
call :Log "debug3" "Key %key% was not found in the placeholders set."
set /A PLACEHOLDER_COUNT+=1
set "PLACEHOLDER_KEY_!PLACEHOLDER_COUNT!=%key%"
set "PLACEHOLDER_VALUE_!PLACEHOLDER_COUNT!=%value%"
call :Log "debug2" "Added new placeholder: mapped '!key!' to '!value!'."
exit /b 0





:: ====================================================================================================================
:: CollectMissingInputs subroutine
:: Prompts for any required inputs not supplied via CLI/config.
:: Parameters: None
:: NOTE: I tried to subroutine this further by standardizing the conditional blocks but that was a rabbit hole of epic proportions due to the double expansion which never seems to work properly in batch. By "double expansion" I mean "pass a variable's name as an argument and then try to pull out the value for that variable". Trying the silly "call set" trick didn't work, nor did "%%%var%%%", so I have no idea how to do this. Anyway, this is all to say DON'T DO IT. Just leave that monster alone. Even thought the way this is done right now is kinda dumb.
:: ====================================================================================================================
:CollectMissingInputs
call :ResetError
echo.

call :Log "debug2" "In CollectMissingInputs"

set "MISSING_INPUTS=false"

if not defined CLI_package (
    call :Log "debug2" "CLI argument not provided for package; prompting."
    call :PromptForInput package "Enter a name for the package." "Should be lower-case or snake-case."
    call :AddPlaceholder "package" "!package!"
    call :Log "debug3" "package set to '!package!'." 
    set "MISSING_INPUTS=true"
) else (
    call :Log "debug2" "Package was already defined as '!package!', no prompt needed."
)


if not defined CLI_repo (
    call :Log "debug2" "CLI argument not provided for the repo_name; prompting."
    call :PromptForInput repo_name "Enter a name for the repo." "Should be lower-case or kebab-case."
    call :AddPlaceholder "repo_name" "!repo_name!"
    call :Log "debug3" "repo set to '!repo_name!'." 
    set "MISSING_INPUTS=true"
) else (
    call :Log "debug2" "Repo_name was already defined as '!repo_name!', no prompt needed."
)


if not defined CLI_desc (
    call :Log "debug2" "CLI argument not provided for description; prompting."
    call :PromptForInput description "Enter a description." "This should be one (1) sentence that tackles the 'what' and 'why' for this package." "This will be displayed in the .toml and the README." "[RESTRICTIONS]: No exclamation marks, percent signs, carets, ampersands, pipes, or angle brackets. The CLI really hates them."
    call :AddPlaceholder "description" "!description!"
    call :Log "debug3" "description set to '!description!'." 
    set "MISSING_INPUTS=true"
) else (
    call :Log "debug2" "A description was already provided as '!description!', no prompt needed."
)

REM Sort of a hacky way to check for additional prompts that may be needed.
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    if "!PLACEHOLDER_KEY_%%N!"=="author" (
        set AUTHOR_DEFINED=true
        set "auth_temp=!PLACEHOLDER_KEY_%%N!"
    )
    if "!PLACEHOLDER_KEY_%%N!"=="email" (
        set EMAIL_DEFINED=true
        set "email_temp=!PLACEHOLDER_KEY_%%N!"
    )
)

if not defined AUTHOR_DEFINED (
    call :Log "debug2" "CLI argument not provided for author; prompting."
    call :PromptForInput author "Enter a name for an author of this package."
    call :AddPlaceholder "author" "!author!"
    call :Log "debug3" "author set to '!author!'." 
    set "MISSING_INPUTS=true"
) else (
    call :Log "debug2" "Author was already defined as '!auth_temp!', no prompt needed."
)

if not defined EMAIL_DEFINED (
    call :Log "debug2" "CLI argument not provided for email; prompting."
    call :PromptForInput email "Enter a contact email address." "No validation is done here."
    call :AddPlaceholder "email" "!email!"
    call :Log "debug3" "email set to '!email!'." 
    set "MISSING_INPUTS=true"
) else (
    call :Log "debug2" "Email was already defined as '!email_temp!', no prompt needed."
)

if defined VALIDATE (
    if "%VALIDATE_BASELINE_DIR%"=="" (
        call :Log "debug2" "CLI flag for validate was passed but the baseline directory seems to be empty."
        call :PromptForInput VALIDATE_BASELINE_DIR "Enter the absolute path to the directory you'd like to compare the generated directory to." "No validation is done here."
        call :Log "debug3" "VALIDATE_BASELINE_DIR set to '!VALIDATE_BASELINE_DIR!'."
    ) else (
        call :Log "debug2" "Validation directory set to '%VALIDATE_BASELINE_DIR%'."
    )
)

call :Log "debug2" "End of CollectMissingInputs."

if "%MISSING_INPUTS%"=="true" (
    exit /b 1
) else (
    if "%MISSING_INPUTS%"=="false" (
        exit /b 0
    ) else (
        exit /b 2
    )
)
goto :eof





:: ====================================================================================================================
:: Copy_withMsg subroutine
:: Copies with a built-in error message.
:: Parameters: 
::      1: Source file
::      2: Destination file
:: ====================================================================================================================
:Copy_withMsg

set "SOURCE=%~1"
set "DEST=%~2"
set "TAB=   "

call :Log "debug2" "In 'copy_withMsg'" "Source: '%SOURCE%'" "Destination: '%DEST%'"

copy "%SOURCE%" "%DEST%" >nul
if "%errorlevel%"=="0" (
    call :Log "debug2" "%TAB%Successfully copied '%SOURCE%' to '%DEST%'."
) else (
    call :Log "ERROR" "%TAB%FAILED TO COPY '%SOURCE%' to '%DEST%'. Continuing."
)
goto :eof





:: ====================================================================================================================
:: ExportPlaceholders subroutine
:: Exports the placeholders to environment variables with a 'PH_' prefix.
:: For instance, after calling this, %PH_package% will contain the current package name.
:: ====================================================================================================================
:ExportPlaceholders
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    set "k=!PLACEHOLDER_KEY_%%N!"
    set "v=!PLACEHOLDER_VALUE_%%N!"
    call set "PH_%%k%%=!v!"
)
goto :eof





:: ====================================================================================================================
:: Linebreak subroutine
:: Prints a single line of a character string, the length of which is equal to the width of the console.
:: PowerShell is used to accomplish this.
:: Parameters:
::      1. The character(s) to use for the line.
:: Notes:
::      1. If 'COLS' is not defined externally, it will be assigned within the script, either by PowerShell if available, or set to a default of 80. If this subroutine is being run frequently, it's likely worthwhile to assign COLS externally since the PS script takes a second to run.
:: ====================================================================================================================
:Linebreak
rem -------------------------------------------------
rem Prints a horizontal line made up of the passed character in %1,
rem the length of which equals the width of this console.
rem Uses PowerShell to retrieve the window width.
rem -------------------------------------------------

set "str=%~1"
set "len=0"

:CountLoop
if not "%str%"=="" (
    set "str=%str:~1%"
    set /a "len+=1"
    goto CountLoop
)

if "%LINECHAR%"=="" (
    set "LINECHAR=-"
) else (
    set "LINECHAR=%~1"
)

if not defined COLS (
    REM Check for PowerShell
    where powershell >nul 2>&1
    if errorlevel 1 (
        set "COLS=80"
        goto :colsSet
    )
    for /f "usebackq delims=" %%A in (
      `powershell -NoProfile -Command "$Host.UI.RawUI.WindowSize.Width"`
    ) do set "COLS=%%A"
)

:colsSet

set /a numCols=%COLS%/%len%

set "line="
for /L %%i in (1,1,%numCols%) do (
    set "line=!line!!LINECHAR!"
)
echo !line!

goto :EOF





:: ====================================================================================================================
:: Log subroutine
::
:: Standardized console-printing method with various built-in severity levels and debug-level validation.
::
:: Parameters:
::      1: The severity. This should be 'INFO', 'WARNING', 'ERROR', or 'DEBUG<LEVEL>', but technically it could be anything (within reason, giving the limitations of Batch). The <LEVEL> here would be 1, 2, 3, or 4, and corresponds to the level of the global variable DEBUG_LEVEL at or above which the statement prints.
::      2... %N: Any number of strings. These will be printed in order, each on it's own line. The first line will get the severity indicator, subsequent lines will be indent.
::
:: Usage: 
::      call :Log "INFO" "This is some information."
::      call :Log "debug2" "This will print only if DEBUG_LEVEL is greater than or equal to 2."
::
:: Notes:
::      I originally wanted to write wrappers for this functionality (e.g. 'warn', or 'info') and make this into an internal helper function. The issue is that passing an arbitrary number of arguments from 'info' to 'log' would have been fragile. The "obvious" way to do is to call, from within 'info', 'call :Log "INFO" %*', where the '%*' would pass all the subsequent arguments. The issue is that this notation doesn't work within certain contexts (e.g. loops or other blocks wih extra parsing) and 'DelayedExpansion' interferes with it. There is way to avoid it - you loop over all the passed arguments to build a single string and pass that - but that kind of defeats the purpose of the wrapper since each of the wrappers would need this nearly-identical code. So instead, it's preferred here to use a single method that's a bit more flexible at the expense of an extra subroutine parameter.
:: All this is to say, don't try breaking this up into wrappers. 
:: ====================================================================================================================

:Log
REM call :Log "debug4" "Inside the 'log' subroutine."
if "%DEBUG_LEVEL%"=="4" echo In 'log'
set "debugging="

set "severity=%~1"
if "%DEBUG_LEVEL%"=="4" echo Severity is '%severity%'.
REM call :Log "debug4" "Severity set to '%~1'."
shift

if /I "!severity:~0,5!"=="debug" (

    if "%DEBUG_LEVEL%"=="4" echo I think we are debugging.

    REM Extract the 6th character (i.e. at index 5)
    set "level=!severity:~5,1!"
    if "y%DEBUG_LEVEL%"=="4" echo The level is set to !level!.
    
    REM If global debugging is off, exit.
    if "!DEBUG_LEVEL!"=="0" (
        REM echo Whoops, debugging is currently disabled.
        REM exit /b 1
        goto :eof
    )
    
    REM If the level is above the global debug level, exit. 
    REM (We only print debugging statements at levels BELOW the set debug level.)
    if "!level!" gtr "!DEBUG_LEVEL!" (
        REM echo Whoops, the level of this call is higher than the set debug level. 
        REM exit /b 1
        goto :eof
    )
    
    set "severity=DEBUG"
    if "%DEBUG_LEVEL%"=="4" echo Severity has been reset to '!severity!'.
)

if /I "%severity%"=="ERROR" (
  call :Log "debug4" "This will send messages to stderr."
)


REM Print first argument on same line as severity.
REM Subsequent arguments will be on intended unlabeled lines.

set "msg=%~1"
if "%DEBUG_LEVEL%"=="4" echo First msg: '!msg!'
if /I "%severity%"=="ERROR" (
  echo.
  echo --[ERROR]-- %msg%1>&2
) else (
    if "%severity%"=="WARNING" (
      echo.
      echo -[WARNING]- %msg%
    ) else (
        echo [%severity%] %msg%
    )
)
shift

:log_loop
if "%~1"=="" goto log_done
REM call :Log "debug4" "Next argument: '%~1'"

set "msg=%~1"
if "%DEBUG_LEVEL%"=="4" echo Next message: '!msg!'
if /I "%severity%"=="ERROR" (
  echo     !msg! 1>&2
) else (
  echo     !msg!
)
shift
goto log_loop


:log_done
REM Basic example: errors go to stderr.
REM call :Log "debug4" "End of 'log' subroutine - no more arguements."
REM echo And that was the end of 'log'. 
goto :eof





:: ====================================================================================================================
:: LoadPlaceholders subroutine
:: Reads key=value pairs from a file and passes them to 'AddPlaceholder' for proper assignment.
:: Parameters:
::      1. The full path to the file to read.
:: ====================================================================================================================
:LoadPlaceholders
if not exist "%~1" exit /b 1
for /F "usebackq tokens=1* delims==" %%A in ("%~1") do (
    if not "%%A"=="" (
        set "lineKey=%%A"
        if not "!lineKey:~0,1!"=="#" (
            call :AddPlaceholder "%%A" "%%B"
        )
    )
)
exit /b 0





:: ====================================================================================================================
:: ParseArguments subroutine
:: Processes CLI parameters in the form "--key=value" or "key=value".
:: Invalidly structured parameters are skipped.
:: Valid keys are handled explicitly or passed to 'AddPlaceholder' for storing or updating.
:: Certain keys also trigger flag-setting for later validation.
:: Parameters:
::      1. The list of parameters to parse. Normally this would be '%*' (unquoted), but could be any space-separated list, I think (though this is untested). 
:: Note: CLI overrides previous settings.
:: Usage: call :ParseArguments %*
:: ====================================================================================================================
:ParseArguments
call :ResetError
call :Log "debug2" "In ParseArguments"

:parseArgsLoop
call :Log "debug3" "At the top of the 'ParseArgsLoop'"
if "%~1"=="" goto EndParseArgs

set "arg=%~1"
call :Log "debug2" "Arg = !arg!"

:: Remove leading '--' or '-' if present
if "!arg:~0,2!"=="--" set "arg=!arg:~2!"
if "!arg:~0,1!"=="-" set "arg=!arg:~1!"

REM Check for the 'debug' flag.
REM This would usually be set to a specific level using a 'key=val' pair, but if not, we should catch it.
REM Since any 'debug' flag should be taken care of early in the script, we actually just skip over it. 
if /I "!arg:~0,5!"=="debug" (
    call :Log "debug2" "Param identified as 'debug', identified and set earlier in the script but not removed from the parameters list because that's tricky. Skipping."
    shift
    goto ParseArgsLoop
)


REM At this point, we'll check for an '=' sign and loop if we don't see it.
if "!arg!"=="!arg:=!" (
    call :Log "debug2" "Error: Parameter '!arg!' does not contain an '=' sign."
    REM You might choose to skip or exit with an error here.
    shift
    goto ParseArgsLoop
)


:: Split at '=' to extract key (param) and value (val)
for /F "tokens=1,* delims==" %%A in ("!arg!") do (
    set "param=%%A"
    set "val=%%B"
    call :Log "debug3" "Arg parsed as '!param!' and '!val!'."
)


REM If the parameter is empty, shift and loop.
if "!param!"=="" (
    call :Log "debug2" "Error: Parameter could not be parsed correctly from '!arg!'."
    shift
    goto ParseArgsLoop
)

REM Check for the 'validate' flag. It's not a placeholder, so we do this before that.
if /I "!arg!"=="validate" (
    set "VALIDATE=true"
    set "VALIDATE_BASELINE_DIR=!val!"
    shift
    goto ParseArgsLoop
)


REM I check for known parameters first, and then highlight unknown ones.
REM "Known" here is based from the keys that we've seen from the placeholders files.
if not defined PLACEHOLDER_COUNT (
    call :Log "WARNING" "The 'PLACEHOLDER_COUNT' variable hasn't been defined for some reason?" "This is more of a debugging message, but also, it should absolutely have been defined already, so it might be concerning for the functionality of the script. "
    goto addParam
)


if "%PLACEHOLDER_COUNT%"=="0" (
    call :Log "debug2" "No placeholders have been defined, so these are all new."
    goto addParam
)


REM These lines allow for spelling variations.
if /I "!param!"=="license-spdx" set "param=license_spdx"
if /I "!param!"=="license-name" set "param=license_spdx"
if /I "!param!"=="project-name" set "param=project_name"
if /I "!param!"=="proj_name" set "param=project_name"
if /I "!param!"=="proj-name" set "param=project_name"
if /I "!param!"=="proj-root" set "param=proj_root"
if /I "!param!"=="project_root" set "param=proj_root"
if /I "!param!"=="project-root" set "param=proj_root"
if /I "!param!"=="repo-name" set "param=repo_name"
if /I "!param!"=="parent-dirPath" set "param=parent_dirPath"


set "found="
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    if not defined found (
        if "!PLACEHOLDER_KEY_%%N!"=="!param!" (
            set "found=true"
        )
    )
)


if not defined found (
    call :Log "WARNING" "Unknown placeholder '!param!' with value '!val!' is being passed over CLI." "The placeholder will be set, but just so you know, it's not one of the previously-defined keys."
    goto addParam
)


REM These are known parameters that need additional handling.
if /I "!param!"=="package" set "CLI_package=1"
if /I "!param!"=="author" set "AUTHOR_DEFINED=1"
if /I "!param!"=="email" set "EMAIL_DEFINED=1"
if /I "!param!"=="license_spdx" set "LICENSE_DEFINED=1"
if /I "!param!"=="description" set "CLI_desc=1"
if /I "!param!"=="repo_name" set "CLI_repo=1"

call :Log "debug3" "'!param!', a known placeholder, seen via CLI."  


REM All parameters that are passed are added to the Placeholders "list" for later processing.
REM These will be accessible later as well via 'PH_%param%'. 
:addParam
call :AddPlaceholder "%param%" "%val%"
shift
goto ParseArgsLoop

:endParseArgs
call :Log "debug2" "End of 'ParseArgsLoop' - no more arguments."
goto :eof





:: =======================================================================================================================================
:: ProcessTemplate subroutine
:: Handles the processing of the various templates: copies, appends any boilerplate, and then replaces placeholders.
:: Parameters:
::    1 = Source file (i.e. the template)
::    2 = Destination file (the full path plus new filename)
::    3 = Path to the PowerShell instance you'll use (e.g. PS5.1, PS7, etc.)
::    4 = Path to the PS script for prepending boilerplate text.
::    5 = Path to boilerplate text file. 
::      NOTE: This must be a single file (Batch-lists don't pass to PS well). Put the file together outside this method.
::    6 = Path to the PS script for placeholder replacement.
::    7 = Path to the file that details the placeholders and their replacements.
::    8 = Path to the script for commenting the boilerplate
::    9 = Debugging level for this script (will be passed to PS scripts as well.)
:: ====================================================================================================================================== 

:: Function for copying and filling from template
:ProcessTemplate


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
set /a NEXT_DEBUG_LEVEL = _DEBUG_LEVEL + 1
REM set "COMMENT_BP_SCRIPT=%~8"

REM First, a debug-printing step.
call :Log "debug1" "In 'ProcessTemplate' subroutine" 
call :Log "debug2" "Parameters:" "Source: '%SOURCE%'" "Destination: '%DEST%'" "Prepend script path: '%PREPEND_SCRIPT%'" "Boilerplate filepath: '%BOILERPLATE%'" "Replacement script path: '%REPLACEMENT_SCRIPT%'" "Placeholders filepath: '%PLACEHOLDERS%'" "Max placeholder depth: '%MAX_PLACEHOLDER_DEPTH%'" "Debug level: '%_DEBUG_LEVEL%'"


REM Second, we copy the source file (the template) into the new destination.
call :Log "debug1" "Copying..."
call :Copy_withMsg "%SOURCE%" "%DEST%"

REM :prepending
call :Log "debug1" "Prepending..."
if "%BOILERPLATE%"=="" (
  call :Log "debug1" "Nothing to prepend - continuing"
) else (
    "%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%PREPEND_SCRIPT%" "%DEST%" "%BOILERPLATE%" -DEBUG_LEVEL "%_DEBUG_LEVEL%"
    call :Log "debug1" "Prepend successful."
)


REM Finally, we call the placeholder-replacement script to replace all the placeholders.
call :Log "debug1" "Running replacement script..."
"%PWSH%" -NoProfile -File "%REPLACEMENT_SCRIPT%" -InputFile "%DEST%" -OutputFile "%DEST%" -PlaceholdersFile "%PLACEHOLDERS%" -MaxIterations "%CFG_max_placeholder_depth%" -DEBUG_LEVEL "%_DEBUG_LEVEL%"
call :Log "debug1" "Replacements successful. "

call :Log "debug1" "End of 'ProcessTemplate' subroutine."

endlocal
goto :eof




:: ====================================================================================================================
:: PromptForInput subroutine
:: Prompts the user for input with a custom message and confirms the input.
:: Parameters:
::      1. The name of the variable to place the input value into.
::      2...N: The prompt messages to display, one per line, indented after the first.
:: Usage:
::      call :PromptForInput package "Enter a new name for the package." "(Should be lower-case or snake-case.)"
:: ====================================================================================================================
:PromptForInput
setlocal EnableDelayedExpansion

set "varName=%~1"
call :Log "debug3" "VarName = %varName%"
shift
echo.

if "%~1"=="" (
    call :Log "debug1" "Second argument was empty, using default prompt string."
    echo Enter a value for !varName!.
    goto InputPrompt
)

set "TAB="
:inputLoop
set "msg=%~1"
echo !TAB!!msg!
set "TAB=    "
shift
if "%~1"=="" goto InputPrompt
call :Log "debug3" "Third argument was NOT empty, looping."
goto InputLoop

:inputPrompt
call :Log "debug3" "End of arguments; prompting."
echo.
set /p "temp=    >>> "
echo.
echo You entered: "!temp!".
REM set /p "confirm=Is this correct? (Y/N): "
REM if /I "!confirm!" neq "Y" (
choice /M "Is this correct "
if errorlevel 2 (
    echo Let's try again...
    set "temp="
    goto InputPrompt
) else (
    call :Log "debug3" "Confirmed"
)
(
    endlocal
    rem Use a block to pass the value back. The variable name is provided in %~1.
    set "%varName%=%temp%"
)
goto :EOF





:: ====================================================================================================================
:: ResetError subroutine
:: Just resets the errorlevel to zero.
:: Parameters: None.
:: ====================================================================================================================
:ResetError
exit /b 0





:: ====================================================================================================================
:: SafeExit subroutine
:: Exits in a standard way with standard console message structure and a custom message (if needed)
:: Parameters:
::      1...N: Strings to be printed, in order, with an '[EXITING]' tag.
:: ====================================================================================================================
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




:: ====================================================================================================================
:: SectionHeader routine
:: Prints a standardized block for a section heading: two linebreaks, a blank line, text, a blank line, then two more linebreaks.
:: Parameters:
::      1...N: Strings to be printed within the section header block.
:: ====================================================================================================================
:SectionHeader
echo.
call :Linebreak "="
call :Linebreak "="
echo.
:sh_loop
if "%~1"=="" goto SH_end
echo %~1
shift
goto SH_loop
:sh_end
echo.
call :Linebreak "="
call :Linebreak "="
echo.

goto :eof





:: ====================================================================================================================
:: SubsectionHeader subroutine
:: Prints a standardized block for a subsection heading: a linebreak, a blank line, text, a blank line, then another linebreak.
:: Parameters:
::      1...N: Strings to be printed within the subsection header block.
:: ====================================================================================================================
:SubsectionHeader
:: Takes in an arbitrary number of strings.
echo.
call :Linebreak "-"
echo.
:ssh_loop
if "%~1"=="" goto SSH_end
echo %~1
shift
goto SSH_loop
:ssh_end
echo.
call :Linebreak "-"
echo.
goto :eof



:: ====================================================================================================================
:: WaitForEnter subroutine
:: Displays a custom pause message, which also allows the user to safely quit.
:: Parameters:
::      1. The message to display.
:: Note:
::      - The 'set /p dummy=""' forces the prior line to print first before a prompt, which enforces how the output looks.
:: ====================================================================================================================

:WaitForEnter
echo.
<nul set /p "=Press 'Enter' to %~1, or 'Q' to quit."
set /p dummy=""
if /I "%dummy%"=="q" call :SafeExit
if defined ABORT_SCRIPT exit /b 1

call :Linebreak

echo.
exit /b 0