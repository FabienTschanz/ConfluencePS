function ConvertTo-PageAncestor {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType([ConfluencePS.Page])]
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
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Converting Object to Page (Ancestor)"
            [ConfluencePS.Page](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                id,
                status,
                title
            ))
        }
    }
}
