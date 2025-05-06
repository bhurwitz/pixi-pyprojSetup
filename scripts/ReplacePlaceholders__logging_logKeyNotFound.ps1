param (
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    [Parameter(Mandatory=$true)]
    [string]$EnvFile
)

# Optionally, enable debug preference so Write-Debug shows messages.
$DebugPreference = "Continue"

# Log: Show full environment file contents.
Write-Host "Loading environment file: $EnvFile"
$lines = Get-Content $EnvFile
Write-Host "Environment file has $($lines.Count) line(s):"
$lines | ForEach-Object { Write-Host "  $_" }

# Build the replacements table.
$replacements = @{}
foreach ($line in $lines) {
    Write-Host "`nProcessing line: $line"
    if ($line -match '^(.*?)=(.*)$') {
        $key = $matches[1]
        $value = $matches[2]
        Write-Host "Parsed key: '$key' and value: '$value'"
        
        # Optionally, trim the value (or perform additional cleaning/escaping)
        $value = $value.Trim()
        
        $pureKey = $key -replace '^MY_', ''
        $placeholder = '{' + $pureKey + '}'
        Write-Host "Mapping placeholder '$placeholder' to value '$value'"
        $replacements[$placeholder] = $value
    } else {
        Write-Host "Line did not match expected pattern: $line"
    }
}

# Log: Show the entire replacement dictionary.
Write-Host "`nReplacement table:"
$replacements.GetEnumerator() | ForEach-Object {
   Write-Host "  $($_.Key) -> $($_.Value)"
}

# Read the input file.
Write-Host "`nReading input file: $InputFile"
$fileContent = Get-Content $InputFile -Raw
Write-Host "Original file content (first 300 chars):"
Write-Host ($fileContent.Substring(0, [Math]::Min(300, $fileContent.Length)))
 
# Perform the replacements only when the placeholder exists.
foreach ($key in $replacements.Keys) {
    $escapedKey = [regex]::Escape($key)
    if ($fileContent -match $escapedKey) {
        Write-Host "`nReplacing placeholder '$key' with '$($replacements[$key])'"
        $fileContent = $fileContent -replace $escapedKey, $replacements[$key]
    } else {
        Write-Host "`nPlaceholder '$key' not found in the file content; skipping replacement."
    }
}

# Log: Show final content before writing out.
Write-Host "`nFinal file content (first 300 chars):"
Write-Host ($fileContent.Substring(0, [Math]::Min(300, $fileContent.Length)))

# Write the content to the output file.
Set-Content $OutputFile $fileContent
Write-Host "`nOutput file written successfully to: $OutputFile"
