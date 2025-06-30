<#
.SYNOPSIS
    Add a new attachment to an existing Confluence page.

.DESCRIPTION
    Add Attachments (one or more) to Confluence pages (one or more). If the Attachment did not exist previously, it will be created.
    This will not update an already existing Attachment; see Set-Attachment for updating a file.

.PARAMETER PageID
    The ID of the page to which apply the Attachment to. Accepts multiple IDs, including via pipeline input.

.PARAMETER FilePath
    One or more files to be added.

.EXAMPLE
    Add-ConfluenceAttachment -PageID 123456 -FilePath test.png -Verbose
    Adds the Attachment test.png to the wiki page with ID 123456. -Verbose output provides extra technical details, if interested.

.EXAMPLE
    Get-ConfluencePage -SpaceKey SRV | Add-ConfluenceAttachment -FilePath test.png -WhatIf
    Simulates adding the Attachment test.png to all pages in the space with key SRV. -WhatIf provides PageIDs of pages that would have been affected.

.OUTPUTS
    ConfluencePS.Attachment
#>
function Add-Attachment {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.Attachment])]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [Alias('ID')]
        [System.UInt64]$PageID,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
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
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                } else {
                    return $true
                }
            }
        )]
        [Alias('InFile', 'FullName', 'Path', 'PSPath')]
        [System.String[]]
        $FilePath
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri = "$($Script:ApiUri)/content/{0}/child/attachment" -f $PageID
            Method = "Post"
            OutputType = [ConfluencePS.Attachment]
        }

        foreach ($file in $FilePath) {
            $iwParameters["InFile"] = $file

            Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Invoking Add Attachment Method with `$parameter"
            if ($PSCmdlet.ShouldProcess($PageID, "Adding attachment(s) '$($file)'.")) {
                Invoke-Method @iwParameters
            }
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
