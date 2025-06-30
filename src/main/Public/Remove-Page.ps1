<#
.SYNOPSIS
    Trash an existing Confluence page.

.DESCRIPTION
    Delete existing Confluence content by page ID.
    This trashes most content, but will permanently delete "un-trashable" content.
    > Untested against non-page content.

.PARAMETER PageID
    The page ID to delete. Accepts multiple IDs via pipeline input.

.EXAMPLE
    Remove-ConfluencePage -PageID 123456 -Verbose -Confirm
    Trash the wiki page with ID 123456. Verbose and Confirm flags both active; you will be prompted before removal.

.EXAMPLE
    Get-ConfluencePage -SpaceKey ABC -Title '*test*' | Remove-ConfluencePage -WhatIf
    For all wiki pages in space ABC with "test" somewhere in the name, simulate the each page being trashed. -WhatIf prevents any removals.

.EXAMPLE
    Get-ConfluencePage -Label 'deleteMe' | Remove-ConfluencePage
    For all wiki pages with the label "deleteMe" applied, trash each page.

.OUTPUTS
    System.Boolean
#>
function Remove-Page {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
    )]
    [OutputType([System.Boolean])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [Alias('ID')]
        [System.UInt64[]]
        $PageID
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content/{0}"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($null -ne $_ -and ($_ -isnot [ConfluencePS.Page] -and $_ -isnot [System.UInt64])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            throw $exception
        }

        $iwParameters = @{
            Method = "Delete"
        }

        foreach ($_page in $PageID) {
            $iwParameters["Uri"] = $resourceApi -f $_page

            if ($PSCmdlet.ShouldProcess("PageID $_page")) {
                Invoke-Method @iwParameters
            }
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
