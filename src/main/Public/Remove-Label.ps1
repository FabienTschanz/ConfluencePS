<#
.SYNOPSIS
    Remove a label from existing Confluence content.

.DESCRIPTION
    Remove labels from Confluence content.
    Does accept multiple pages piped via Get-ConfluencePage.
    > Untested against non-page content.

.PARAMETER PageID
    The page ID to remove the label from. Accepts multiple IDs via pipeline input.

.PARAMETER Label
    A single content label to remove from one or more pages.

.EXAMPLE
    Remove-ConfluenceLabel -PageID 123456 -Label 'seven' -Verbose -Confirm
    Remove label "seven" from the wiki page with ID 123456. Verbose and Confirm flags both active; you will be prompted before deletion.

.EXAMPLE
    Get-ConfluencePage -SpaceKey 'ABC' -Label 'deleteMe' | Remove-ConfluenceLabel -Label 'deleteMe' -WhatIf
    For all wiki pages in the ABC space, the label "deleteMe" would be removed. WhatIf parameter prevents any modifications.

.EXAMPLE
    Get-ConfluenceChildPage -PageID 123456 | Remove-ConfluenceLabel
    For all wiki pages immediately below page 123456, remove all labels from each page.

.OUTPUTS
    System.Boolean
#>

function Remove-Label {
    [CmdletBinding(
        ConfirmImpact = 'Low',
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
        $PageID,

        [Parameter()]
        [System.String[]]
        $Label
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content/{0}/label?name={1}"
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
            $_labels = $Label
            if (-not $_labels) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Collecting all Labels for page $_page"
                $allLabels = Get-Label -PageID $_page
                if ($allLabels.Labels) {
                    $_labels = $allLabels.Labels | Select-Object -ExpandProperty Name
                }
            }
            Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Labels to remove: `$_labels"

            foreach ($_label in $_labels) {
                $iwParameters["Uri"] = $resourceApi -f $_page, $_label

                if ($PSCmdlet.ShouldProcess("Label $_label, PageID $_page")) {
                    Invoke-Method @iwParameters
                }
            }
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
