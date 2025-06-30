<#
.SYNOPSIS
    Updates an existing attachment with a new file.

.DESCRIPTION
    Updates an existing attachment with a new file.

.PARAMETER Attachment
    Attachment names to add to the content.

.PARAMETER FilePath
    File to be updated.

.EXAMPLE
    $attachment = Get-ConfluenceAttachment -PageID 123456 -FileNameFilter test.png
    Set-ConfluenceAttachment -Attachment $attachment -FilePath newTest.png -Verbose -Confirm
    For the attachment test.png on page with ID 123456, replace the file with the file newTest.png.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456 -FileNameFilter test.png | Set-ConfluenceAttachment -FilePath newTest.png -WhatIf
    Would replace the attachment test.png to the page with ID 123456. -WhatIf reports on simulated changes, but does not modify anything.

.OUTPUTS
    ConfluencePS.Attachment
#>
function Set-Attachment {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.Attachment])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Attachment]
        $Attachment,

        # Path of the file to upload and attach
        [Parameter(Mandatory = $true)]
        [ValidateScript(
            {
                if (-not (Test-Path $_ -PathType Leaf)) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"File not found"),
                        'ParameterValue.FileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $_
                    )
                    $errorItem.ErrorDetails = "No file could be found with the provided path '$_'."
                    $PSCmdlet.throwTerminatingError($errorItem)
                } else {
                    return $true
                }
            }
        )]
        [System.String]
        $FilePath
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content/{0}/child/attachment/{1}/data"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri = $resourceApi -f $Attachment.PageID, $Attachment.ID
            Method = "Post"
            InFile = $FilePath
            OutputType = [ConfluencePS.Attachment]
        }

        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Invoking Set Attachment Method with `$parameter"
        if ($PSCmdlet.ShouldProcess($Attachment.PageID, "Updating attachment '$($Attachment.Title)'.")) {
            Invoke-Method @iwParameters
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
