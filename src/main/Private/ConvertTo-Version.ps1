<#
.SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
#>
function ConvertTo-Version {
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
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Converting Object to Version"
            [ConfluencePS.Version](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                @{
                    Name = "by"
                    Expression = {
                        ConvertTo-User $_.by
                    }
                },
                when,
                friendlyWhen,
                number,
                message,
                minoredit
            ))
        }
    }
}
