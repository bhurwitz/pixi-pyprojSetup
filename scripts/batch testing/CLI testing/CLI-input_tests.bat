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
REM set "DEBUG=true"
set MAX_DEBUG=4

REM :: Set default if not provided
if not defined DEBUG_LEVEL (
  set "DEBUG_LEVEL=0"
) else (
    if !DEBUG_LEVEL! LSS 1 (
        set DEBUG_LEVEL=0
    ) 
    if !DEBUG_LEVEL! GTR %MAX_DEBUG% (
        set DEBUG_LEVEL=%MAX_DEBUG%
    )
)


REM :: Process CLI first so it overrides any existing environment variable
REM call :ParseArguments %*

REM :: Debug confirmation
if "!DEBUG_LEVEL!" lss "0" (
    set DEBUG_LEVEL=0
    call :log "STATUS" "Debugging is DISABLED."
)
if "!DEBUG_LEVEL!" gtr "%MAX_DEBUG%" (
    set DEBUG_LEVEL=%MAX_DEBUG%
)

call :debug !DEBUG_LEVEL! "Using Debug Level: !DEBUG_LEVEL!"



:: ============================================================================
::
:: MAIN SCRIPT
::
:: ============================================================================


:: ==========================================================
:: Setup testing environment and configuration files
:: ==========================================================

echo.
echo --- Setting up testing environment ---
echo.

call :debug 1 "Working out of '%CD%'."

:: --- Setup configuration folder ---
set "config_dirPath=%CD%\config"
if not exist "%config_dirPath%" (
    call :log "INFO" "Config directory does not exist. Creating."
    mkdir "%config_dirPath%"
) else (
    call :log "INFO" "Will use existing config directory."
)

:: --- Create placeholders.DEFAULT file (if missing) ---
if not exist "%config_dirPath%\placeholders.DEFAULT" (
    call :log "INFO" "Creating default placeholders file."
    (
      echo author=Default Author
      echo email=default@example.com
      echo parent_dirPath=C:\Default\ParentDir
      echo package=defaultpackage
      echo repo_name=defaultrepo
      echo description=Default project description goes here
      echo license-spdx=GPLv3
    ) > "%config_dirPath%\placeholders.DEFAULT"
) else (
    call :log "INFO" "Will use existing 'placeholders.DEFAULT' default placeholders file from the config directory."
)

:: --- Create placeholders.user file (optional override) ---
if not exist "%config_dirPath%\placeholders.user" (
    call :log "INFO" "Creating user placeholder file."
    (
       echo email=useroverride@example.com
       echo repo_name=user_repo_override
    ) > "%config_dirPath%\placeholders.user"
) else (
    call :log "INFO" "Will use existing 'placeholders.user' user placeholders file from the config directory."
)

:: --- Create pixi_pyprojSetup_config.cmd file ---
if not exist "%config_dirPath%\pixi_pyprojSetup_config.cmd" (
    call :log "INFO" "Creating pixi_pyprojSetup_config.cmd file."
    (
       echo @echo off
       echo set "templates_dirPath=%CD%\templates"
    ) > "%config_dirPath%\pixi_pyprojSetup_config.cmd"
) else (
    call :log "INFO" "Will use existing 'pixi_pyprojSetup_config.cmd' config file from the config directory."
)

:: --- Create dummy templates folder (if needed) ---
if not exist "%CD%\templates" (
    call :log "INFO" "Creating dummy templates folder."
    mkdir "%CD%\templates"
) else (
    call :log "INFO" "Will use existing dummy 'templates' folder."
)



:: ==========================================================
:: Parameter processing
:: ==========================================================

echo.
echo.
echo --- Starting placeholder and config processing ---
echo.

:: --- 1. Load General Configuration Defaults ---
REM THESE ARE IMMUTABLE AND SHOULD NOT BE CHANGED.
call :debug 1 "Loading the config file next."
call "%config_dirPath%\pixi_pyprojSetup_config.cmd"
call :log "INFO" "Config file loaded."

set PLACEHOLDER_COUNT=0

:: --- 2. Load Default Placeholder Values ---
call :LoadPlaceholders "%config_dirPath%\placeholders.DEFAULT"
call :log "INFO" "Default placeholders loaded."

:: --- 3. Override with User Placeholder Config ---
call :debug 1 "Reading from '%config_dirPath%\placeholders.user'."
call :LoadPlaceholders "%config_dirPath%\placeholders.user"
call :log "INFO" "User's placeholder file loaded."


:: --- 4. Process CLI Parameters (highest priority) ---
call :debug 1 "Parsing arguments..."
call :ParseArguments %*
call :log "INFO" "Arguments parsed successfully."

:: --- 5. Consolidate and Debug (Collect additional user input if missing) ---
call :debug 1 "Collecting missing inputs..."
call :CollectMissingInputs
call :log "INFO" "Completed collecting missing inputs."

REM Export placeholders to environment variables for easier retrieval later.
call :ExportPlaceholders

echo.

(
    for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
        set "k=!PLACEHOLDER_KEY_%%N!"
        set "v=!PLACEHOLDER_VALUE_%%N!"
        echo !k!=!v!
    )
) > "%config_dirPath%\placeholders.updated"


echo.
call :log "INFO" "Updated placeholders file:"
type "%config_dirPath%\placeholders.updated"

echo.
echo Package is %package%. Demos that the placeholders were written out to the environment.
echo.
echo --- Processing Complete ---
pause
endlocal
goto :eof



:: ============================================================================
::
:: SUBROUTINES
::
:: ============================================================================



:: ==========================================================
:: Centralized Error Handling
:: ==========================================================
:ErrorExit
call :log "ERROR" "%~1"
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
echo [DEBUG] %~1
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
  call :debug 4 "This is NOT an error (it was '%everity%'), so will print normally."
)
shift

setlocal EnableDelayedExpansion

:log_loop
if "%~1"=="" goto log_print
call :debug 4 "Next argument: '%~1'"
REM set "msg=!msg! %~1"
REM call :debug 4 "Message is now: '!msg!'"
REM shift
REM goto log_loop

set "msg=%~1"
if /I "%severity%"=="ERROR" (
  echo [%severity%] !msg! 1>&2
) else (
  echo [%severity%] !msg!
)
shift
goto log_loop


:log_print
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
            call :AddPlaceholders "%%A" "%%B"
        )
    )
)
goto :eof



:: ==========================================================
:: AddPlaceholder Subroutine
:: Adds a key to the PLACEHOLDERS list if not already present.
:: Usage: call :AddPlaceholder "key"
:: ==========================================================
:AddPlaceholders
set "key=%~1"
set "value=%~2"

call :debug 2 "In AddPlaceholders with key=%~1 and value=%~2"
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
    call :debug 3 "Param identified as 'debug', setting as !val!."
    set "DEBUG_LEVEL=!val!"
    shift 
    goto ParseArgsLoop
)

if /I "!arg!"=="repo-sameAs-package" (
    call :debug 3 "Arg is '--repo-sameAs-package'."
    set "REPO_SAME_AS_PACKAGE=true"
    shift
    goto ParseArgsLoop
)

if /I "%param%"=="package" set "CLI_package=1"
if /I "%param%"=="repo_name"  set "CLI_repo=1"
if /I "%param%"=="description" set "CLI_desc=1"
call :AddPlaceholders "%param%" "%val%"


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

if not defined CLI_package (
  call :debug 2 "CLI argument not provided for package; prompting."
  echo.
  echo Enter a name for the package ^(should be lowercase or snake-case^).
  set /p "package=>>> "
  REM call :AddPlaceholder "package"
  call :AddPlaceholders "package" "%package%"
  set "PACKAGE_DEFINED=true"
  call :debug 3 "package set to '!package!'."
) else (
    call :debug 2 "Package was already defined, no prompt needed."
)

REM if "!REPO_SAME_AS_PACKAGE!"=="true" (
  REM call :debug 2 "The '--repo-sameAs-package' flag was passed. Naming the repo '%package%'."
  REM set "repo_name=%package%"
  REM REM call :AddPlaceholder "repo_name"
  REM call :AddPlaceholders "repo_name" "%package%"
  REM set "REPO_DEFINED=true"
REM ) else (
    REM call :debug 2 "REPO_SAME_AS_PACKAGE was NOT defined."
REM )

if not defined CLI_repo (
  call :debug 2 "CLI argument not provided for repo; prompting."
  echo.
  echo Enter a name for the git repo ^(should be lowercase or kebab-case^).
  set /p "repo_name=>>> "
  REM call :AddPlaceholder "repo_name"
  call :AddPlaceholders "repo_name" "%repo_name%"
  set "REPO_DEFINED=true"
  call :debug 3 "Repo name set to '!repo_name!'."
) else (
    call :debug 2 "Repo was already defined, no prompt needed."
)

if not defined CLI_desc (
  call :debug 2 "CLI argument not provided for description; prompting."
  echo.
  echo Enter a short project description ^(max 1 sentence^).
  set /p "description=>>> "
  call :AddPlaceholders "description" "%description%"
  REM call :AddPlaceholder "description"
  call :debug 3 "description set to '!description!'."
) else (
    call :debug 2 "Description was already defined, no prompt needed."
)

call :debug 2 "End of CollectMissingInputs."
goto :eof


:: ==========================================================
:: This subroutine exports the placeholders to environment variables.
:: For instance, after calling this, %package% will contain the finalized package name.
:: ==========================================================
:ExportPlaceholders
for /L %%N in (1,1,%PLACEHOLDER_COUNT%) do (
    set "k=!PLACEHOLDER_KEY_%%N!"
    set "v=!PLACEHOLDER_VALUE_%%N!"
    call set "%%k%%=!v!"
)
goto :eof