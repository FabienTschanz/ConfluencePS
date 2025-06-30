<#
.SYNOPSIS
    Remove an Attachment.

.DESCRIPTION
    Remove Attachments from Confluence content.
    Does accept multiple pages piped via Get-ConfluencePage.
    > Untested against non-page content.

.PARAMETER Attachment
    The Attachment(s) to remove.


.EXAMPLE
    $attachments = Get-ConfluenceAttachment -PageID 123456
    Remove-ConfluenceAttachment -Attachment $attachments -Verbose -Confirm
    Remove all attachment from page 12345 Verbose and Confirm flags both active; you will be prompted before deletion.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456 | Remove-ConfluenceAttachment -WhatIf
    Do trial deletion for all attachments on page with ID 123456, the WhatIf parameter prevents any modifications.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456 | Remove-ConfluenceAttachment
    Remove all Attachments on page 123456.

.OUTPUTS
    None.
#>
function Remove-Attachment {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
    )]
    [OutputType([System.Boolean])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Attachment[]]
        $Attachment
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content/{0}"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Method = "Delete"
        }

        foreach ($_attachment in $Attachment) {
            $iwParameters["Uri"] = $resourceApi -f $_attachment.ID

            if ($PSCmdlet.ShouldProcess("Attachment $($_attachment.ID), PageID $($_attachment.PageID)")) {
                Invoke-Method @iwParameters
            }
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}


