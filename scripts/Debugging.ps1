function Debug-Status {
    [CmdletBinding()]
    param(
        # The log message is required.
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message, 
        
        # A color can be passed if desired to overwrite the default.
        [Parameter(Mandatory = $false)]
        [string]$ForeColor
    )
    
    # Call the 'Debug' method at level -1
    if ($ForeColor) {
        try {
            __Debug-Print "[STATUS] $Message" -FColor $ForeColor -Level -1
        } catch [System.Management.Automation.PSArgumentValidationException] {
            Write-Debug "--> Invalid color passed to 'Debug-Status'. Using the default."
            __Debug-Print "[STATUS] $Message" -Level -1
        }
    }
    else {
        __Debug-Print "[STATUS] $Message" -Level -1
    }
}


function Debug-Info {
    [CmdletBinding()]
    param(
        # The log message is required.
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message, 
        
        # A color can be passed if desired to overwrite the default.
        [Parameter(Mandatory = $false)]
        [string]$ForeColor
    )
    
    # Call the 'Debug' method at level 0
    if ($ForeColor) {
        try {
            __Debug-Print "[INFO] $Message" -FColor $ForeColor -Level 0
        } catch [System.Management.Automation.PSArgumentValidationException] {
            Write-Debug "--> Invalid color passed to 'Debug-Info'. Using the default."
            __Debug-Print "[INFO] $Message" -Level 0
        }
    }
    else {
        __Debug-Print "[INFO] $Message" -Level 0
    }
}

function Debug-Warning {
    [CmdletBinding()]
    param(
        # The log message is required.
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message, 
        
        # A color can be passed if desired to overwrite the default.
        [Parameter(Mandatory = $false)]
        [string]$ForeColor
    )
    
    # Call the 'Debug' method at level 1
    if ($ForeColor) {
        try {
            __Debug-Print "[WARNING] $Message" -FColor $ForeColor -Level 1
        } catch [System.Management.Automation.PSArgumentValidationException] {
            Write-Debug "--> Invalid color passed to 'Debug-Warning'. Using the default."
            __Debug-Print "[WARNING] $Message" -Level 1
        }
    }
    else {
        __Debug-Print "[WARNING] $Message" -Level 1
    }
}

function Debug-Error {
    [CmdletBinding()]
    param(
        # The log message is required.
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message, 
        
        # A color can be passed if desired to overwrite the default.
        [Parameter(Mandatory = $false)]
        [string]$ForeColor
    )
    
    # Call the 'Debug' method at level 2
    if ($ForeColor) {
        try {
            __Debug-Print "[ERROR] $Message" -FColor $ForeColor -Level 2
        } catch [System.Management.Automation.PSArgumentValidationException] {
            Write-Debug "--> Invalid color passed to 'Debug-Error'. Using the default."
            __Debug-Print "[ERROR] $Message" -Level 2
        }
    }
    else {
        __Debug-Print "[ERROR] $Message" -Level 2
    }
}


function __Debug-Print {
    [CmdletBinding()]
    param(
        # The log message is required.
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        # This parameter is validated against the level.
        [Parameter(Mandatory = $false)]
        [ValidateSet(-1, 0, 1, 2)]
        [int]$Level, 
        
        # Each '$Level' has a default color that can be overriden here.
        # This parameter is validated against a set of colors.
        [Parameter(Mandatory = $false)]
        [ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
        [string]$FColor
    )
    
    if ($Level -eq -1 -and -not $FColor) { $FColor = "Cyan" }
    if ($Level -eq 0 -and -not $FColor) { $FColor = "White" }
    if ($Level -eq 1 -and -not $FColor) { $FColor = "Yellow" }
    if ($Level -eq 2 -and -not $FColor) { $FColor = "Red" }


    # Check the global $DebugPreference. If it is set to 'Continue',
    # then we assume that we want debug/log output.
    if ($DebugPreference -eq 'Continue') {
        Write-Host "$Message" -ForegroundColor $FColor
    }
    
}