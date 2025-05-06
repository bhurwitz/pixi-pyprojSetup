param (
    [string]$InputFile,
    [string]$OutputFile,
    [string]$EnvFile
)

# Read the original file.
$file = Get-Content $InputFile -Raw

# Read the env file and build the replacement hash.
$lines = Get-Content $EnvFile
$replacements = @{}
foreach ($line in $lines) {
    if ($line -match '^(.*?)=(.*)$') {
        $key = $matches[1]
        $value = $matches[2]
        # Remove the "MY_" prefix from the key.
        $pureKey = $key -replace '^MY_', ''
        # The placeholder substitution we'll use {key}
        $placeholder = '{' + $pureKey + '}'
        $replacements[$placeholder] = $value
    }
}

# Perform all replacements.
foreach ($key in $replacements.Keys) {
    $escapedKey = [regex]::Escape($key)
    $file = $file -replace $escapedKey, $replacements[$key]
}

# Write the modified content.
Set-Content $OutputFile $file
