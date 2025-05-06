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
