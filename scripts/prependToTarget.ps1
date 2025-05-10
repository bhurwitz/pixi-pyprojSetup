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
param(
    # Target file to be updated.
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetFile,
    
    # Additional items to prepend; each item may be a file or literal text.
    [Parameter(Mandatory = $true, Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$PrependItems,
    
    [int]$DEBUG_LEVEL
)

# We need to add the current path to the PSModulePath so that PS can find the Logging module.
# The module path should be absolute, but we may not want to reveal our full path.
$modulePath_relative = "."
$env:PSModulePath += ";$((Resolve-Path $modulePath_relative).Path)"

Import-Module Logging -DisableNameChecking

if ($DEBUG_LEVEL -gt 0) {
    Set-DebugLevel $DEBUG_LEVEL
    Log-Status "Debugging enabled at level $DEBUG_LEVEL in 'prependToTarget.ps1'."
}

Log-Debug2 "Parameters:"
Log-Debug2 "    Target file: $TargetFile"
Log-Debug2 "    Prepend Items: $($PrependItems)"

# Read the original target file content (or assume empty if it doesn't exist)
if (Test-Path $TargetFile) {
    $originalContent = Get-Content -Path $TargetFile -Raw
    if ($originalContent) {
        $printLen = [Math]::Min(300, $originalContent.Length)
        Log-Debug3 "First $printLen chars of the target file:"
        Log-Debug3 ($originalContent.Substring(0, $printLen))
    }
    else {
        Log-Debug3 "Target file exists but is empty."
    }
} else {
    $originalContent = ""
    Log-Debug3 "Target file doesn't exist yet, so it's empty."
}

# Initialize a variable to hold all prepended content
$prependContent = ""

# Loop over each additional parameter in the order provided.
foreach ($item in $PrependItems) {
    if (Test-Path $item) {
        # If the item is a file, read its content
        $content = Get-Content -Path $item -Raw
        Log-Debug2 "Value '$item' is interpreted as a file. Adding its contents."
    }
    else {
        # If not, treat it as literal text.
        $content = $item
        Log-Debug2 "Value '$item' is interpreted as literal text."
    }
    # Append the content along with a newline separator.
    $prependContent += $content + "`r`n"
}

# Optionally add an extra newline between the prepended block and the original content.
$combined = $prependContent + "`r`n" + $originalContent

# Write the combined content back to the target file.
Set-Content -Path $TargetFile -Value $combined

Log-Debug3 "First 300 chars of the target file after prepending:"
Log-Debug3 ($combined.Substring(0, [Math]::Min(300, $combined.Length)))

# (Optional) Write an informational message.
Log-Debug2 "Prepending complete. Updated '$TargetFile'."
