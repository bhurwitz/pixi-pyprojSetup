:: string_replacement_test.bat
::
:: Automates string replacement based on KEY=VALUE pairs in the associated .env file
::

@echo off

REM Set working directory to the batch file’s directory (optional but useful)
cd /d "%~dp0"

set "placeholderDefaults_FILE=string_replacement_test_defaults.env"
set "placeholders_TEMP=string_replacements_test_TEMP.env"

REM Loads default values from external env file
REM Note that the prefix is only temporarily appended and should NOT be added manually within the 'placeholders.env' file.
for /f "usebackq tokens=1* delims==" %%A in ("%placeholderDefaults_FILE%") do (
    set "MY_%%A=%%B"
)
echo Default values loaded.
echo.

REM --- Read user input for one of the variables (if needed) ---
REM For example, update the description with user input.
REM echo Default description is currently: %MY_description%
REM setlocal DisableDelayedExpansion
REM set /p "TMP_DESC=Enter a description: "
REM REM (
    REM REM echo %TMP_DESC%
REM REM ) > temp_input.txt 
REM REM endlocal
REM REM for /f "usebackq delims=" %%a in ("temp_input.txt") do set "MY_description=%%a"
REM endlocal & call set "MY_description=%%TMP_DESC%%"
REM endlocal & call set "MY_description=%TMP_DESC%"
REM call :GetDescription MY_description

REM echo WScript.Echo InputBox^("Enter a description:", "Description Input"^)> prompt.vbs

REM for /f "usebackq delims=" %%A in (`cscript //nologo prompt.vbs`) do set "MY_description=%%A"


setlocal DisableDelayedExpansion
set /p "TMP_DESC=Enter a description: "
endlocal & set "MY_description=%TMP_DESC%"


REM echo Updated description is: %MY_description%
REM pause
REM del temp_input.txt

REM --- Write the MY_description value reliably to a temporary file using a VBScript helper.
REM (
    REM echo Set objArgs = WScript.Arguments
    REM echo CreateObject^("Scripting.FileSystemObject"^).CreateTextFile^("temp_input.txt", True^).Write objArgs^(0^)
REM ) > write.vbs

REM REM Call the VBScript passing the description.
REM cscript //nologo write.vbs "%MY_description%"

REM pause

REM REM Now, read back the file content into MY_description.
REM for /f "usebackq delims=" %%A in ("temp_input.txt") do set "MY_description=%%A"

REM pause

REM REM Clean up the temporary files.
REM del write.vbs
REM del temp_input.txt


REM --- Define other variables ---
REM If these are also provided interactively, you could do similar set /p prompts.
set "MY_package=testpack"
set "MY_author=BCH"
set "MY_email=BCH@gmail.com"
set "MY_year=2025"
set "MY_license=MIT"
set "MY_project_name=testproject"
set "MY_proj_root=%CD%"
set "MY_repo_name=testrepo"
set "MY_version=0.1.0"

for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "MY_date=%%A"


REM --- Write out an env file that holds all key/value pairs for replacement ---
REM --- It will automatically write out the default keys from the default 'placeholders.env' file, since the key has temporarily been prepended with a fixed prefix, and any updated value.
(
    for /f "tokens=* delims=" %%V in ('set MY_') do (
        echo %%V
    )
) > "%placeholders_TEMP%"

echo Updated env file written to %placeholders_TEMP%.
echo.
pause

REM --- Define file paths for input & output ---
set "inputFile=string_replacement_test_input.txt"
set "outputFile=string_replacement_test_output.txt"
set "psScript=..\ReplacePlaceholders.ps1"

REM Call the PowerShell script with the three parameters.
powershell -NoProfile -File "%psScript%" -InputFile "%inputFile%" -OutputFile "%outputFile%" -EnvFile "%placeholders_TEMP%"

REM --- Clean up the temporary env file ---
del "%placeholders_TEMP%"

REM endlocal

echo Replacement complete. Output written to %outputFile%.
pause

goto :eof


:GETDESCRIPTION
REM Parameter %~1 is the name of the variable we want to set.
setlocal DisableDelayedExpansion
set /p "tempInput=Enter a new description: "
endlocal & set "%~1=%tempInput%"
REM endlocal & call set "%~1"=%%tempInput%%
goto :EOF