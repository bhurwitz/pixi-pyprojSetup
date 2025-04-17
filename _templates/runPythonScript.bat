REM === This script will automatically run the main.py through Pixi for the project. ===
REM === It may be moved to wherever so that the project can be stored separate from the run-script. ===

@echo off

cd {absPath}
PYTHONPATH=src pixi run python main.py