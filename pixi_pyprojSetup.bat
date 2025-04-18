:: This file is copyrighted by Ben Hurwitz <bchurwitz+pixi_pyprojSetup@gmail.com>, 2025, under the GNU GPL v3.0. 
:: Much of this file was written with the help of ChatGPT, versions GPT-4o, GPT-4o mini, and o3-mini.
:: See <https://chatgpt.com/share/67ffcd98-a7a8-800e-9dcd-8c4b78f895f8>
:: This file is version-controlled via git and saved on GitHub under the repository <https://github.com/bhurwitz/pixi-pyprojSetup>
::
:: TODO: boilerplate should not be limited to warranty text.
:: TODO: Incorporate semantic-release (https://python-semantic-release.readthedocs.io/en/latest/) for versioning and changelog.

@echo off
setlocal EnableDelayedExpansion

REM === ENVIRONMENTAL VARS
set defaultDir=C:\Users\bchur\Desktop\Projects
set "templateDir=%~dp0_templates"
echo Templates will be found at: %templateDir%

cd /d "%defaultDir%"
echo The project directory will be created in "%CD%".
choice /M "Would you like to change where the project directory will live?"
IF ERRORLEVEL 2 GOTO skipChangeParent
set /p new_parent=Enter the absolute path to the PARENT directory into which the project directory will be created: 
if not exist "!new_parent!\" (
  mkdir "!new_parent!"
  echo A new directory has been created at "!new_parent!". 
)
cd /d "!new_parent!"
:skipChangeParent
echo Currently in "!CD!"


REM === Collect user input ===
set /p package=Enter a name for the package (lower- or snake-case): 
set /p repo_name=Enter a name for the repo (lower- or kebab-case): 
set /p author=Enter author name: 
set /p email=Enter email address:
set /p description=Enter a short project description (1 sentence): 
for /f %%I in ('powershell -NoProfile -Command "(Get-Date).Year"') do set year=%%I
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%A"

:: Create and enter project directory
pixi init %package% --format pyproject
cd %package%
set "proj_root=%CD%"
set "srcDir=src\%package%"

for /f "tokens=2 delims== " %%A in ('findstr /r "^version *= *" pyproject.toml') do (
    set version=%%A
)
set version=%version:"=%

::=================================================================================================
::=================================================================================================

REM === Select a license ===
:: 1) Enumerate license templates
set count=0
for %%F in (%templateDir%\license_*.txt) do (
  set /a count+=1
  rem strip off "license_" prefix
  set "fname=%%~nF"
  set "name=!fname:license_=!"
  set "license_!count!=!name!"
  echo !count!: !name!
)

:: 2) Prompt the user to pick one
echo See ^<https://choosealicense.com/licenses/^> for license summaries.
set /p choice=Select a license by number: 
rem retrieve the chosen license name
for /f "delims=" %%L in ('echo !license_%choice%!') do set "license_name=%%L"
echo Selected license: %license_name%

:: ——————————————
:: 3) Copy the LICENSE file
call :copy_fromTemplate "%templateDir%\license_%license_name%.txt" "LICENSE.txt"

:: 4) Ensure a boilerplate exists in _templates
set "boilerplate=%srcDir%\%license_name%_boilerplate.txt"
if not exist "%templateDir%\%license_name%_boilerplate.txt" (
  echo # This file within package ^<%package%^> is copyrighted by %author% ^<%email%^> as of %year% under the %license_name% license. > "%boilerplate%"
) else (
  call :copy_fromTemplate "%templateDir%\%license_name%_boilerplate.txt" "%boilerplate%"
)

::=================================================================================================
::=================================================================================================

REM === Create README.md from template ===
set file=README.md
call :copy_fromTemplate "%templateDir%\%file%.TEMPLATE" "%file%"

::=================================================================================================
::=================================================================================================

REM === Create CHANGELOG.md from template ===
set file=CHANGELOG.md
call :copy_fromTemplate "%templateDir%\%file%.TEMPLATE" "%file%"

::=================================================================================================
::=================================================================================================

REM === Create __init__.py from template ===
set file=__init__.py
call :copy_fromTemplate "%templateDir%\%file%.TEMPLATE" "%srcDir%\%file%" %boilerplate%
(
  echo.
  echo __version__ = "%version%"
  echo __author__ = "%author%"
) >> "%srcDir%\%file%" 


::=================================================================================================
::=================================================================================================

REM === Create cli.py from template ===
set file=cli.py
call :copy_fromTemplate "%templateDir%\%file%.TEMPLATE" "%srcDir%\%file%" "%boilerplate%"


::=================================================================================================
::=================================================================================================

REM === Create __main__.py from template ===
set file=__main__.py
call :copy_fromTemplate "%templateDir%\%file%.TEMPLATE" "%srcDir%\%file%" "%boilerplate%"

::=================================================================================================
::=================================================================================================

REM === Create main.py from template ===
set file=main.py
call :copy_fromTemplate "%templateDir%\%file%.TEMPLATE" "%file%" "%boilerplate%"

::=================================================================================================
::=================================================================================================

REM === Create the batch script to run the package ===
call :copy_fromTemplate "%templateDir%\runPythonScript.bat.TEMPLATE" "run_%package%.bat" "" ":: Copyright (C) %year% by %author% <%email%> under %license_name% (see LICENSE.txt for details)"

:: The following code is basically the prepend_boilerplate_string method put into the code. 
REM set "boilerplate=:: Copyright (C) {year}  {author} <{email}> under GNU GPL v3.0 (see LICENSE.txt for details)"
REM set "boilerplateFile=%temp%\boilerplate_%random%.txt"
REM powershell -Command "Set-Content -Path '!boilerplateFile!' -Value '!boilerplate!'"
REM call :copy_fromTemplate "%templateDir%\runPythonScript.bat.TEMPLATE" "run_%package%.bat" "!boilerplateFile!"


::=================================================================================================
::=================================================================================================

REM === Insert readme and license into pyproject.toml ===
set TOML_FILE=pyproject.toml

powershell -Command ^
  "$file = '%TOML_FILE%';" ^
  "$lines = Get-Content $file;" ^
  "$newlines = @(); $inserted = $false;" ^
  "foreach ($line in $lines) {" ^
  "  $newlines += $line;" ^
  "  if ($line -match '^version =') {" ^
  "    $newlines += 'readme = \"README.md\"';" ^
  "    $newlines += 'license-files = [\"LICENSE.txt\"]';" ^
  "    $newlines += 'license = \"%license_name%\"';" ^
  "    $newlines += 'description = \"%description%\"';" ^
  "    $inserted = $true" ^
  "  }" ^
  "}; if (-not $inserted) { Write-Host 'Warning: version line not found' };" ^
  "$newlines | Set-Content $file"
  

REM === Check if the [tool.setuptools] section exists, and append if not ===
findstr /C:"[tool.setuptools]" "%TOML_FILE%" >nul
if errorlevel 1 (
    :: Add an empty line before the section
    echo.>> "%TOML_FILE%" 
    echo [tool.setuptools]>> "%TOML_FILE%"
    echo package-dir = {"" = "src"}>> "%TOML_FILE%"
) else (
    echo [tool.setuptools] section already exists.
)

REM === Check if the [tool.pytest.ini_options] section exists, and append if not ===
findstr /C:"[tool.pytest.ini_options]" "%TOML_FILE%" >nul
if errorlevel 1 (
    :: Add an empty line before the section
    echo.>> "%TOML_FILE%" 
    echo [tool.pytest.ini_options]>> "%TOML_FILE%"
    echo pythonpath = ["src"]>> "%TOML_FILE%"
) else (
    echo [tool.pytest.ini_options] section already exists.
)

::=================================================================================================
::=================================================================================================  

REM === Initialize Git ===
git init
git add .
git commit -m "Initial project setup"
git tag -a v%version% -m "Initial release"

:: Add a few things to the .gitignore
(
    echo.
    echo # Python extras
    echo __pycache__/
    echo *.pyc
    echo *.pyo
    echo *.pyd
    echo.
    echo # OS clutter:
    echo .DS_Store
    echo Thumbs.db
    echo .venv/
    echo.
    echo # Misc.
    echo *.env
) >> .gitignore

REM === Push to the repo ===
echo.
choice /M "Would you like to push to GitHub?"
IF %ERRORLEVEL%==1 GOTO :GitHub
:postgithub


echo.
echo Project setup COMPLETE
echo.
echo ^>^>^> Now you can start coding in ^<%package%^>.
echo.
echo ^>^>^> Don't forget to add packages with ^'pixi add ^<package^>^'.
echo.
echo ^>^>^> You can run the package's 'main.py' by running ^'%package%_run.bat^' from wherever is convenient.
echo.
echo ^>^>^> Alternative, run ^'pixi run python -m %package%^' from within the project root ^(this may require some edits to function properly^).
echo.

pause

goto :eof

::=================================================================================================
::=================================================================================================  


:GitHub
gh repo create %repo_name% --private --source=. --remote=origin
git branch -M main
git push -u origin main
git push origin v%version%
goto :postgithub


::=================================================================================================
::=================================================================================================  


REM === STRING REPLACEMENT METHOD
:replace_placeholders
:: %1 = file path to modify
:: %2 = An optional location for debugging.

if "%~1"=="" (
    echo [ERROR][replace_placeholders] Missing file path. Called from: %~2
    goto :eof
)

powershell -Command ^
  "$file = Get-Content '%~1' -Raw;" ^
  "$replacements = @{" ^
    "'{package}' = '%package%';" ^
    "'{author}' = '%author%';" ^
    "'{email}' = '%email%';" ^
    "'{year}' = '%year%';" ^
    "'{date}' = '%date%';" ^
    "'{license}' = '%license_name%';" ^
    "'{license-name}' = '%license_name%';" ^
    "'{description}' = '%description%';" ^
    "'{project_name}' = '%project_name%';" ^
    "'{absPath}' = '%proj_root%';" ^
    "'{repo_name}' = '%repo_name%'" ^
  "};" ^
  "foreach ($key in $replacements.Keys) { $file = $file -replace $key, $replacements[$key] };" ^
  "Set-Content '%~1' $file"

goto :eof


::=================================================================================================
::================================================================================================= 

:prepend_boilerplate
:: %1 = boilerplate file OR string
:: %2 = target file to insert into
set "TAB=   "
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
if exist "%~1" (
REM if %errorlevel%==0 (
  REM echo in the file block
  echo %TAB%Prepending file ^<%~1^> into ^<%~2^>.
  call :prepend_boilerplate_file "%~1" "%~2"
) else (
  REM echo in the string block
  echo %TAB%Prepending string ^<"%~1"^> into ^<%~2^>.
  call :prepend_boilerplate_string "%~1" "%~2"
)
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
  
powershell -Command ^
  "$boilerplate = Get-Content '%~1' -Raw;" ^
  "$target = Get-Content '%~2' -Raw;" ^
  "$combined = $boilerplate + \"`n`n\" + $target;" ^
  "Set-Content '%~2' $combined"
  

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
set "TAB=   "
copy "%~1" "%~2" >nul
if %errorlevel%==0 (
    echo %TAB%Successfully copied ^<%~1^> to ^<%~2^>.
) else (
    echo %TAB%FAILED TO COPY ^<%~1^> to ^<%~2^>
)
goto :eof


::=================================================================================================
::=================================================================================================  

:: Function for copying and filling from template
:copy_fromTemplate
:: %1 = source file
:: %2 = destination file
:: %3 = boilerplate file (may be empty)
:: %4 = boilerplate string (may be empty)
:: %5 = string first? (true/false, defaults to false)
:: By default, if a file and string are passed, the file is prepended first UNLESS %5 is set to "true".

call :copy_withMsg "%~1" "%~2"

:: If the string should be prepended first, else do the first first.
if "%~5"=="true" (
  REM echo 5 was true
  :: If the string passed is non-empty, write it.
  if not "%~4"=="" (
    REM echo and 4 was nonempty
    call :prepend_boilerplate_string "%~4" "%~2"
  )
  :: If the file pass is non-empty, write it.
  if not "%~3"=="" (
    REM echo and 3 was nonempty
    call :prepend_boilerplate "%~3" "%~2"
  )
) else (
  REM echo 5 was NOT true
  :: If the file pass is non-empty, write it.
  if not "%~3"=="" (
    REM echo and 3 was nonempty
    call :prepend_boilerplate "%~3" "%~2"
  )
  :: If the string passed is non-empty, write it.
  if not "%~4"=="" (
    REM echo and 4 was nonempty
    call :prepend_boilerplate_string "%~4" "%~2"
  )
)

:: This conditional tried to pass complicated strings to prepend_boilerplate, where a conditional would test if the string existed as a path. This conditional broke with special characters and I couldn't get it working, which leads to the obnoxious conditional tree above. But now it works.
REM if "%~3"=="" (
  REM call :prepend_boilerplate "%~3" "%~2"
REM )

call :replace_placeholders "%~2" "%~2"

goto :eof

