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

<# Convert-JsonWithErrorMapping.ps1
.SYNOPSIS
    A wrapper for Convert-Json with some extra error handling.

.DESCRIPTION
    This script provides a wrapper for the Convert-Json function with a try/catch block for some more verbose error handling.

.PARAMETER JsonString
    The JSON string that is being converted. 

.EXAMPLE
    # You dot source the file first
    . <path-to-parent>\Convert-JsonWithErrorMapping.ps1
    
    # Now you can call the function
    Convert-JsonWithErrorMapping -JsonString $json
    
    # If you have JSON in a file, do this sequence:
    $rawJSON = Get-Content $JSONfile -Raw
    $processedJSON = Convert-JsonWithErrorMapping -JsonString $rawJSON

.NOTES
    Author: Ben Hurwitz
    Email: bchurwitz+pixi_pyprojSetup@gmail.com
    Date: 2025-May-10
    Version: 1.0.0
    License: GNU GPL v3.0 (see above)
    Compatability: PowerShell 5.1 and 7
#>

function Convert-JsonWithErrorMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonString
    )

    # Comprehensive mapping of problematic patterns.
    $replacementsMapping = @{
        '^\uFEFF'                 = 'Removed BOM (Byte Order Mark)'
        '//.*$'                   = 'Removed single-line comments'
        '/\*([\s\S]*?)\*/'        = 'Removed multi-line block comments'
        ',\s*}'                   = 'Removed trailing commas before }'
        ',\s*\]'                  = 'Removed trailing commas before ]'
    }

    try {
        $result = $JsonString | ConvertFrom-Json
        return $result
    }
    catch {
        Write-Host "ERROR: JSON conversion failed." -ForegroundColor Red
        Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Here are some problematic characters for JSON and how to escape them from within JSON:" -ForegroundColor Magenta
        foreach ($pattern in $replacementsMapping.Keys) {
            Write-Host "Pattern    : $pattern" -ForegroundColor Cyan
            Write-Host "Replacement: $($replacementsMapping[$pattern])" -ForegroundColor Cyan
            Write-Host "-------------------------------"
        }
        Write-Host ""
        Write-Host "NOTE! " -ForegroundColor Red
        Write-Host "These escape sequences are only value for escaping from WITHIN a JSON file. For passing JSON strings directly in PowerShell or CMD, additional escaping is likely required (especially nested quotes - they require a *triple* backslash escape)." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Original raw JSON input:" -ForegroundColor Green
        Write-Host $JsonString
        throw "JSON conversion failed; see output above for details."
    }
}
