<#
.SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
#>
function ConvertTo-User {
    [CmdletBinding()]
    [OutputType([ConfluencePS.User])]
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
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Converting Object to User"
            [ConfluencePS.User](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                username,
                userKey,
                @{
                    Name = "profilePicture"
                    Expression = {
                        ConvertTo-Icon $_.profilePicture
                    }
                },
                displayname
            ))
        }
    }
}
