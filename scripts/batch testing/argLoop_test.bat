@echo off
setlocal enabledelayedexpansion

rem Initialize variables
set "DEBUG_LEVEL="

echo.

set "ALLARGS=%*"
echo ALLARGS: %ALLARGS%

echo.
echo.

echo Processing arguments without shifting...
for %%A in (%*) do (
    echo Processing argument: %%A
    set "curr=%%~A"
    echo Stripped of quotes hopefully: !curr!
    REM Split the argument at the first '='
    for /F "tokens=1,2 delims==" %%B in ("!curr!") do (
         echo  Key: "%%B"  Value: "%%C"
         if /I "%%B"=="debug" (
             set "DEBUG_LEVEL=%%C"
         )
    )
)

echo.
echo Debug Level after for loop: %DEBUG_LEVEL%
echo.
echo When ready, press enter to move to goto+shift method.
pause
echo.
echo.

set DEBUG_LEVEL=0

:ParseArgsLoop
echo At the top of the 'ParseArgsLoop'
if "%~1"=="" goto EndParseArgs

set "arg=%~1"
echo Arg = !arg!

:: Remove leading '--' if present
if "!arg:~0,2!"=="--" set "arg=!arg:~2!"
echo Arg after double-dash removal if appropriate: !arg!

:: Split at '=' to extract key (param) and value (val)
for /F "tokens=1,* delims==" %%A in ("!arg!") do (
    set "param=%%A"
    set "val=%%B"
    echo Arg parsed as '!param!' and '!val!'.
)

:: Check for known parameters and update variables accordingly.
if /I "!param!"=="debug" (
    echo Param identified as 'debug', setting as !val!.
    set "DEBUG_LEVEL=!val!"
    shift 
    goto ParseArgsLoop
)

shift
goto ParseArgsLoop
:EndParseArgs

rem Display extracted values
echo Debug Level after goto+shift method: %DEBUG_LEVEL%

endlocal
pause
