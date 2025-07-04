<#
.SYNOPSIS
    Converts a PSCustomObject to Hashtable

.DESCRIPTION
    PowerShell v4 on Windows 8.1 seems to have trouble casting [PSCustomObject] to custom classes.
    This function is a workaround, as casting from [Hashtable] is no problem.
#>
function ConvertTo-HashTable {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $InputObject
    )

    begin {
        $hash = @{}
        $InputObject.PSObject.properties | Foreach-Object {
            $hash[$_.Name] = $_.Value
        }
        $hash
    }
}
