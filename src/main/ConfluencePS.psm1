# Load the ConfluencePS namespace from C#
if (-not ("ConfluencePS.Space" -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot ConfluencePS.Types.cs) -ReferencedAssemblies Microsoft.CSharp, Microsoft.PowerShell.Commands.Utility, System.Management.Automation
}

$global:PATValue = ""
$global:CookieValue = ""

# Load Web assembly when needed
# PowerShell Core has the assembly preloaded
if (-not ("System.Web.HttpUtility" -as [Type])) {
    Add-Type -Assembly System.Web
}

$ErrorActionPreference = 'Stop'

# Get public and private function definition files.
# Sort to make sure files that start with '_' get loaded first
$Private = Get-ChildItem -Path "$PSScriptRoot\Private" -Recurse -Filter "*.ps1"
$Public  = Get-ChildItem -Path "$PSScriptRoot\Public" -Recurse -Filter "*.ps1"

# Dot source the private files
foreach ($import in $Private) {
    try {
        . $import.FullName
        Write-Verbose -Message "Imported private function $($import.FullName)"
    } catch {
        Write-Error -Message "Failed to import private function $($import.FullName): $_"
    }
}

# Dot source the public files
foreach ($import in $Public) {
    try {
        . $import.FullName
        Write-Verbose -Message "Imported public function $($import.FullName)"
    } catch {
        Write-Error -Message "Failed to import public function $($import.FullName): $_"
    }
}

# Load Module variables file
try {
    $variables = Get-Content "$PSScriptRoot\Variables.json" | ConvertFrom-Json -AsHashtable
    foreach ($variable in $variables) {
        New-Variable -Name $variable.Name -Value $variable.Value -Scope Script -Option Constant
    }
} catch {
    throw "Could not load Variables.json file. Error: $_"
}
