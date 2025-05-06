@echo off
setlocal enabledelayedexpansion

REM Set the parent directory (adjust to your needs).
set "parentDir=C:\Users\bchur\Desktop\Projects\pixi_pyprojSetup\templates"

REM Specify the folder names that should be excluded.
set "excludeFolders=boilerplates src"

REM Recursively loop through all files under the parent directory.
for /R "%parentDir%" %%F in (*) do (
    REM Store the full file path in a variable.
    set "filepath=%%F"
    set "skipFile="

    REM Loop through all the folder names we wish to exclude.
    for %%D in (%excludeFolders%) do (
        REM Use string substitution to remove "\FolderName\" from the path.
        REM If the replacement is different, the folder is present.
        call set "test=%%filepath:\%%D\=%%%"
        if not "!test!"=="!filepath!" (
            set "skipFile=yes"
        )
    )

    if defined skipFile (
         echo -- Skipping file "%%F" because it is in one of the excluded folders.
    ) else (
         call :processFile "%%F"
    )
)
goto :EOF

:processFile
REM Replace this with the action you want to perform on each file.
echo Processing file: %~1
REM (Your processing code goes here)
goto :EOF
