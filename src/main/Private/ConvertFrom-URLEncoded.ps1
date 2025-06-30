<#
.SYNOPSIS
    Decode a URL encoded string
#>
function ConvertFrom-URLEncoded {
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
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Decoding string from URL"
        [System.Web.HttpUtility]::UrlDecode($InputString)
    }
}
