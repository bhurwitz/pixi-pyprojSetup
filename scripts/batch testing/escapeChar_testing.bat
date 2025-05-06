@echo off
REM setlocal EnableDelayedExpansion

:: Simulate problematic input
REM set "description=Here's a string with: backticks`, pipes ^| , ampersands ^&, less ^<, greater ^>, semicolons ^;, percent sign %%, dollars ^$, at-signs ^@, quotes \", and single ' quotes!"
REM echo Original: !description!

:: If we're asking for user input, comment out the previous two lines and uncomment these next ones
:: set /p "description=Enter a description with special characters: "
:: echo You entered: !description!
:: set "description=!description!"

REM =========================== METHOD 1 ==============================
REM ==== Escape each character individually.
REM ====

:: Escape it for PowerShell using the character-replacment method
REM call :escape_for_powershell "!description!"

:: Alternative ONE: using PowerShell environmental variables (DIDN'T WORK)
REM set "PS_DESCRIPTION=%description%"
REM powershell -Command "Write-Host 'Escaped description:  $env:PS_DESCRIPTION"

:: Alternative TWO: using PowerShell encoding (DIDN'T WORK)
REM :: Build the PowerShell command string.
REM :: Notice we embed the description directly; if necessary, you could perform escaping via a subroutine.
REM set "psCommand=Write-Host 'Escaped description: %description%'"
REM :: Encode the command using PowerShell (this step uses PowerShell to encode our command).
REM for /f "delims=" %%A in ('powershell -NoProfile -Command "[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('%psCommand%'))"') do (set "encodedCmd=%%A")
REM :: Execute the encoded command.
REM powershell -NoProfile -EncodedCommand %encodedCmd%

:: Alternative THREE: via global parameter (WORKED)
REM set "rawInput=%description%"
REM call :escape_for_powershell

:: Print the escaped string
REM echo Escaped: !escaped!

REM :: Example of passing it to PowerShell
REM powershell -Command "Write-Host 'Escaped description: '!escaped!'"


REM ========================== METHOD 2 ==============================
REM ==== Encode the string, then write it.
REM ==== 

REM @echo off

REM set "filePath=escapeChar_testing.txt"
REM set "newFilePath=escapeChar_testing_output.txt"

REM :: Escape any embedded single quotes by doubling them.
REM :: This converts each ' into ''
REM set "description=%description:'='''%"

REM :: --- Build the PowerShell Command String ---
REM :: In our example the command reads a file, performs some replacements,
REM :: and writes the file back.
REM :: Notice how we embed our variables directly.
REM set "psCommand=$file = Get-Content '%filePath%' -Raw; $replacements = @{'{description}' = '%description%'}; foreach ($key in $replacements.Keys) { $file = $file -replace $key, $replacements[$key] }; Set-Content '%newFilePath%' $file"

REM :: Optional: Display the command for debugging.
REM echo.
REM echo PS Command: !psCommand!
REM echo.

REM :: Because this command may contain problematic symbols, we need to generate a Base64
REM :: encoding using PowerShell itself.
REM :: PowerShell will encode our command in UTF-16LE as required by the -EncodedCommand switch.
REM for /f "delims=" %%A in ('powershell -NoProfile -Command "[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('%psCommand%'))"') do set "encodedCmd=%%A"

REM :: Optional: Display the encoded command for debugging.
REM echo Encoded Command: %encodedCmd%

REM :: --- Execute the Encoded Command ---
REM :: The entire command is now safely transmitted to PowerShell with -EncodedCommand.
REM powershell -NoProfile -EncodedCommand %encodedCmd%



REM ======================= METHOD 3 ======================================
REM ==== Write the encoded string out to a temp file, read it, encode it, execute it.
REM ====

REM @echo off

REM :: --- Gather User Input and Pre-sanitize ---
REM REM set /p "description=Enter a description: "
REM :: For PowerShell single-quoted literals, double any single quotes.
REM set "version=%description:'='''%"

REM :: --- Define Other Variables ---
REM set "filePath=escapeChar_testing_input.txt"
REM set "newFilePath=escapeChar_testing_output.txt"
REM set "package=MyPackage"

REM :: --- Build the PowerShell Command String as a Single Line ---
REM :: (All parts are combined with semicolons to avoid using caret continuations.)
REM set "psCommand=$file=Get-Content '%filePath%' -Raw; $replacements=@{'{package}'='%package%'; '{version}'='%version%'}; foreach ($key in $replacements.Keys){$file=$file -replace $key, $replacements[$key]}; Set-Content '%newFilePath%' $file"

REM :: Optional: Output the command for debugging.
REM :: Use a syntax that avoids interpretation of special characters:
REM echo(PS Command: !psCommand!

REM :: --- Write the Command to a Temporary File ---
REM set "tmpFile=%TEMP%\psCommand.txt"
REM > "%tmpFile%" echo(!psCommand!

REM :: --- Encode the Command Using PowerShell ---
REM :: By reading from the temporary file, we avoid inline parsing issues.
REM for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content -Path '%tmpFile%' -Raw)))"`) do set "encodedCmd=%%A"

REM :: Optional: Output the encoded command.
REM echo(Encoded Command: !encodedCmd!

REM :: --- Execute the Encoded Command ---
REM powershell -NoProfile -EncodedCommand !encodedCmd!

REM :: --- Clean Up ---
REM del "%tmpFile%"


REM ======================= METHOD 4 ======================================
REM ==== Write the PS command out to a temp file, then execute the file essentially
REM ====

@echo off
setlocal EnableDelayedExpansion

:: Ensure we’re in the same directory as the batch file
REM cd /d %~dp0

:: --- Define our variables ---
REM set "description=Here's a string with: backticks`, pipes |, ampersands &, less <, greater >, semicolons ;, percent sign %, dollars $, at-signs @, quotes \", and single ' quotes!"
setlocal DisableDelayedExpansion
set /p "description=Enter a description: "
REM endlocal & set "description=%description%"
REM endlocal & set "MYDESC=%description%"

set "filePath=scripts\escapeChar_testing_input.txt"
set "newFilePath=scripts\escapeChar_testing_output.txt"
set "package=MyPackage"

:: Use current directory for temp file
set "tempPSFile=scripts\temp.ps1"

REM REM Optional: Show that MYDESC now holds the full text (including any double quotes)
REM echo The description is: !MYDESC!
REM pause

:: --- Write the PowerShell script to a temporary file ---
(
    echo param^(
    echo     [string]$filePath,
    echo     [string]$newFilePath,
    echo     [string]$package,
    echo     [string]$version
    echo ^)
    echo $version = $env:description
    echo $file = Get-Content $filePath -Raw
    echo $replacements = @{'{package}' = $package; '{version}' = $version}
    echo foreach ^($key in $replacements.Keys^) { $file = $file -replace $key, $replacements[$key] }
    echo set-Content $newFilePath $file
) > "%tempPSFile%"

:: --- (Optional) Debug: list the file content and show the file path ---
REM type "%tempPSFile%"
REM echo Temporary script file at: "%tempPSFile%"
REM pause

:: --- Execute the temporary PowerShell script, passing in the parameters
powershell -NoProfile -File "%tempPSFile%" -filePath "%filePath%" -newFilePath "%newFilePath%" -package "%package%" -version "%description%"

REM Re-enable delayed expansion if needed for subsequent processing.
REM endlocal EnableDelayedExpansion
endlocal 
REM setlocal EnableDelayedExpansion

:: --- Clean Up ---
del "%tempPSFile%"




REM ======================= METHOD 5 (DIDN'T WORK) =================================
REM ==== Write an inline PS function, write it to a file, encode that, then run the encoded command with the problematic string as a parameter
REM ====

REM @echo off
REM :: Ensure we’re in the same directory as the batch file
REM setlocal EnableDelayedExpansion

REM :: --- Define our variables ---
REM set "description=Here's a string with: backticks`, pipes |, ampersands &, less <, greater >, semicolons ;, percent sign %, dollars $, at-signs @, quotes \", and single ' quotes!"
REM set "filePath=scripts\escapeChar_testing_input.txt"
REM set "newFilePath=scripts\escapeChar_testing_output.txt"
REM set "package=MyPackage"

REM :: Use current directory for temp command file
REM set "tempCmdFile=scripts\psCommand.txt"

REM :: --- Write the inline PowerShell command to a temporary file ---
REM (
  REM echo function Invoke-Replacements {
  REM echo     param^( [string]$originalFile, [string]$newWrittenFile, [string]$mypackage, [string]$myversion ^)
  REM echo     $file = Get-Content $originalFile -Raw;
  REM echo     $replacements = @{'{package}' = $mypackage; '{version}' = $myversion};
  REM echo     foreach ^($key in $replacements.Keys^) {
  REM echo         $file = $file -replace $key, $replacements[$key]
  REM echo     }
  REM echo     Set-Content $newWrittenFile $file;
  REM echo }
  REM echo Invoke-Replacements -originalFile $args[0] -newWrittenFile $args[1] -mypackage $args[2] -myversion $args[3];
REM ) > "%tempCmdFile%"

REM :: --- (Optional) Debug: list the command file content ---
REM type "%tempCmdFile%"
REM echo Temporary command file at: "%tempCmdFile%"
REM pause

REM :: --- Encode the command file to Base64 (Unicode encoding) ---
REM for /f "usebackq delims=" %%A in (`
  REM powershell -NoProfile -Command "[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content -Path '%tempCmdFile%' -Raw)))"
REM `) do set "encodedCmd=%%A"

REM echo Encoded command: !encodedCmd!
REM pause

REM :: --- Execute the encoded command while passing parameters ---
REM REM powershell -NoProfile -EncodedCommand !encodedCmd! -originalFile "%filePath%" -newWrittenFile "%newFilePath%" -mypackage "%package%" -myversion "%description%"
REM :: use -ArgumentList to supply the parameter values in the order defined in the script's param block.
REM powershell -NoProfile -EncodedCommand !encodedCmd! -ArgumentList "%filePath%","%newFilePath%","%package%","%description%"

REM :: --- Clean Up ---
REM del "%tempCmdFile%"





REM ================= END OF SCRIPT ===========================

REM pause
exit /b


:escape_for_powershell
:: %1 = input string
:: returns sanitized string in `!escaped!`
setlocal EnableDelayedExpansion

if "%~1" neq "" (
    set "rawInput=%~1"
)

:: Escape single quotes by doubling them
set "escaped=!rawInput:'='''!"

:: Escape backticks by doubling them
set "escaped=!escaped:`=``!"

:: Escape characters that PowerShell uses for control
set "escaped=!escaped:|=`|!"
set "escaped=!escaped:&=`&!"
set "escaped=!escaped:<=`<!"
set "escaped=!escaped:>=`>!"
set "escaped=!escaped:;=`;!"
set "escaped=!escaped:$=`$!"
set "escaped=!escaped:@=`@!"
set "escaped=!escaped:"=`"!"
set "escaped=!escaped:%%=%%!"

:: Backslashes are generally safe, but can be escaped if needed:
:: set "escaped=!escaped:\=`\!"

endlocal & set "escaped=%escaped%"
goto :eof

REM :escape_for_powershell
REM rem ============================================================
REM rem This subroutine expects the raw input as %~1.
REM rem It sanitizes characters that are problematic when embedding
REM rem the text in PowerShell commands via CMD.
REM rem The problematic characters we handle here are:
REM rem   - Backtick (`): escaped by doubling them.
REM rem   - Pipe (|): replaced with `|
REM rem   - Ampersand (&): replaced with `&
REM rem   - Percent sign (%): doubled to safeguard against CMD variable expansion.
REM rem   - Double quotes ("): escaped as `"
REM rem   - Single quotes ('): doubled (to work properly in single-quoted literals)
REM rem ============================================================
REM setlocal EnableDelayedExpansion
REM set "output=%~1"

REM :: 1. First, escape all backticks (the escape char itself) by doubling them.
REM set "output=!output:`=``!"

REM :: 2. Escape pipes so that CMD does not treat them as a command separator.
REM set "output=!output:|=`|!"

REM :: 3. Escape ampersands by prefixing them with a backtick.
REM set "output=!output:&=`&!"

REM :: 4. Escape percent signs by doubling them.
REM ::    This ensures that any % in the string isn’t misinterpreted as a variable marker.
REM set "output=!output:%%=%%%%!"

REM :: 5. Escape double quotes.
REM ::    In many PowerShell contexts a double quote can break a double-quoted string,
REM ::    so we prefix them with a backtick.
REM set "output=!output:"=`"!"

REM :: 6. Escape single quotes by doubling them.
REM ::    Inside single-quoted PowerShell strings, a single quote is escaped by doubling.
REM set "output=!output:'='''!"

REM endlocal & set "escaped=%output%"
REM goto :EOF