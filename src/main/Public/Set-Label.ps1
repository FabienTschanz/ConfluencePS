<#
.SYNOPSIS
    Set the labels applied to existing Confluence content.

.DESCRIPTION
    Sets desired labels for Confluence content.
    All preexisting labels will be removed in the process.
    > Note: Currently, Set-ConfluenceLabel only supports interacting with wiki pages.

.PARAMETER PageID
    The page ID to remove the label from. Accepts multiple IDs via pipeline input.

.PARAMETER Label
    Label names to add to the content.

.EXAMPLE
    Set-ConfluenceLabel -PageID 123456 -Label 'a','b','c'
    For existing wiki page with ID 123456, remove all labels, then add the three specified.

.EXAMPLE
    Get-ConfluencePage -SpaceKey 'ABC' | Set-Label -Label '123' -WhatIf
    Would remove all labels and apply only the label "123" to all pages in the ABC space. -WhatIf reports on simulated changes, but does not modifying anything.

.OUTPUTS
    ConfluencePS.ContentLabelSet
#>
function Set-Label {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.ContentLabelSet])]
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

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Label
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content/{0}/label"
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
            Method = "Post"
            OutputType = [ConfluencePS.Label]
        }

        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePS.Page]) {
                $InputObject = $_
            } else {
                $InputObject = Get-Page -PageID $_page
            }

            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Removing all previous labels"
            Remove-Label -PageID $_page | Out-Null

            $iwParameters["Uri"] = $resourceApi -f $_page
            $iwParameters["Body"] = $Label | ForEach-Object { @{prefix = 'global'; name = $_ } } | ConvertTo-Json

            Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($iwParameters["Body"] | Out-String)"
            if ($PSCmdlet.ShouldProcess("Label $Label, PageID $_page")) {
                $output = [ConfluencePS.ContentLabelSet]@{ Page = $InputObject }
                $output.Labels += (Invoke-Method @iwParameters)
                $output
            }
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
