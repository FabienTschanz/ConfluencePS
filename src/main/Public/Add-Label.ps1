<#
.SYNOPSIS
    Add a new global label to an existing Confluence page.

.DESCRIPTION
    Assign labels (one or more) to Confluence pages (one or more).
    If the label did not exist previously, it will be created. Preexisting labels are not affected.

.PARAMETER PageID
    The ID of the page to which apply the label to. Accepts multiple IDs, including via pipeline input.

.PARAMETER Label
    One or more labels to be added. Currently only supports labels of prefix "global".

.EXAMPLE
    Add-ConfluenceLabel -PageID 123456 -Label alpha -Verbose
    Apply the label alpha to the wiki page with ID 123456. -Verbose output provides extra technical details, if interested.

.EXAMPLE
    Get-ConfluencePage -SpaceKey SRV | Add-ConfluenceLabel -Label servers -WhatIf
    Simulates applying the label "servers" to all pages in the space with key SRV. -WhatIf provides PageIDs of pages that would have been affected.

.EXAMPLE
    Get-ConfluencePage -SpaceKey DEMO | Add-ConfluenceLabel -Label abc -Confirm
    Applies the label "abc" to all pages in the space with key DEMO. -Confirm prompts Yes/No for each page that would be affected.

.OUTPUTS
    ConfluencePS.ContentLabelSet
#>
function Add-Label {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.ContentLabelSet])]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [Alias('ID')]
        [System.UInt64[]]$PageID,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Labels')]
        $Label
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content/{0}/label"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Validate input object from Pipeline
        if (($_) -and -not ($_ -is [ConfluencePS.Page] -or $_ -is [System.UInt64] -or $_ -is [ConfluencePS.ContentLabelSet])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            throw $exception
        }

        # The parameter "Label" has no type declared. Because of this, a piped object of
        # type "ConfluencePS.ContentLabelSet" will be assigned to "Label". Lets fix this:
        if ($_ -and $Label -is [ConfluencePS.ContentLabelSet]) {
            $Label = $Label.Labels
        }

        # Test if Label is String[]
        [System.String[]]$_label = $Label
        $_label = $_label | Where-Object { $_ -ne "ConfluencePS.Label" }
        if ($_label) {
            [System.String[]]$Label = $_label
        }
        # Allow only for Label to be a [System.String[]] or [ConfluencePS.Label[]]
        $allowedLabelTypes = @(
            "System.String"
            "System.String[]"
            "ConfluencePS.Label"
            "ConfluencePS.Label[]"
        )
        if ($Label.GetType().FullName -notin $allowedLabelTypes) {
            $message = "Parameter 'Label' is not a Label or a String. It is $($Label.gettype().FullName)"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            throw $exception
        }

        $iwParameters = @{
            Method = "Post"
            OutputType = [ConfluencePS.Label]
        }

        # Extract name if an Object is provided
        if (($Label -is [ConfluencePS.Label]) -or $Label -is [ConfluencePS.Label[]]) {
            $Label = $Label | Select-Object -ExpandProperty Name
        }

        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePS.Page]) {
                $InputObject = $_
            } elseif ($_ -is [ConfluencePS.ContentLabelSet]) {
                $InputObject = $_.Page
            } else {
                $InputObject = Get-Page -PageID $_page
            }

            $iwParameters["Uri"] = $resourceApi -f $_page
            $iwParameters["Body"] = ($Label | ForEach-Object {
                @{
                    prefix = 'global'
                    name = $_
                }
            }) | ConvertTo-Json

            Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($iwParameters["Body"] | Out-String)"
            if ($PSCmdlet.ShouldProcess("Label $Label, PageID $_page")) {
                $output = [ConfluencePS.ContentLabelSet]@{
                    Page = $InputObject
                }
                $output.Labels += (Invoke-Method @iwParameters)
                $output
            }
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
