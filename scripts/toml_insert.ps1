<# toml_insert.ps1

.SYNOPSIS
    Inserts arbitrary strings into a TOML file.

.DESCRIPTION
    This script inserts an arbitrary set of strings into a TOML file after an anchor point. These can either be passed as explicit parameters through the CLI, or from within a JSON file with the insertions as a list. The JSON file may have C-style comments, and can be used in conjuntion with the placeholder structures. See 'toml_insert.config' for example, and see 'ReplacePlaceholders.ps1' for placeholder details.

.PARAMETER File
    The path to the target TOML file to be modified.

.PARAMETER Insertions
    A JSON string or object whose 'key':'value' pairs will be mapped to 'key = value' lines for insertion into the file.

.PARAMETER Anchor
    The line AFTER this string appears will be where the insertions take place. Be sure to pass a unique string here, e.g. 'versions = ' and not just 'versions' (which could be elsewhere). 

.PARAMETER Debug  
    A switch that, if specified, turns on debugging messages. 

.PARAMETER ConfigFile  
    The path to a JSON configuration file. Any parameters passed within this file will override CLI parameters EXCEPT 'Debug'. If 'Debug' is set on the CLI, it cannot be overriden by the configuration file.

.EXAMPLE
    # Replace keys using a config file:
    .\toml_replace_only.ps1 -ConfigFile "toml_replace.config"
    
    # Replace keys using a string with the debug flag (new lines added for readability; note the required escaping):
    .\toml_replace.ps1 
        -File test_toml_file.toml 
        -Replacements 
            "{\"readme\":\"README.md\",
            \"license-files\":\"[\\\"LICENSE.txt\\\"]\",
            \"authors\":
                \"[{name = \\\"{author}\\\", 
                    email = \\\"ben@example.com\\\"}]\",
            \"numbers\":[1,2,3],
            \"isStable\":true}" 
        -Debug

.NOTES

#>
[CmdletBinding()]
param (
    [string]$File = $null,
    [object]$Insertions = $null,
    [string]$Anchor = $null,
    [string]$ConfigFile = $null,
    # [switch]$Debug,       # The '-Debug' flag is automatically included with the CmdletBinding().
    # [switch]$NoDebug
    [int]$DEBUG_LEVEL
)

# Import the custom Logging module. It lives in <Documents\PowerShell (and WindowsPowerShell)\Modules>.
Import-Module Logging 

# Source the JSON-error method
. "$PSScriptRoot\Convert-JsonWithErrorMapping.ps1"

# --- Determine the Debug State ---
# The following logic checks (in priority order):
#   1. If the caller explicitly disabled debug (via -NoDebug),
#   2. If external configuration says to enable debug,
#   3. If the built-in -Debug parameter was used,
#   4. If the global $DebugPreference has been set.
#   5. Otherwise, leave debugging off.
# This explicitly ignores the other two debugging settings ("Inquire" and "Stop").

# NOTE! This block will not set any debugging state if a config file exists and will just maintain the caller's status quo. The config file will over only the caller's status quo and NOT any passed flags.

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
} elseif ($DebugPreference -eq 'Continue' -and -not $ConfigFile) {
    $Debug = [switch]$True
    Set-DebugLevel 1
} elseif ($DebugPreference -eq 'SilentlyContinue' -and -not $ConfigFile) {
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
    Log-Status "Debugging is enabled at level $DEBUG_LEVEL in 'toml_insert.ps1'."
}

#####################################################################
## Parse the configuration file, if one was passed.

if ($ConfigFile) {

    if (!(Test-Path $ConfigFile)) {
        if ($File -and $Insertions -and $Anchor) {
            Log-Warning "Passed configuration file ($ConfigFile) does not appear to exist! Falling back to CLI arguments."
        }
        else {
            Log-Error "Configuration file '$ConfigFile' not found and no CLI arguments passed! Try again."
            return $false
        }
    }
    else {
    
        Log-Debug2 "Config file passed. Parsing..."
    
        # Read raw JSON file
        $rawConfig = Get-Content $ConfigFile -Raw
        Log-Debug3 "Raw config file:"
        Log-Debug3 $rawConfig
        
        # Remove C-style comments.
        $cleanConfig = $rawConfig -replace '//.*', '' -replace '/\*([\s\S]*?)\*/', ''
        
        Log-Debug3 "Pre-processed config file:"
        Log-Debug3 $cleanConfig
        
        # Convert to JSON object with integrated error handling.
        $config = Convert-JsonWithErrorMapping -JsonString $cleanConfig
        
        # Assign configuration variables to local parameters.
        
        # The external parameters file 'toml_replace.config' will only override debug if is it NOT EXPLICITLY SET via the CLI.

        if ($config.Debug -and -not ($DEBUG_LEVEL -or $PSBoundParameters.ContainsKey("Debug"))) {
        
            # if ($config.Debug -is [string] -and $config.Debug.ToLower() -eq "true") {
                # $Debug = [switch]$True
                # $DebugPreference = 'Continue'
                
            # }
            # elseif ($config.Debug -is [bool] -and $config.Debug -eq $true) {
                # $Debug = [switch]$True
                # $DebugPreference = 'Continue'
            # }
            Set-DebugLevel $config.Debug
            $DEBUG_LEVEL = $config.Debug
            if ($config.Debug -eq 0) {
                $DebugPreference = 'SilentlyContinue'
                $Debug = [switch]$false
            }
            else {
                $DebugPreference = 'Continue'
                $Debug = [switch]$true
            }
            
            # else {
                # $Debug = [switch]$False
                # $DebugPreference = 'SilentlyContinue'
            # }
            
            Log-Debug3 "Config file parsed."
            Log-Debug3 "Debugged ENABLED from the config file." -ForegroundColor Cyan
            Log-Debug3 ""
            Log-Debug3 "Raw config file:"
            Log-Debug3 $rawConfig
            Log-Debug3 ""
            Log-Debug3 "Pre-processed config file:"
            Log-Debug3 $cleanConfig
            Log-Debug3 ""
        }
        
        if ($DEBUG_LEVEL -ge 3) {
            Log-Debug3 "Processed JSON (detailed):"
            Log-Debug3 ($config | Format-List * | Out-String)
            Log-Debug3 ""
        }
        
        $File = if ($config.File) { $config.File }

        $Insertions = if ($config.Insertions) { $config.Insertions } 
        
        $Anchor = if ($config -and $config.Anchor) { $config.Anchor }
    }

}

#####################################################################
### Validation

if (-not $File) {
    throw "Missing required parameter: 'File'."
}
if (-not $Insertions) {
    throw "Missing required parameter: 'Insertions'."
}
if (-not $Anchor) {
    throw "Missing required parameter: 'Anchor'."
}

# At this point, $Insertions might be a JSON string (if it was directly passed) or it might already be an object (if it was passed via the config file)
if ($Insertions -is [string]) {
    # Check if the string looks like JSON; for example, it should start with a '{' or '['.
    $trimmed = $Insertions.TrimStart()
    if ($trimmed.StartsWith("{") -or $trimmed.StartsWith("[")) {
        Log-Debug3 "Parsing Insertions string '$Insertions' into an object..." 
        $Insertions = $Insertions | ConvertFrom-Json
    } else {
        Log-Debug3 "Insertions appears to be a plain string; no JSON conversion performed." 
    }
} else {
    Log-Debug3 "Insertions is already an object; no conversion needed." 
}


Log-Debug2 "`nResolved parameters:"
Log-Debug2 "  File: $File"
Log-Debug2 "  Insertions: $Insertions"
Log-Debug2 "  Anchor: $Anchor"
Log-Debug2 "  Debug: $Debug"


#####################################################################
### Insertion routine

if (!(Test-Path $File)) {
    throw "Target TOML file '$File' not found!"
}
$fileContent = Get-Content $File
$newLines = @()
$inserted = $false

Log-Debug3 "$File contents: $fileContent"

foreach ($line in $fileContent) {
    $newLines += $line
    Log-Debug3  "Current line: $line"
    if ($line -match "$Anchor") {
        Log-Debug3 "Anchor found: $line"
        foreach ($key in $Insertions.PSObject.Properties.Name) {
            $value = $Insertions.$key
            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                # If the value is a list or array, don't add quotes.
                $newLines += "$key = $value"
            } elseif ($value -like "[{*}]") {
                # Preserve raw TOML-like values (e.g., authors) as-is without wrapping in extra quotes.
                $newLines += "$key = $value"
            } else {
                # For other types (e.g., plain strings, numbers), add quotes around the value.
                $newLines += "$key = `"$value`""
            }
            Log-Debug3 "Inserted key '$key' with value '$value'"
        }          
        $inserted = $true
    }
}

if (-not $inserted) {
    Log-Warning "Warning: Anchor '$Anchor' not found!"
}

$newLines | Set-Content $File

Log-Debug2 "Insertion operation completed!"