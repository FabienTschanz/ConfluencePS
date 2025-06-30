<#
.SYNOPSIS
    Remove an existing Confluence space.

.DESCRIPTION
    Delete an existing Confluence space, including child content.
    > Note: The space is deleted in a long running task, so the space cannot be considered deleted when this resource returns.

.PARAMETER SpaceKey
    The key (short code) of the space to delete. Accepts multiple keys via pipeline input.

.PARAMETER Force
    Forces the deletion of the space without prompting for confirmation.

.EXAMPLE
    Remove-ConfluenceSpace -SpaceKey ABC -WhatIf
    Simulates the deletion of wiki space ABC and all child content. -WhatIf parameter prevents removal of content.

.EXAMPLE
    Remove-ConfluenceSpace -SpaceKey XYZ -Force
    Delete wiki space XYZ and all child content below it.
    By default, you will be prompted to confirm removal. ("Are you sure? Y/N") -Force suppresses all confirmation prompts and carries out the deletion.

.OUTPUTS
    System.Boolean
#>
function Remove-Space {
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true
    )]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [System.String[]]
        $SpaceKey,

        [Parameter()]
        [switch]
        $Force

        # TODO: Probably an extra param later to loop checking the status & wait for completion?
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/space/{0}"

        if ($Force) {
            Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not ($_ -is [ConfluencePS.Space] -or $_ -is [System.String])) {
            $message = "The Object in the pipe is not a Space."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            throw $exception
        }

        $iwParameters = @{
            Method = "Delete"
        }

        foreach ($_space in $SpaceKey) {
            $iwParameters["Uri"] = $resourceApi -f $_space

            if ($PSCmdlet.ShouldProcess("Space key $_space")) {
                $response = Invoke-Method @iwParameters

                # Successful response provides a "longtask" status link
                # (add additional code here later to check and/or wait for the status)
            }
        }
    }

    end {
        if ($Force) {
            Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
