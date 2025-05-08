REM ================================================================
REM pixi_pyprojectSetup.env

REM Description:
REM     This defines the environmental variables for the 'pixi_pyprojectSetup.bat' script.
     
REM Usage:
REM     1. Variables MUST be in the form '<KEY><EQUAL-SIGN><VALUE>'. Any excess whitespace will translate into weirdness in the script.
REM     2. Any line that does not have an <EQUAL-SIGN> will be ignored.
REM     3. You may use placeholders (as defined in 'placeholders.user') within these.

REM Package <pixi_pyprojectSetup>

REM Copyright (c) 2025 by Ben Hurwitz <bchurwitz+pixi_pyprojectSetup@gmail.com> under GNU GPL v3.0

REM See LICENSE.txt for full details.

REM ================================================================


REM ================================================================
REM Settings that are fine for typical users to adjust.
REM ================================================================




REM ================================================================
REM Advanced settings, probably don't need to change these.
REM ================================================================

REM The maximum nesting depth for placeholders.
set "CFG_max_placeholder_depth=10"

REM The full path to the directory that stores the templates for copying and processing.
set "CFG_templates_dirPath=%CD%\templates"

REM Full path to the directory in which the licenses live.
set "CFG_license_dirPath=%CFG_templates_dirPath%\%CFG_license_dirName%

REM The full path to the directory that stores the various utility scripts that run.
set "CFG_scripts_dirPath=%CD%\scripts"

REM The script for inserting into a TOML file.
set "CFG_script_toml_insert=%CFG_scripts_dirPath%\toml_insert.ps1"

REM The script for replacing lines within a TOML file.
set "CFG_script_toml_replace=%CFG_scripts_dirPath%\toml_replace.ps1"

REM The script for placeholder replacement.
set "CFG_script_replacePlaceholders=%CFG_scripts_dirPath%\ReplacePlaceholders.ps1"

REM The script for prepending the boilerplate.
set "CFG_script_prepend=%CFG_scripts_dirPath%\prependToTarget.ps1"

REM The script for properly commenting the boilerplate template. 
set "CFG_script_BPcommenting=%CFG_scripts_dirPath%\Comment-Boilerplate.ps1"

REM The full path to the directory with the boilerplate templates
set "CFG_boilerplatesDir=%CFG_license_dirPath%\boilerplates"

REM The standardized naming structure for boilerplate files WITHOUT the extension.
REM Note that '{license_spdx}' will be replaced in the script with the correct user-selected value.
set "CFG_boilerplate_name={license_spdx}_boilerplate"

REM Template file extension identified (the final extension for any template file)
set "CFG_templateExt=TEMPLATE"

REM The name of the directory (not the path) in which the licenses live.
set "CFG_license_dirName=_licenses"

REM Specify folder names to exclude from copying.
REM When a folder name contains spaces, enclose it in quotes.
set "CFG_excludeFolders="%CFG_license_dirName%" "_miscNotCopied""\

REM Specify file names to exclude from copying
set "CFG_excludeFiles="file one.txt" "file2.cfg""



REM ================================================================
REM Return value, DO NOT CHANGE
REM ================================================================
exit /b 0