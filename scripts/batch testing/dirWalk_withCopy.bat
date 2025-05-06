@echo off
setlocal enabledelayedexpansion
set "TAB=    "
set "TABB=        "

REM Set the source (parent) directory and destination directory.
set "parentDir=C:\Users\bchur\Desktop\Projects\pixi_pyprojSetup\templates"
set "destDir=C:\Users\bchur\Desktop\Projects\pixi_pyprojSetup\scripts\batch testing\dirWalk_withCopy_testDir"

REM Specify folder names to exclude.
REM When a folder name contains spaces, enclose it in quotes.
REM For example, to exclude folders named "Folder One" and "Folder Two":
set "excludeFolders="_licenses" "src""

REM Recursively loop through all files under the parent directory.
for /R "%parentDir%" %%F in (*) do (
    set "filepath=%%F"
    set "skipFile="

    REM Check each excluded folder.
    for %%D in (%excludeFolders%) do (
        REM %%~D removes any surrounding quotes.
        REM This call uses string substitution to remove "\FolderName\" from the file path.
        call set "test=%%filepath:\%%~D\=%%%"
        if not "!test!"=="!filepath!" (
            set "skipFile=yes"
        )
    )

    if defined skipFile (
         echo -- Skipping file "%%F" because it is in one of the excluded folders.
    ) else (
         echo "Processing file %%F"
         call :processFile "%%F"
    )
)
goto :EOF

:processFile
REM This subroutine copies the file, preserving the relative directory structure.
REM %~1 is the full path to the file.
set "filepath=%~1"

REM Compute the relative path by removing the parentDir plus the trailing backslash.
set "relPath=!filepath:%parentDir%\=!"
set "destFile=%destDir%\!relPath!"

echo %TAB% relPath = !relPath!
echo %TAB% destFile = !destFile!

REM Create the destination directory if needed.
for %%I in ("!destFile!") do set "destDirPath=%%~dpI"
if not exist "!destDirPath!" (
    mkdir "!destDirPath!"
)

REM echo Copying "!filepath!" to "!destFile!"
copy /Y "!filepath!" "!destFile!" >nul
if errorlevel 0 (
    echo %TAB% Copy successful
) else (
    echo %TAB% --- FAILED TO COPY
)
goto :EOF
