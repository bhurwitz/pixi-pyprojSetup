param (
    [string]$File,          # The target file to modify.
    [string]$Replacements,  # JSON string defining replacement key-value pairs.
    [switch]$Debug          # Optional debug flag.
    [string]$ConfigFile = $null     # The file that stores the parameters.
)

try {

    try {
        # Step 1: Read the configuration file if provided.
        $config = $null
        if ($ConfigFile) {
            if (!(Test-Path $ConfigFile)) {
                throw "Configuration file '$ConfigFile' not found!"
            } 
            else {
                Write-Host "Config file passed. Parsing..."
            }
            # Read and pre-process the JSON file.
            $rawConfig = Get-Content $ConfigFile -Raw
            if ($Debug) {
                Write-Host "Raw config file: $rawConfig"
            }
            $cleanConfig = $rawConfig -replace "//.*", "" -replace "/\*([\s\S]*?)\*/", ""
            if ($Debug) {
                Write-Host "Pre-processed config file: $cleanConfig"
            }
            $config = $cleanConfig | ConvertFrom-Json
            if ($Debug) {
                Write-Host "Processed JSON (detailed):"
                $config | Format-List *
            }
            
            $File = if ($config -and $config.File) { $config.File }
        
            $Replacements = if ($config -and $config.Replacements) { $config.Replacements } 
            
            if ($config -and $config.Debug) {
            
                if ($config.Debug -is [string]) {
                    if ($config.Debug -eq "0") { $Debug = [switch]$False }
                    elseif ($config.Debug.ToLower() -eq "false") { $Debug = [switch]$False }
                    else { $Debug = [switch]$True }
                }
                else {
                    $Debug = [switch]$True
                }
            }

        }
        else {
            Write-Host "No config file passed!"
        }
    } catch {
        throw "Error in the Config-file read-in! Nothing will be inserted."
    }

    if (-not $File) {
        throw "Missing required parameter: 'File'."
    }
    if (-not $Replacements) {
        throw "Missing required parameter: 'Replacements'."
    }
    if ($Debug) {
        Write-Host "Debug mode ENABLED"
        if ($ConfigFile) { Write-Host "Config file parsed!" }
        if ($rawConfig) { Write-Host "Raw config file: $rawConfig" }
        if ($cleanConfig) { Write-Host "Pre-processed config file: $cleanConfig" }
        if ($config) { 
            Write-Host "Processed JSON (detailed):" 
            $config | Format-List *
        }
    }
    else {
        Write-Host "Debug mode DISABLED"
    }

        
    # Step 4: Parse Insertions if passed as a JSON string.

    # At this point, $Replacements might be a JSON string (if it was directly passed) or it might already be an object (if it was passed via the config file)
    if ($Replacements -is [string]) {
        # Check if the string looks like JSON; for example, it should start with a '{' or '['.
        $trimmed = $Replacements.TrimStart()
        if ($trimmed.StartsWith("{") -or $trimmed.StartsWith("[")) {
            if ($Debug) { Write-Host "Parsing Insertions string '$Replacements' into an object..." }
            $Replacements = $Replacements | ConvertFrom-Json
        } else {
            if ($Debug) { Write-Host "Insertions appears to be a plain string; no JSON conversion performed." }
        }
    } else {
        if ($Debug) { Write-Host "Insertions is already an object; no conversion needed." }
    }


    if ($Debug) {
        Write-Host "`nResolved parameters:"
        Write-Host "  File: $File"
        Write-Host "  Replacements: $Replacements"
        Write-Host "  Debug: $Debug"
    }

    # Parse the JSON string into a hashtable.
    $replacementPairs = $Replacements | ConvertFrom-Json

    if ($Debug) {
        Write-Host "`nStarting replacement operation on file: $File"
    }

    # Read the file into memory.
    $fileContent = Get-Content $File
    foreach ($key in $replacementPairs.Keys) {
        $pattern = "^\s*($key\s*=\s*).*$"  # Match the key and its current value.
        $replacement = "$1\"$($replacementPairs[$key])\""  # Replace with the new value (quoted).
        if ($Debug) {
            Write-Host "Replacing key '$key' with value '$($replacementPairs[$key])'"
        }
        $fileContent = $fileContent -replace $pattern, $replacement
    }

    # Write back the updated content.
    Set-Content $File $fileContent
    if ($Debug) {
        Write-Host "Replacement operation completed!"
    }

} catch {
    Write-Host "`nError: $($_.Exception.Message)"
    Write-Host "Ensure the parameters are correctly specified. A complete list of problematic characters and their escape sequences:"
    Write-Host "  - Backslashes (\): Use \ to escape them."
    Write-Host "  - Double quotes (`"): Use \`" to escape them."
    Write-Host "    Note! If you're explicitly passing parameters and need a literal quote `" (for example, with nested quotes), you escape it with three backslashes."
    Write-Host "  - Forward slashes (/): Use \/ to escape them (optional)."
    Write-Host "  - Newlines: Replace with \\n."
    Write-Host "  - Tabs: Replace with \\t."
    Write-Host "  - Carriage returns: Replace with \\r."
    Write-Host "  - Unicode characters: Use \\u followed by the 4-digit code (e.g., \\u0022 for `")."
    Write-Host "  - Single quotes ('): Single quotes do not require escaping in JSON."
    Write-Host "  - Curly braces ({ or }): Curly braces do not require escaping in JSON."
    Write-Host "Example JSON format: {\`"key1\`":\`"value1\`", \`"key2\`":\`"value2\`", \`"key3\`": \"[\\\"value1\\\", \\\"value2\\\"]\"}"
}

