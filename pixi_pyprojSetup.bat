@echo off
setlocal EnableDelayedExpansion

set templateDir=C:\Users\bchur\Desktop\Projects\_templates
set boilerplate=%templateDir%\GNU_GPL_v3_boilerplate.txt

REM === Collect user input ===
set /p package=Enter a name for the package (lower- or snake-case): 
set /p repo_name=Enter a name for the repo (lower- or kebab-case): 
set /p author=Enter author name: 
set /p email=Enter email address:
set /p description=Enter a short project description (1 sentence): 
for /f %%I in ('powershell -NoProfile -Command "(Get-Date).Year"') do set year=%%I

for /f "tokens=2 delims== " %%A in ('findstr /r "^version *= *" pyproject.toml') do (
    set version=%%A
)
set version=%version:"=%

:: Create and enter project directory
pixi init %package% --format pyproject
cd %package%
set "proj_root=%CD%"


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

REM === Copy LICENSE.txt (GNU GPL v3.0) ===
copy "%templateDir%\license_GNU_GPL_v3.txt" LICENSE.txt

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
  "    $newlines += 'license = \"GPL-3.0-only\"';" ^
  "    $newlines += 'description = \"%description%\"';" ^
  "    $inserted = $true" ^
  "  }" ^
  "}; if (-not $inserted) { Write-Host 'Warning: version line not found' };" ^
  "$newlines | Set-Content $file"

REM === Create __init__.py from template ===
set init_file=src\%package%\__init__.py

powershell -Command ^
  "$template = Get-Content '%boilerplate%' -Raw;" ^
  "$output = $template -replace '{package}', '%package%' " ^
  "                      -replace '{author}', '%author%' " ^
  "                      -replace '{email}', '%email%' " ^
  "                      -replace '{year}', '%year%' " ^
  "                      -replace '{description}', '%description%';" ^
  "Set-Content '%init_file%' $output"

(
echo.
echo __version__ = "%version%"
echo __author__ = "Ben Hurwitz"
) >> %init_file%


REM === Copy template files and fill as needed ===
REM === cli.py ===
set copiedFile=src\%package%\cli.py
copy "%templateDir%\cli.py" %copiedFile%
powershell -Command ^
  "$boilerplate = Get-Content '%boilerplate%';" ^
  "$file = Get-Content '%copiedFile%';" ^
  "$combined = $boilerplate + $file;" ^
  "$combined | Set-Content '%copiedFile%'"
powershell -Command ^
  "$template = Get-Content '%copiedFile%' -Raw;" ^
  "$output = $template -replace '{package}', '%package%' " ^
  "                      -replace '{author}', '%author%' " ^
  "                      -replace '{email}', '%email%' " ^
  "                      -replace '{year}', '%year%' " ^
  "                      -replace '{description}', '%description%';" ^
  "Set-Content '%copiedFile%' $output"

REM === __main__.py ===
set copiedFile=src\%package%\__main__.py
copy "%templateDir%\__main__.py" %copiedFile%
powershell -Command ^
  "$boilerplate = Get-Content '%boilerplate%';" ^
  "$file = Get-Content '%copiedFile%';" ^
  "$combined = $boilerplate + $file;" ^
  "$combined | Set-Content '%copiedFile%'"
powershell -Command ^
  "$template = Get-Content '%copiedFile%' -Raw;" ^
  "$output = $template -replace '{package}', '%package%' " ^
  "                      -replace '{author}', '%author%' " ^
  "                      -replace '{email}', '%email%' " ^
  "                      -replace '{year}', '%year%' " ^
  "                      -replace '{description}', '%description%';" ^
  "Set-Content '%copiedFile%' $output"
  
REM === main.py ===
set copiedFile=main.py
copy "%templateDir%\main.py" %copiedFile%
powershell -Command ^
  "$boilerplate = Get-Content '%boilerplate%';" ^
  "$file = Get-Content '%copiedFile%';" ^
  "$combined = $boilerplate + $file;" ^
  "$combined | Set-Content '%copiedFile%'"
powershell -Command ^
  "$template = Get-Content '%copiedFile%' -Raw;" ^
  "$output = $template -replace '{package}', '%package%' " ^
  "                      -replace '{author}', '%author%' " ^
  "                      -replace '{email}', '%email%' " ^
  "                      -replace '{year}', '%year%' " ^
  "                      -replace '{description}', '%description%';" ^
  "Set-Content '%copiedFile%' $output"


REM === Runner batch file ===
set copiedFile=%package%_run.bat
copy "%templateDir%\runPythonScript.bat" %copiedFile%

powershell -Command ^
  "$boilerplate = ':: Copyright (C) {year}  {author} <{email}> under GNU GPL v3.0 (see LICENSE.txt for details)';" ^
  "$file = Get-Content '%copiedFile%';" ^
  "$combined = $boilerplate + $file;" ^
  "$combined | Set-Content '%copiedFile%'"
  
  
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
git tag -a v%version% -m "Release v%version"

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
set /p repo=Would you like to push to GitHub? [y/n] 
IF "%repo%"=="y" (
    gh repo create %repo_name% --private --source=. --remote=origin
    git branch -M main
    git push -u origin main
    git push origin v%version%
)

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
