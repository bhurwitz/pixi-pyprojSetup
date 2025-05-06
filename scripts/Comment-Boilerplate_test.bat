@echo off
setlocal EnableDelayedExpansion

REM Define base directories relative to this script.
set "BASE_DIR=%~dp0"
set "TEST_DIR=%BASE_DIR%CommentBoilerplate_TestFiles"
set "OUTPUT_DIR=%BASE_DIR%CommentBoilerplate_OutputFiles"

REM Create test and output directories if they don't exist.
if not exist "%TEST_DIR%" mkdir "%TEST_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Define the extensions to test.
set "extensions=.py .md .bat .yml .yaml .cpp .c .toml .ini .xyz .rst .cfg .sh .ps1"

REM Create a test file for each extension.
for %%e in (%extensions%) do (
    set "ext=%%e"
    set "filename=Boilerplate%%e"
    set "filepath=%TEST_DIR%\!filename!"
    
    echo Creating test file: !filepath!
    
    REM Clear a flag to indicate the file hasn’t been created yet.
    set "created="
    
    if "%%e"==".py" (
        (
            echo # Correct Python comment.
            echo    #Missing space after marker.
            echo print^(^"Hello from Python^"^)
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".md" if not defined created (
        (
            echo %%%% Markdown comment line.
            echo Some markdown content.
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".bat" if not defined created (
        (
            echo REM Batch file comment.
            echo echo Hello from Batch
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".yml" if not defined created (
        (
            echo                          # YAML comment, large leading space
            echo key: value
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".yaml" if not defined created (
        (
            echo #                   YAML comment with extra after-space.
            echo - item1
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".cpp" if not defined created (
        (
            echo // C++ comment.
            echo int main^(^) { return 0; }
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".c" if not defined created (
        (
            echo // C comment.
            echo char *s = ^"Hello^";
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".toml" if not defined created (
        (
            echo # TOML comment.
            echo [section]
            echo key = ^"value^"
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".ini" if not defined created (
        (
            echo # INI comment line.
            echo [settings]
            echo option=1
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".xyz" if not defined created (
        (
            echo * Wrong marker for unknown extension.
            echo Some unknown content.
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".rst" if not defined created (
        (
            echo .. This is a reStructuredText comment.
            echo Some reST content.
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".cfg" if not defined created (
        (
            echo # CFG comment.
            echo option = value
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".sh" if not defined created (
        (
            echo # Shell script comment.
            echo echo ^"Hello from shell^"
        ) > "!filepath!"
        set "created=1"
    )
    if "%%e"==".ps1" if not defined created (
        (
            echo # PowerShell script comment.
            echo echo ^"Hello from PowerShell^"
        ) > "!filepath!"
        set "created=1"
    )
)

echo.
echo Running Comment-Boilerplate.ps1 on test files...
for %%e in (%extensions%) do (
    set "filename=Boilerplate%%e"
    set "filepath=%TEST_DIR%\!filename!"
    echo Processing !filepath!...
    
    REM NOTE: Adjust the following script path if Comment-Boilerplate.ps1 is not in the current folder.
    REM powershell.exe -NoProfile -File "%BASE_DIR%Comment-Boilerplate.ps1" -Boilerplate "!filepath!" -Extension "%%e" -OutputDir "%OUTPUT_DIR%" -Debug
    pwsh.exe -NoProfile -File "%BASE_DIR%Comment-Boilerplate.ps1" -Boilerplate "!filepath!" -Extension "%%e" -OutputDir "%OUTPUT_DIR%" -Debug
)

echo.
echo Processed files are in the folder "%OUTPUT_DIR%":
dir /b "%OUTPUT_DIR%"

pause
endlocal
