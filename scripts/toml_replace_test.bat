@echo off
setlocal

REM Set the path to PowerShell 7 (if installed).
set PWSH_PATH="C:\Program Files\PowerShell\7\pwsh.exe"

REM Check if PowerShell 7 exists.
if exist %PWSH_PATH% (
    echo Running with PowerShell 7...
) else (
    echo Running with PowerShell 5.1...
    set PWSH_PATH="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
)

REM Step 1: Create a dummy TOML file with initial settings.
set TOML_FILE=test_toml_file.toml
(
    echo [package]
    echo name = "example_package"
    echo version = "0.1.0"
    echo readme = "oldreadme.md"
    echo license-files = "oldlicense.txt"
    echo authors = "old author"
    echo numbers = [0]
    echo isStable = false
    echo notReplaced = "this should not be replaced"
) > %TOML_FILE%

echo.
echo Original TOML file:
type %TOML_FILE%
echo.

REM Step 2: Create a replacement configuration file with comments.
(
    echo // A comment above the brace.
    echo {
    echo     // Test comment for replacement config.
    echo     "File": "test_toml_file.toml",
    echo     "Replacements": {
    echo         "readme": "README.md",   // Replace old readme value.
    echo         "license-files": "[\"LICENSE.txt\"]",
    echo         "authors": "[{name = \"{author}\", email = \"{email}\"}]",
    echo         "numbers": [1, 2, 3],
    echo         "isStable": true
    echo     },
    echo     "Debug": true,
    echo     /* a block comment, not inline */
    echo     "FakeReplace": "This should not end up in the final file."
    echo }
    echo // A comment below the brace.
) > toml_replace_test.config

REM Step 3: Run the replacement script.
%PWSH_PATH% -NoProfile -ExecutionPolicy Bypass -File toml_replace.ps1 -ConfigFile "toml_replace_test.config"

echo.
echo Modified TOML file:
type %TOML_FILE%


echo.
echo Press enter to try the direct-pass method.
pause

echo.
echo Resetting the TOML file to the default...

set TOML_FILE=test_toml_file.toml
(
    echo [package]
    echo name = "example_package"
    echo version = "0.1.0"
    echo readme = "oldreadme.md"
    echo license-files = "oldlicense.txt"
    echo authors = "old author"
    echo numbers = [0]
    echo isStable = false
) > %TOML_FILE%

echo.
echo Original TOML file:
type %TOML_FILE%
echo.

%PWSH_PATH% -NoProfile -File toml_replace.ps1 -File test_toml_file.toml -Replacements "{\"readme\":\"README.md\",\"license-files\":\"[\\\"LICENSE.txt\\\"]\",\"authors\":\"[{name = \\\"Ben\\\", email = \\\"ben@example.com\\\"}]\",\"numbers\":[1,2,3],\"isStable\":true}" -Debug

echo.
echo Modified TOML file:
type %TOML_FILE%

endlocal
pause
