<#
.SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
#>
function ConvertTo-Label {
    [CmdletBinding()]
    [OutputType([ConfluencePS.Version])]
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
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Converting Object to Label"
            [ConfluencePS.Label](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                id,
                name,
                prefix
            ))
        }
    }
}
