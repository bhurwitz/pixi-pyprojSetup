<# toml_replace.ps1

.SYNOPSIS  
    Replaces key–value lines in a TOML file based on a JSON configuration.

.DESCRIPTION  
    This script reads a configuration file (which may include “C-style” comments that are stripped) containing a JSON object with a "Replacements" field, plus the target file path. For each key in "Replacements", the script searches for a line in the target TOML file with the pattern  
        key = ...  
    and if found, replaces that whole line with:  
        key = <replacement value>  
    If a key is not found in the file, no new line is inserted.  

.PARAMETER File  
    The path to the target TOML file to be modified.

.PARAMETER Replacements  
    An object or JSON-formatted string whose properties are keys to process and whose values are the new values to use in replacement.

.PARAMETER Debug  
    A switch that, if specified, turns on debugging messages.

.PARAMETER ConfigFile  
    The path to a JSON configuration file. If provided, parameters from the config file override any command-line parameters EXCEPT 'Debug'. If 'Debug' is set on the CLI, it cannot be overriden by the configuration file.

.EXAMPLE  
    # Replace keys using a config file:
    .\toml_replace_only.ps1 -ConfigFile "toml_replace_only.config"

.NOTES  

#>
[CmdletBinding()]
param (
    [string]$File = $null,
    [object]$Replacements = $null,  # Accepts either a JSON object or a JSON string.
    [string]$ConfigFile = $null,
    # [switch]$Debug,       # The '-Debug' flag is automatically included with the CmdletBinding().
    # [switch]$NoDebug
    [int]$DEBUG_LEVEL = $null
)

# We need to add the current path to the PSModulePath so that PS can find the Logging module.
# The module path should be absolute, but we may not want to reveal our full path.
$modulePath_relative = "."
$env:PSModulePath += ";$((Resolve-Path $modulePath_relative).Path)"

# Import the custom Logging module. It lives in <Documents\PowerShell\Modules>.
Import-Module Logging -DisableNameChecking

# Source external files
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
    Log-Status "Debugging is enabled at level $DEBUG_LEVEL in 'toml_replace.ps1'."
}


#####################################################################
## Parse the configuration file, if one was passed.



if ($ConfigFile) {

    if (!(Test-Path $ConfigFile)) {
        if ($File -and $Replacements) {
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

        $Replacements = if ($config.Replacements) { $config.Replacements } 
    }
}

#####################################################################
### Validation

if (-not $File) {
    throw "Missing required parameter: 'File'."
}

if (-not $Replacements) {
    throw "Missing required parameter: 'Replacements'."
}


# If Replacements is a JSON string, convert it to an object.
if ($Replacements -is [string]) {
    $trimmed = $Replacements.TrimStart()
    if ($trimmed.StartsWith("{") -or $trimmed.StartsWith("[")) {
        Log-Debug3 "The 'Replacements' string (below) appears to be a valid JSON string in object form."
        Log-Debug3 "Parsing Replacements string into an object." 
        Log-Debug3 "Original string: $Replacements"
        $Replacements = Convert-JsonWithErrorMapping -JsonString $Replacements
    } else {
        Log-Debug3 "Replacements string does not appear to be valid JSON. Using as-is."
    }
}

Log-Debug2 "Final configuration:"
Log-Debug2 "File: $File"
Log-Debug2 "Replacements:"
Log-Debug2 ($Replacements | Format-List * | Out-String)

#####################################################################
### Replacement routine

if (-not (Test-Path $File)) {
    throw "Target file '$File' not found."
}

$contents = Get-Content $File -Raw
Log-Debug3 "Original file content:"
Log-Debug3 $contents

# For each key in the Replacements object, search and replace a matching line.
foreach ($key in $Replacements.PSObject.Properties.Name) {
    $value = $Replacements.$key
    # If the replacement value is a plain string and does not start with [ or {, add quotes.
    if ($value -is [string]) {
        if (-not ($value.TrimStart().StartsWith('[') -or $value.TrimStart().StartsWith('{'))) {
            $value = '"' + $value + '"'
        }
    }
    # Create a multline regex pattern that matches a line starting with the key.
    $pattern = "(?m)^\s*" + [regex]::Escape($key) + "\s*=\s*.*$"
    $replacementLine = "$key = $value"
    if ($contents -match $pattern) {
        Log-Debug3 "Replacing line for key '$key' with: $replacementLine" 
        $contents = $contents -replace $pattern, $replacementLine
    }
    else {
        Log-Debug3 "Key '$key' not found. No replacement will be performed." 
    }
}

Set-Content -Path $File -Value $contents -Encoding UTF8

Log-Debug2 "Replacement operation completed!"

