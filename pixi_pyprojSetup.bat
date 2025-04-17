:: This file is copyrighted by Ben Hurwitz <bchurwitz+pixi_pyprojSetup@gmail.com>, 2025, under the GNU GPL v3.0. 
:: Much of this file was written with the help of ChatGPT, versions GPT-4o, GPT-4o mini, and o3-mini.
:: See <https://chatgpt.com/share/67ffcd98-a7a8-800e-9dcd-8c4b78f895f8>
:: This file is version-controlled via git and saved on GitHub under the repository <https://github.com/bhurwitz/pixi-pyprojSetup>
::
:: TODO: boilerplate should not be limited to warranty text.

@echo off
setlocal EnableDelayedExpansion

REM === ENVIRONMENTAL VARS
set templateDir=C:\Users\bchur\Desktop\Projects\_templates
::set boilerplate=%templateDir%\GNU_GPL_v3_boilerplate.txt
set defaultDir=C:\Users\bchur\Desktop\Projects

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

:: Create and enter project directory
pixi init %package% --format pyproject
cd %package%
set proj_root="%CD%"

for /f "tokens=2 delims== " %%A in ('findstr /r "^version *= *" pyproject.toml') do (
    set version=%%A
)
set version=%version:"=%


REM === Copy LICENSE.txt (GNU GPL v3.0) ===
::copy "%templateDir%\license_GNU_GPL_v3.txt" LICENSE.txt


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
copy "%templateDir%\license_%license_name%.txt" "LICENSE.txt"
call :replace_placeholders "LICENSE.txt" "LICENSE"

:: 4) Ensure a boilerplate exists in _templates
set boilerplate=src\%package%\%license_name%_boilerplate.txt
if not exist "%templateDir%\%license_name%_boilerplate.txt" (
  echo # This file within package ^<%package%^> is copyrighted by %author% ^<%email%^> as of %year% under the %license_name% license. > "%boilerplate%"
) else (
  copy "%templateDir%\%license_name%_boilerplate.txt" "%boilerplate%"
  call :replace_placeholders "%boilerplate%" "boilerplate"
)

REM === Create README.md ===
copy %boilerplate% README.md
(
  echo %package% ^(%author% ^<%email%^>, %year%^)
  echo.
  echo %description%
  echo.
  echo ## Installation
  echo Instructions go here.
) > README.md

REM === Insert readme and license into pyproject.toml ===
powershell -Command ^
  "$file = 'pyproject.toml';" ^
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

REM === Create __init__.py from template ===
set init_file=src\%package%\__init__.py
copy "%boilerplate%" "%init_file%"
(
  echo.
  echo __version__ = "%version%"
  echo __author__ = "%author%"
) >> %init_file%


REM === Copy template files and fill as needed ===
REM === cli.py ===
set copiedFile=src\%package%\cli.py
copy "%templateDir%\cli.py" %copiedFile%
call :replace_placeholders "%copiedFile%" "cli.py"
call :prepend_boilerplate "%boilerplate%" "%copiedFile%"
REM powershell -Command ^
  REM "$template = Get-Content '%copiedFile%' -Raw;" ^
  REM "$output = $template -replace '{package}', '%package%' " ^
  REM "                      -replace '{author}', '%author%' " ^
  REM "                      -replace '{email}', '%email%' " ^
  REM "                      -replace '{year}', '%year%' " ^
  REM "                      -replace '{description}', '%description%';" ^
  REM "Set-Content '%copiedFile%' $output"
REM powershell -Command ^
  REM "$boilerplate = (Get-Content '%boilerplate%' | Out-String).TrimEnd();" ^
  REM "$file = Get-Content '%copiedFile%' -Raw;" ^
  REM "$combined = $boilerplate + \"`n`n\" + $file;" ^
  REM "Set-Content '%copiedFile%' $combined"


REM === __main__.py ===
set copiedFile=src\%package%\__main__.py
copy "%templateDir%\__main__.py" %copiedFile%
call :replace_placeholders "%copiedFile%" "__main__.py"
call :prepend_boilerplate "%boilerplate%" "%copiedFile%"


  
REM === main.py ===
set copiedFile=main.py 
copy "%templateDir%\main.py" %copiedFile%
call :replace_placeholders "%copiedFile%" "main.py"
call :prepend_boilerplate "%boilerplate%" "%copiedFile%"



REM === Runner batch file ===
set copiedFile=run_%package%.bat
copy "%templateDir%\runPythonScript.bat" %copiedFile%
powershell -Command ^
  "$boilerplate = ':: Copyright (C) {year}  {author} <{email}> under GNU GPL v3.0 (see LICENSE.txt for details)';" ^
  "$file = Get-Content '%copiedFile%' -Raw;" ^
  "$combined = $boilerplate + \"`n`n\" + $file;" ^
  "Set-Content '%copiedFile%' $combined"
call :replace_placeholders "%copiedFile%" "run.bat"


  

REM === Initialize Git ===
git init
git add .
git commit -m "Initial project setup"
git tag -a v%version% -m "Initial release"

:: Add a few things to the .gitignore
(
    echo __pycache__/
    echo *.pyc
    echo *.pyo
    echo *.pyd
    echo
    echo # OS clutter:
    echo .DS_Store
    echo Thumbs.db
    echo .venv/
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
echo ^>^>^> Activate the environment with ^'pixi shell^', and the add packages with ^'pixi add ^<package^>^'.
echo.
echo ^>^>^> Move ^'%package%_run.bat^' to wherever is convenient and then run that to call ^'main.py^'.
echo.
echo ^>^>^> Alternative, run ^'pixi run python -m %package%^' from within the project root ^(this may require some edits to function properly^).
echo.

pause

goto :eof

:GitHub
gh repo create %repo_name% --private --source=. --remote=origin
git branch -M main
git push -u origin main
git push origin v%version%
goto :postgithub


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


REM === PREPEND BOILERPLATE TEXT
:prepend_boilerplate
:: %1 = boilerplate file
:: %2 = target file

powershell -Command ^
  "$boilerplate = Get-Content '%~1';" ^
  "$target = Get-Content '%~2';" ^
  "$combined = $boilerplate + '', $target;" ^
  "$combined | Set-Content '%~2'"
  

goto :eof
