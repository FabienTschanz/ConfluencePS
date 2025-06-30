<#
.SYNOPSIS
    Encode a string into HTML (eg: &gt; instead of >)
#>
function ConvertTo-HTMLEncoded {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(
            Position = $true,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String]
        $InputString
    )

    process {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Encoding string to HTML"
        [System.Web.HttpUtility]::HtmlEncode($InputString)
    }
}
