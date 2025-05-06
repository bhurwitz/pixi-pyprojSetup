@echo off
setlocal EnableDelayedExpansion

:: External file has already defined the structure:
call "inlineStringSubs_extFile.bat"
REM set "CFG_boilerplate_name={license_spdx}_BP"

:: Later, after prompting the user:
set "license_spdx=GPL-3.0-only"

:: Now perform the substitution using delayed expansion:
set "boilerplate_name=%CFG_boilerplate_name:{license_spdx}=!license_spdx!%"

echo The computed boilerplate_name is: !boilerplate_name! OR %boilerplate_name%
endlocal
pause