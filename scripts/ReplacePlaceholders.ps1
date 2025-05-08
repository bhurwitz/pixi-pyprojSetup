<#
.SYNOPSIS
    A brief overview of what the script does.

.DESCRIPTION
    This script demonstrates how to perform [task/operation] using PowerShell.
    Expand on what the script accomplishes and any important considerations.

.PARAMETER Param1
    Description of the first parameter.

.PARAMETER Param2
    Description of the second parameter (optional).

.EXAMPLE
    .\MyScript.ps1 -Param1 "Value" -Param2 "AnotherValue"
    # Brief explanation of what this example demonstrates.

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0.0
    License: MIT (or other license)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,

    [Parameter(Mandatory=$true)]
    [string]$EnvFile,

    [Parameter()]
    [int]$MaxIterations = 10,

    [Parameter()]
    [int]$DEBUG_LEVEL
)

# We need to add the current path to the PSModulePath so that PS can find the Logging module.
# The module path should be absolute, but we may not want to reveal our full path.
$modulePath_relative = "."
$modulePath_abs = (Resolve-Path $modulePath_relative).Path
Write-Host "Path to this folder: $modulePath_abs"
$env:PSModulePath += ";$modulePath_abs"
Write-Host "PS module path: $env:PSModulePath"

# Import the Logging module for nice printing. It lives in <Documents\PowerShell (and WindowsPowerShell)\Modules>.
Import-Module Logging -DisableNameChecking

# --- Determine the Debug State ---
# The following logic checks (in priority order):
#   1. If the caller explicitly disabled debug (via -NoDebug),
#   2. If external configuration says to enable debug,
#   3. If the built-in -Debug parameter was used,
#   4. If the global $DebugPreference has been set.
#   5. Otherwise, leave debugging off.
# This explicitly ignores the other two debugging settings ("Inquire" and "Stop").

if ($DEBUG_LEVEL -eq 0) {
    $DebugPreference = 'SilentlyContinue'
    $Debug = [switch]$False
# } elseif ($externalConfig.DebugEnabled -eq $true) {
    # $DebugPreference = 'Continue'
} elseif ($PSBoundParameters.ContainsKey("Debug") -or $Debug) {
    # ($Debug is the built-in switch variable; it’s $true if -Debug was passed)
    $DebugPreference = 'Continue'
    $Debug = [switch]$True
    Set-DebugLevel 1
} elseif ($DebugPreference -eq 'Continue' -and -not $DEBUG_LEVEL) {
    $Debug = [switch]$True
    Set-DebugLevel 1
} elseif ($DebugPreference -eq 'SilentlyContinue' -and -not $DEBUG_LEVEL) {
    $Debug = [switch]$False
    Set-DebugLevel 0
} elseif ($DEBUG_LEVEL -gt 0) {
    $DebugPreference = 'Continue'
    $Debug = [switch]$True
    Set-DebugLevel $DEBUG_LEVEL
# } else {
    # $DebugPreference = 'SilentlyContinue'
    # $Debug = [switch]$False
}

if ($DEBUG_LEVEL -gt 0) {
    Log-Status "Debugging is enabled at level $DEBUG_LEVEL in 'ReplacePlaceholders.ps1'."
}

if ((-not (Test-Path $InputFile)) -or ((Get-Item $InputFile).length -eq 0)) {
    Log-Warning "The input file passed to 'ReplacePlaceholders.ps1' is missing or empty. No replacements performed."
    exit 1
}

if ((-not (Test-Path $EnvFile)) -or ((Get-Item $EnvFile).length -eq 0)) {
    Log-Warning "The placeholders file passed to 'ReplacePlaceholders.ps1' is missing or empty. No replacements performed."
    exit 1
}


# Log: Show full environment file contents.
Log-Debug2 "Loading environment file: $EnvFile"
$lines = Get-Content $EnvFile
Log-Debug2 "Environment file has $($lines.Count) line(s):"
$lines | ForEach-Object { Log-Debug2 "  $_" }

# Build the replacements table.
$replacements = @{}
foreach ($line in $lines) {
    Log-Debug3 "`nProcessing line: $line"
    if ($line -match '^(.*?)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        Log-Debug3 "Parsed key: '$key' and value: '$value'"
        
        # Create placeholder by surrounding the key with braces.
        $placeholder = '{' + $key + '}'
        Log-Debug3 "Mapping placeholder '$placeholder' to value '$value'"
        $replacements[$placeholder] = $value
    } else {
        Log-Debug3 "Line did not match expected pattern: $line"
    }
}

# Log: Show the entire replacement table.
Log-Debug2 "`nReplacement table:"
$replacements.GetEnumerator() | ForEach-Object {
   Log-Debug2 "  $($_.Key) -> $($_.Value)"
}

# Read the input file.
Log-Debug3 "`nReading input file: $InputFile"
$fileContent = Get-Content $InputFile -Raw
Log-Debug2 "Original file content (first 300 chars):"
Log-Debug2 ($fileContent.Substring(0, [Math]::Min(300, $fileContent.Length)))
 
# Perform the replacements repeatedly to resolve nested placeholders.
for ($i = 0; $i -lt $MaxIterations; $i++) {
    # Write-Host "Starting iteration $i"
    $prevContent = $fileContent
    foreach ($key in $replacements.Keys) {
        $escapedKey = [regex]::Escape($key)
        if ($fileContent -match $escapedKey) {
            Log-Debug3 "`nReplacing placeholder '$key' with '$($replacements[$key])'"
            $fileContent = $fileContent -replace $escapedKey, $replacements[$key]
        }
    }
    if ($fileContent -eq $prevContent) {
        Log-Debug3 "`nNo further changes detected in iteration $i; nested placeholder replacement is complete."
        break
    }
}
if ($i -eq $MaxIterations) {
    Log-Warning "`nWarning: Maximum iterations reached. Some nested placeholders may still be unresolved."
}

# Log: Show final content before writing out.
Log-Debug2 "`nFinal file content (first 300 chars):"
Log-Debug2 ($fileContent.Substring(0, [Math]::Min(300, $fileContent.Length)))

# Write the content to the output file.
Set-Content $OutputFile $fileContent
Log-Debug2 "`nOutput file written successfully to: $OutputFile"






##################################### The below only worked for a single pass.
# # Read the input file.
# Write-Host "`nReading input file: $InputFile"
# $fileContent = Get-Content $InputFile -Raw
# Write-Host "Original file content (first 300 chars):"
# Write-Host ($fileContent.Substring(0, [Math]::Min(300, $fileContent.Length)))
 
# # Perform the replacements only when the placeholder exists.
# foreach ($key in $replacements.Keys) {
    # $escapedKey = [regex]::Escape($key)
    # if ($fileContent -match $escapedKey) {
        # Write-Host "`nReplacing placeholder '$key' with '$($replacements[$key])'"
        # $fileContent = $fileContent -replace $escapedKey, $replacements[$key]
    # } else {
        # Write-Host "`nPlaceholder '$key' not found in the file content; skipping replacement."
    # }
# }

# # Log: Show final content before writing out.
# Write-Host "`nFinal file content (first 300 chars):"
# Write-Host ($fileContent.Substring(0, [Math]::Min(300, $fileContent.Length)))

# # Write the content to the output file.
# Set-Content $OutputFile $fileContent
# Write-Host "`nOutput file written successfully to: $OutputFile"
