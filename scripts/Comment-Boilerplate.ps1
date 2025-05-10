<#
.SYNOPSIS
    Processes a boilerplate file to ensure each line is properly commented.
.DESCRIPTION
    Given a file, its extension, and a full output file path, this script reads each line and ensures that the correct
    comment marker is applied. In general the script checks (by default, the first 10 characters) for an existing comment marker.
    For lines that already start with one (after any leading whitespace), it preserves the column where the content begins
    by replacing the marker with the correct one and inserting enough spaces. Lines without an existing marker are simply
    prepended with the proper marker.
    
    For Markdown (.md) files the user is given three options:
      1) Wrapped style: Each line is wrapped in HTML comment tags (<!-- and -->).
      2) Inline style using a '%' character.
      3) Custom inline style: The user enters a custom comment marker.
      
.PARAMETER Boilerplate
    Full path to the input file.
.PARAMETER Extension
    The file extension (e.g. ".py", ".md", ".bat", etc.) that determines which commenting style to use.
.PARAMETER OutputFile
    The full file path where the processed file will be written. The directory in the path will be created if it doesn't exist.
.PARAMETER ScanLength
    (Optional) The number of characters from the start of each line to scan for an existing comment marker.
    Defaults to 10.
.EXAMPLE
    .\Comment-Boilerplate.ps1 -Boilerplate "C:\Test\Boilerplate.md" -Extension ".md" -OutputFile "C:\Test\Output\Boilerplate.md"
    Will prompt you to choose one of the three MD comment styles, then process the Markdown file accordingly, writing the output to the specified path.
    
.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0.0
    License: MIT (or other license)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Boilerplate,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Extension,

    [Parameter(Mandatory = $true, Position = 2)]
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [int]$ScanLength = 10,
    
    [int]$DEBUG_LEVEL = $null
)

# We need to add the current path to the PSModulePath so that PS can find the Logging module.
# The module path should be absolute, but we may not want to reveal our full path.
$modulePath_relative = "."
$env:PSModulePath += ";$((Resolve-Path $modulePath_relative).Path)"

Import-Module Logging -DisableNameChecking

if ($Debug -or ($DebugPreference -eq 'Continue')) {
    $DEBUG_LEVEL = [Math]::Max(1, $DEBUG_LEVEL)
}
if ($DEBUG_LEVEL -gt 0) {
    Set-DebugLevel $DEBUG_LEVEL
    Log-Status "Debugging level set to $DEBUG_LEVEL in 'Comment-Boilerplate.ps1'."
    $DebugPreference = 'Continue'
    $Debug = [switch]$true
}
else {
    $DebugPreference = 'SilentlyContinue'
    $Debug = [switch]$false
}


Log-Debug2 "Starting Comment-Boilerplate processing."
Log-Debug3 "    Boilerplate: $Boilerplate"
Log-Debug3 "    Extension: $Extension"
Log-Debug3 "    OutputFile: $OutputFile"
Log-Debug3 "    ScanLength: $ScanLength"

# Determine the comment marker based on the file extension.
# For most extensions we use a fixed marker; for Markdown (.md) we offer three user options.
$commentChar = $null
$mdStyle = $null   # Will hold either "Wrapped" or "Inline"
switch -Regex ($Extension.ToLower()) {
    '^\.py$'   { $commentChar = "#"; break }
    '^\.bat$'  { $commentChar = "::"; break }   # 'REM' will echo, '::' doesn't.
    '^\.cmd$'  { $commentChar = "::"; break }   # 'REM' will echo, '::' doesn't.
    '^\.ps1$'  { $commentChar = "#"; break }    
    '^\.yml$'  { $commentChar = "#"; break }
    '^\.yaml$' { $commentChar = "#"; break }
    '^\.cpp$'  { $commentChar = "//"; break }
    '^\.c$'    { $commentChar = "//"; break }
    '^\.toml$' { $commentChar = "#"; break }
    '^\.ini$'  { $commentChar = "#"; break }
    '^\.rst$'  { $commentChar = ".."; break }
    '^\.cfg$'  { $commentChar = "#"; break }
    '^\.sh$'   { $commentChar = "#"; break }
    '^\.md$'   {
        Write-Host "Select Markdown comment style:"
        Write-Host "  1) Wrapped style (HTML comments: <!-- content -->)"
        Write-Host "  2) Inline style using '%' as the marker"
        Write-Host "  3) Custom inline style (enter your own marker)"
        $mdOption = Read-Host "Enter option number (1, 2, or 3)"
        switch ($mdOption) {
            "1" {
                $mdStyle = "Wrapped"
                $commentChar = "<!--"
                $mdEndMarker = "-->"
            }
            "2" {
                $mdStyle = "Inline"
                $commentChar = "%"
            }
            "3" {
                $mdStyle = "Inline"
                $commentChar = Read-Host "Enter your custom Markdown inline comment marker"
            }
            default {
                Write-Host "Invalid option; defaulting to Wrapped style."
                $mdStyle = "Wrapped"
                $commentChar = "<!--"
                $mdEndMarker = "-->"
            }
        }
        break
    }
    default    {
        $prompt = "Enter the comment character for '$Extension'"
        if ($Host.UI -and $Host.UI.RawUI) {
            $commentChar = Read-Host $prompt
        }
        else {
            $commentChar = "#"
            Write-Host "Non-interactive session detected. Defaulting to '#' for unknown extension."
        }
        break
    }
}
Log-Debug2 "Using comment marker: '$commentChar'"
if ($Extension.ToLower() -eq ".md" -and $mdStyle -eq "Wrapped") {
    Log-Debug2 "Markdown style selected: Wrapped (HTML comments)"
} elseif ($Extension.ToLower() -eq ".md" -and $mdStyle -eq "Inline") {
    Log-Debug2 "Markdown style selected: Inline (using marker '$commentChar')"
}

# Create output directory from the given file path if needed.
$outputDir = [System.IO.Path]::GetDirectoryName($OutputFile)
if (-not (Test-Path $outputDir)) {
    Log-Debug3 "Output directory does not exist; creating: $outputDir"
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

if (-not (Test-Path $Boilerplate)) {
    Log-Error "Boilerplate file '$Boilerplate' not found."
    exit 1
}

# For non-Markdown files, we use a pattern matching known markers.
# (For inline Markdown, we will build a pattern based on the user’s choice.)
$defaultPattern = '^(?<leading>\s*)(?<marker>#|%|REM|//|\.\.)(?<after>\s*)(?<content>.*)$'

$processedLines = foreach ($line in Get-Content -Path $Boilerplate) {

    if ($Extension.ToLower() -eq ".md") {
        # For Markdown files, if Wrapped style is selected, process each line with HTML comment logic.
        if ($mdStyle -eq "Wrapped") {
            # Check if the line is already wrapped in an HTML comment.
            if ($line -match '^\s*<!--\s*(?<content>.*?)(\s*-->)?\s*$') {
                $content = $matches.content
                Log-Debug3 "Standardizing existing wrapped Markdown comment: '$line'"
                $newLine = "<!-- $content -->"
            }
            else {
                Log-Debug3 "Wrapping line in HTML comment: '$line'"
                $newLine = "<!-- $line -->"
            }
        }
        else {
            # Inline style: build an inline pattern based on the chosen marker.
            $inlinePattern = '^(?<leading>\s*)' + [regex]::Escape($commentChar) + '(?<after>\s*)(?<content>.*)$'
            $firstPart = if ($line.Length -ge $ScanLength) { $line.Substring(0, $ScanLength) } else { $line }
            if ($firstPart -match '^\s*' + [regex]::Escape($commentChar)) {
                if ($line -match $inlinePattern) {
                    $origLeading = $matches.leading      # Leading whitespace
                    $origAfter   = $matches.after         # Whitespace after the marker
                    $origContent = $matches.content         # The rest of the line

                    # Compute where the content originally began.
                    $origOffset = $origLeading.Length + $commentChar.Length + $origAfter.Length
                    $neededSpacesCount = $origOffset - $commentChar.Length
                    if ($neededSpacesCount -lt 1) { $neededSpacesCount = 1 }
                    $neededSpaces = " " * $neededSpacesCount

                    Log-Debug3 "Standardizing existing inline MD comment: '$line'"
                    $newLine = "$commentChar$neededSpaces$origContent"
                }
                else {
                    Log-Debug3 "Fallback inline: Prepending MD marker to line: '$line'"
                    $newLine = "$commentChar $line"
                }
            }
            else {
                Log-Debug3 "No inline MD marker found; prepending: '$line'"
                $newLine = "$commentChar $line"
            }
        }
    }
    else {
        # Non-Markdown files: use the default logic.
        $firstPart = if ($line.Length -ge $ScanLength) { $line.Substring(0, $ScanLength) } else { $line }
        if ($firstPart -match '^\s*(#|%|REM|//|\.\.)') {
            if ($line -match $defaultPattern) {
                $origLeading = $matches.leading       # All leading whitespace
                $origMarker  = $matches.marker          # The detected marker
                $origAfter   = $matches.after           # Whitespace after the marker
                $origContent = $matches.content          

                $origOffset = $origLeading.Length + $origMarker.Length + $origAfter.Length
                $neededSpacesCount = $origOffset - $commentChar.Length
                if ($neededSpacesCount -lt 1) { $neededSpacesCount = 1 }
                $neededSpaces = " " * $neededSpacesCount

                if ($origMarker -ne $commentChar) {
                    Log-Debug3 "Replacing marker '$origMarker' with '$commentChar' in line: '$line'"
                }
                else {
                    Log-Debug3 "Standardizing whitespace for line with correct marker: '$line'"
                }
                $newLine = "$commentChar$neededSpaces$origContent"
            }
            else {
                Log-Debug3 "Fallback: Prepending comment marker to line: '$line'"
                $newLine = "$commentChar $line"
            }
        }
        else {
            Log-Debug3 "No marker found: Prepending comment marker to line: '$line'"
            $newLine = "$commentChar $line"
        }
    }
    $newLine
}

Log-Debug2 "Writing output to: $OutputFile"
$processedLines | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "Processed file saved as: $OutputFile"
