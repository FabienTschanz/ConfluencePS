<#
.SYNOPSIS
    Retrieves the binary Attachment for a given Attachment object.

.DESCRIPTION
    Retrieves the binary Attachment for a given Attachment object.
    As the files are stored in a location of the server that requires authentication, this functions allows the download of the Attachment in the same way as the rest of the module authenticates with the server.

.PARAMETER Attachment
    Attachment object to download.

.PARAMETER Path
    Override the path used to save the files.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456 | Get-ConfluenceAttachmentFile
    Save any attachments of page 123456 to the current directory with each filename constructed with the page ID and the attachment filename.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456 | Get-ConfluenceAttachmentFile -Path "c:\temp_dir"
    Save any attachments of page 123456 to a specific directory with each filename constructed with the page ID and the attachment filename.

.OUTPUTS
    ConfluencePS.Attachment
#>
function Get-AttachmentFile {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Attachment[]]
        $Attachment,

        [Parameter()]
        [ValidateScript(
            {
                if (-not (Test-Path $_)) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Path not found"),
                        'ParameterValue.FileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $_
                    )
                    $errorItem.ErrorDetails = "Invalid path '$_'."
                    $PSCmdlet.throwTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [System.String]
        $Path
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($null -ne $_ -and $_ -isnot [ConfluencePS.Attachment]) {
            $message = "The Object in the pipe is not an Attachment."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            throw $exception
        }

        $iwParameters = @{
            Method = "Get"
        }

        foreach ($_Attachment in $Attachment) {
            $iwParameters['Uri'] = $_Attachment.URL
            $iwParameters['Headers'] = @{
                "Accept" = $_Attachment.MediaType
            }
            $iwParameters['OutFile'] = if ($Path) {
                Join-Path -Path $Path -ChildPath $_Attachment.Filename
            } else {
                $_Attachment.Filename
            }

            $result = Invoke-Method @iwParameters
            (-not $result)
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}


