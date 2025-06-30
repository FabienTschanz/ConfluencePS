<#
.SYNOPSIS
    Generate the GET parameter string for an URL from a hashtable
#>
function ConvertTo-GetParameter {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.Collections.Hashtable]
        $InputObject
    )

    begin {
        [System.String]$parameters = "?"
    }

    process {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Making HTTP get parameter string out of a hashtable"
        foreach ($key in $InputObject.Keys) {
            $parameters += "$key=$($InputObject[$key])&"
        }
    }

    end {
        $parameters -replace ".$"
    }
}
