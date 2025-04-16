@echo off
setlocal

:: Ask user for project name
set /p PROJECT_NAME=Enter project name (kebab case): 

:: Create and enter project directory
pixi init %PROJECT_NAME% --format pyproject
cd %PROJECT_NAME%

:: Create a 'pixi.toml' file as well. This is needed for other Pixi users to replicate the environment.
pixi init --format pixi

:: Initialize Git
git init

:: Create .gitignore
# Add a bunch of stuff to the .gitignore file
(
echo # For the Pixi environment:
echo .pixi/
echo __pycache__/
echo *.pyc
echo *.pyo
echo *.pyd
echo # OS clutter:
echo .DS_Store
echo Thumbs.db
echo .venv/
) >> .gitignore

:: Create __init__.py and populate it with content
(
echo """"
echo %PROJECT_NAME%
echo ------------
echo 
echo This is the initialization file for the %PROJECT_NAME% package.
echo """"
echo 
echo __version__ = "0.1.0"
echo __author__ = "Ben Hurwitz"
) > __init__.py



:: Add and commit to Git
git add .
git commit -m "Initial commit"

:: Create the GitHub repo and push the commits
gh repo create %PROJECT_NAME% --private --source=. --remote=origin --push

echo Project setup complete! Now you can start coding in %PROJECT_NAME%. 
echo
echo  >>> Don't forget to activate the environment with 'pixi shell' and to add packages with 'pixi add <package>'.
pause
