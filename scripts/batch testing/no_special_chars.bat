@echo off
setlocal EnableDelayedExpansion

:: Characters that are considered problematic
set "problematicChars=|&<>\;@$"

:: Initialize flag
set "has_problem=false"

:: Main program
:main
:: Prompt for user input
set "input_string="
set /p "input_string=Enter a description with no special characters (|, &, <, >, ;, $, @): "

:: Check if input contains problematic characters
call :check_for_problematic_chars

:: If problematic characters are found, prompt again
if "!has_problem!"=="true" (
    echo [ERROR] The input contains problematic characters.
    goto :main
)

:: If the input is valid, proceed
echo You entered a valid description: !input_string!
goto :eof


:: Function to check for problematic characters
:check_for_problematic_chars
setlocal EnableDelayedExpansion

:: Check if the input string contains any problematic characters
for /f "delims=" %%A in ("!input_string!") do (
    for /f "delims=" %%B in ("!problematicChars!") do (
        echo %%A | findstr /c:"%%B" >nul
        echo %%A
        if "!errorlevel!"=="0" (
            set "has_problem=true"
            echo Problematic
        ) else (
            echo Not a problem.
        )
    )
)

endlocal & set "has_problem=%has_problem%"
goto :eof