<#
.SYNOPSIS
    Extracted the conversion to private function in order to have a single place
    to select the properties to use when casting to custom object type
#>
function ConvertTo-Icon {
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Icon] )]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true
        )]
        [System.Object[]]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Converting Object to Icon"
            [ConfluencePS.Icon](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                Path,
                Width,
                Height,
                IsDefault
            ))
        }
    }
}
