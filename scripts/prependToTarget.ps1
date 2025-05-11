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

<# PrependToTarget.ps1
.SYNOPSIS
    Prepends an arbitrary number of strings and/or text from files to a target.

.DESCRIPTION
    Loops over all the passed string and files, buids a single string from all those with '+=' and with two blank lines between them, and then writes out a file with that string and then two empty line in front of the original file text.

.PARAMETER TargetFile
    The file to prepend to. If the file doesn't exist, it will be created. This is mandatory and must be passed first.

.PARAMETER PrependItems
    A list of explicit strings and/or filepaths with text to be prepended. The prepending order is the order of this list. If this parameter is given last, arguments may be given as individual values, e.g. "string1" "file1.txt" "file2.txt", and will be collated into a list automatically. 
    
.PARAMETER UseLF
    A flag that, if set, will set the empty lines as 'LF' (`n), as preferred by Unix-based filesystems, rather than the default 'CRLF' (`r`n) preferred by Windows systems.
    
.PARAMETER DEBUG_LEVEL
    An integer that specifies the level of debugging verbosity that we're interested in; 0 is no debugging whereas 4 is more than you probably want. If this is left undefined, it will fall back to anything set externally within the same PowerShell instance.

.EXAMPLE
    .\prependToTarget.ps1 -TargetFile "myFile.py" -PrependItems "string1", "file1.txt", "file2.md" -DEBUG_LEVEL 2
    # This will prepend "string1", the text in 'file1.txt', and the text in 'file2.md' (in order) to the top of 'myFile.py' with 'CRLF's in between everything. Some debugging statements will print as well.
    
    .\prependToTarget.ps1 -TargetFile "myFile.py" -UseLF "string2", "file3.txt", "file4.md"
    # This will prepend "string2", the text in 'file3.txt', and the text in 'file4.md' (in order) to the top of 'myFile.py' with 'LF's in between everything. No debugging will happen. 
    
    $items = @("item1", "item2", "item3")
    .\prependToTarget.ps1 "testfile" -PrependItems $items
    # This will prepend the strings "item1", "item2", and "item3" (in that order) to "testfile". You can also put the @(...) notation directly into the function call.


.NOTES
    Author: Ben Hurwitz
    Email: bchurwitz+pixi_pyprojSetup@gmail.com
    Date: 2025-May-10
    Version: 1.0.0
    License: GNU GPL v3.0 (see above)
    Compatability: PowerShell 5.1 and 7
#>

[CmdletBinding()]
param(
    # Target file to be updated.
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetFile,
    
    # Additional items to prepend; each item may be a file or literal text.
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$PrependItems,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseLF = $false,
    
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

if ($PrependItems.Count -eq 0) {
    Log-Debug1 "Nothing was given to be prepended! Goodbye."
    exit 1
}

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

# Set the 'newline' variable
if ($UseLF) {
    $newline = "`n`n"
}
else {
    $newline = "`r`n"
}

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
    $prependContent += $content + $newline
}

# Optionally add an extra newline between the prepended block and the original content.
$combined = $prependContent + $newline + $originalContent

# Write the combined content back to the target file.
Set-Content -Path $TargetFile -Value $combined

Log-Debug3 "First 300 chars of the target file after prepending:"
Log-Debug3 ($combined.Substring(0, [Math]::Min(300, $combined.Length)))

# (Optional) Write an informational message.
Log-Debug2 "Prepending complete. Updated '$TargetFile'."

exit 0
