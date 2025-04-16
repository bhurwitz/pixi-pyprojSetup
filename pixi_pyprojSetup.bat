:: This file is copyrighted by Ben Hurwitz <bchurwitz+pixi_pyprojSetup@gmail.com>, 2025, under the GNU GPL v3.0. 
:: Much of this file was written with the help of ChatGPT, versions GPT-4o, GPT-4o mini, and o3-mini.
:: See <https://chatgpt.com/share/67ffcd98-a7a8-800e-9dcd-8c4b78f895f8>
:: This file is version-controlled via git and saved on GitHub under the repository <https://github.com/bhurwitz/pixi-pyprojSetup>

@echo off
setlocal EnableDelayedExpansion

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
set "proj_root=%CD%"

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
powershell -Command ^
  "$template = Get-Content 'LICENSE.txt' -Raw; " ^
  "$output = $template -replace '{package}', '%package%' " ^
                    "-replace '{author}', '%author%' " ^
                    "-replace '{email}', '%email%' " ^
                    "-replace '{year}', '%year%' " ^
                    "-replace '{description}', '%description%' " ^
                    "-replace '{license-name}', '%license_name%'; " ^
  "Set-Content 'LICENSE.txt' $output"

:: 4) Ensure a boilerplate exists in _templates
set boilerplate=src\%package%\%license_name%_boilerplate.txt
if not exist "%templateDir%\%license_name%_boilerplate.txt" (
  echo # This file within package ^<%package%^> is copyrighted by %author% ^<%email%^> as of %year% under the %license_name% license. > "%boilerplate%"
) else (
  copy "%templateDir%\%license_name%_boilerplate.txt" "%boilerplate%"
  powershell -Command ^
        "$template = Get-Content '%boilerplate%' -Raw; " ^
        "$output = $template -replace '{package}', '%package%' " ^
                          "-replace '{author}', '%author%' " ^
                          "-replace '{email}', '%email%' " ^
                          "-replace '{year}', '%year%' " ^
                          "-replace '{description}', '%description%' " ^
                          "-replace '{license-name}', '%license_name%'; " ^
        "Set-Content '%boilerplate%' $output"
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
powershell -Command ^
  "$template = Get-Content '%copiedFile%' -Raw;" ^
  "$output = $template -replace '{package}', '%package%' " ^
  "                      -replace '{author}', '%author%' " ^
  "                      -replace '{email}', '%email%' " ^
  "                      -replace '{year}', '%year%' " ^
  "                      -replace '{description}', '%description%';" ^
  "Set-Content '%copiedFile%' $output"
powershell -Command ^
  "$boilerplate = (Get-Content '%boilerplate%' | Out-String).TrimEnd();" ^
  "$file = Get-Content '%copiedFile%' -Raw;" ^
  "$combined = $boilerplate + \"`n`n\" + $file;" ^
  "Set-Content '%copiedFile%' $combined"


REM === __main__.py ===
set copiedFile=src\%package%\__main__.py
copy "%templateDir%\__main__.py" %copiedFile%
powershell -Command ^
  "$template = Get-Content '%copiedFile%' -Raw;" ^
  "$output = $template -replace '{package}', '%package%' " ^
  "                      -replace '{author}', '%author%' " ^
  "                      -replace '{email}', '%email%' " ^
  "                      -replace '{year}', '%year%' " ^
  "                      -replace '{description}', '%description%';" ^
  "Set-Content '%copiedFile%' $output"
powershell -Command ^
  "$boilerplate = (Get-Content '%boilerplate%' | Out-String).TrimEnd();" ^
  "$file = Get-Content '%copiedFile%' -Raw;" ^
  "$combined = $boilerplate + \"`n`n\" + $file;" ^
  "Set-Content '%copiedFile%' $combined"


  
REM === main.py ===
set copiedFile=main.py
copy "%templateDir%\main.py" %copiedFile%
powershell -Command ^
  "$template = Get-Content '%copiedFile%' -Raw;" ^
  "$output = $template -replace '{package}', '%package%' " ^
  "                      -replace '{author}', '%author%' " ^
  "                      -replace '{email}', '%email%' " ^
  "                      -replace '{year}', '%year%' " ^
  "                      -replace '{description}', '%description%';" ^
  "Set-Content '%copiedFile%' $output"
powershell -Command ^
  "$boilerplate = (Get-Content '%boilerplate%' | Out-String).TrimEnd();" ^
  "$file = Get-Content '%copiedFile%' -Raw;" ^
  "$combined = $boilerplate + \"`n`n\" + $file;" ^
  "Set-Content '%copiedFile%' $combined"



REM === Runner batch file ===
set copiedFile=%package%_run.bat
copy "%templateDir%\runPythonScript.bat" %copiedFile%

powershell -Command ^
  "$boilerplate = ':: Copyright (C) {year}  {author} <{email}> under GNU GPL v3.0 (see LICENSE.txt for details)';" ^
  "$file = Get-Content '%copiedFile%' -Raw;" ^
  "$combined = $boilerplate + \"`n`n\" + $file;" ^
  "Set-Content '%copiedFile%' $combined"
  
  
powershell -Command ^
  "$template = Get-Content '%copiedFile%' -Raw;" ^
  "$output = $template -replace '{package}', '%package%' " ^
  "                      -replace '{author}', '%author%' " ^
  "                      -replace '{email}', '%email%' " ^
  "                      -replace '{year}', '%year%' " ^
  "                      -replace '{description}', '%description%' " ^
  "                      -replace '{absPath}', '%proj_root%'; " ^
  "Set-Content '%copiedFile%' $output"

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
IF ERRORLEVEL 2 GOTO skipGitHub
gh repo create %repo_name% --private --source=. --remote=origin
git branch -M main
git push -u origin main
git push origin v%version%
:skipGitHub


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
