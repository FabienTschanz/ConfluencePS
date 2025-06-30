<#
.SYNOPSIS
    Decode a HTML encoded string
#>
function ConvertFrom-HTMLEncoded {
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
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Decoding string from HTML"
        [System.Web.HttpUtility]::HtmlDecode($InputString)
    }
}
