<# 
Package: pixi_pyprojSetup

Copyright (C) 2025  Ben Hurwitz <bchurwitz+pixi_pyprojSetup> under GNU GPL v3.0.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

<# ReplacePlaceholders.ps1
.SYNOPSIS
    Replaces placeholder terms with mapped values.

.DESCRIPTION
    This script uses a mapping, as defined by a given 'PlaceholdersFile', to replace specific terms in the target file that are wrapped in curly braces with their mapped values. It takes this file, which is made up of one "key=value" pair per line, and generates a hashtable with the placeholders (keys) from the file used as the keys of the table mapped to the associated replacements (values). Then it loops up to $MaxIterations number of times over the list of hashtable keys, replacing each with the associate value, thereby enabling deeply-nested keys. For example, if the $PlaceholdersFile has a line 'name=myName' (without quotes), anywhere in the $InputFile where the string '{name}' (without quotes but with braces) appears will be replaced with 'myName' (still without quotes and without braces). 

.PARAMETER InputFile
    The file to have the operation completed upon.

.PARAMETER OutputFile
    The resulting file. This may be the same as the input file if you're overwriting the input.
    
.PARAMETER PlaceholdersFile
    The mapping file. There is no required filetype. It needs only to have one 'placeholder=replacement' pair per line, in that specific format. 
    
.PARAMETER MaxIterations
    The maximum number of iterations of the placeholders list the script will loop through. This generally refers to the maximum nesting depth of placeholders. It defaults to 10.
    
.PARAMETER DEBUG_LEVEL
    An integer that specifies the level of debugging verbosity that we're interested in; 0 is no debugging whereas 4 is more than you probably want. If this is left undefined, it will fall back to anything set externally within the same PowerShell instance.

.EXAMPLE
    .\ReplacePlaceholders.ps1 -InputFile main.py -OutputFile main_replaced.py -PlaceholdersFile replacementMapping.myfiletype
    # This takes in 'main.py', applies replacements according to 'replacementMapping.myfiletype', and writes the resulting file to 'main_replaced.py'

.NOTES
    Author: Ben Hurwitz
    Email: bchurwitz+pixi_pyprojSetup@gmail.com
    Date: 2025-May-10
    Version: 1.0.0
    License: GNU GPL v3.0 (see above)
    Compatability: PowerShell 5.1 and 7
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,

    [Parameter(Mandatory=$true)]
    [string]$PlaceholdersFile,

    [Parameter()]
    [int]$MaxIterations = 10,

    [Parameter()]
    [int]$DEBUG_LEVEL
)

# We need to add the current path to the PSModulePath so that PS can find the Logging module.
# The module path should be absolute, but we may not want to reveal our full path.
$modulePath_relative = "."
$modulePath_abs = (Resolve-Path $modulePath_relative).Path
$env:PSModulePath += ";$modulePath_abs"

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

Log-Debug2 "Parameters:"
Log-Debug2 "    Input file: $InputFile"
Log-Debug2 "    Output file: $OutputFile"
Log-Debug2 "    Placeholders file: $PlaceholdersFile"
Log-Debug2 "    Max iterations: $MaxIterations"


if ((-not (Test-Path $InputFile)) -or ((Get-Item $InputFile).length -eq 0)) {
    Log-Warning "The input file passed to 'ReplacePlaceholders.ps1' is missing or empty. No replacements performed."
    exit 1
}

if ((-not (Test-Path $PlaceholdersFile)) -or ((Get-Item $PlaceholdersFile).length -eq 0)) {
    Log-Warning "The placeholders file passed to 'ReplacePlaceholders.ps1' is missing or empty. No replacements performed."
    exit 1
}


# Log: Show full environment file contents.
# Log-Debug3 "Loading environment file: $PlaceholdersFile"
$lines = Get-Content $PlaceholdersFile
Log-Debug3 "Environment file has $($lines.Count) line(s):"
$lines | ForEach-Object { Log-Debug3 "  $_" }

# Build the replacements table.
$replacements = @{}
foreach ($line in $lines) {
    Log-Debug4 "`nProcessing line: $line"
    if ($line -match '^(.*?)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        Log-Debug4 "    Parsed key: '$key' and value: '$value'"
        
        # Create placeholder by surrounding the key with braces.
        $placeholder = '{' + $key + '}'
        Log-Debug4 "    Mapping placeholder '$placeholder' to value '$value'"
        $replacements[$placeholder] = $value
    } else {
        Log-Debug4     "Line did not match expected pattern: $line"
    }
}

# Log: Show the entire replacement table.
Log-Debug3 "`nReplacement table:"
$replacements.GetEnumerator() | ForEach-Object {
   Log-Debug3 "  $($_.Key) -> $($_.Value)"
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
            Log-Debug4 "`nReplacing placeholder '$key' with '$($replacements[$key])'"
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
