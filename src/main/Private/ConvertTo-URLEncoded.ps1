<#
.SYNOPSIS
    Encode a string into URL (eg: %20 instead of " ")
#>
function ConvertTo-URLEncoded {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String]
        $InputString
    )

    process {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Encoding string to URL"
        [System.Web.HttpUtility]::UrlEncode($InputString)
    }
}
