<#
.SYNOPSIS
    Create a new blank space on your Confluence instance.

.DESCRIPTION
    Create a new blank space.
    A value for `Key` and `Name` is mandatory. Not so for `Description`, although recommended.

.PARAMETER InputObject
    Space Object from which to create the new space.

.PARAMETER SpaceKey
    Specify the short key to be used in the space URI.

.PARAMETER Name
    Specify the space's name.

.PARAMETER Description
    A short description of the new space.

.EXAMPLE
    New-ConfluenceSpace -Key 'HOTH' -Name 'Planet Hoth' -Description "It's really cold" -Verbose
    Create a new blank space with an optional description and verbose output.

.EXAMPLE
    $spaceObject = [ConfluencePS.Space]@{
        Key         = "HOTH"
        Name        = "Planet Hoth"
        Description = "It's really cold"
    }

    # example 1
    New-ConfluenceSpace -InputObject $spaceObject
    # example 2
    $spaceObject | New-ConfluenceSpace
    Two different methods of creating a new space from an object `ConfluencePS.Space`.
    Both examples should return identical results.

.OUTPUTS
    ConfluencePS.Space
#>

function New-Space {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "byObject"
    )]
    [OutputType([ConfluencePS.Space])]
    param (
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byObject",
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Space]
        $InputObject,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byProperties"
        )]
        [Alias('Key')]
        [System.String]
        $SpaceKey,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byProperties"
        )]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = "byProperties")]
        [System.String]
        $Description
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/space"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $SpaceKey = $InputObject.Key
            $Name = $InputObject.Name
            $Description = $InputObject.Description
        }

        $iwParameters = @{
            Uri = $resourceApi
            Method = "Post"
            OutputType = [ConfluencePS.Space]
        }

        $Body = @{
            key         = $SpaceKey
            name        = $Name
            description = @{
                plain = @{
                    value          = $Description
                    representation = 'plain'
                }
            }
        }

        $iwParameters["Body"] = $Body | ConvertTo-Json

        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Body | Out-String)"
        if ($PSCmdlet.ShouldProcess("$SpaceKey $Name")) {
            Invoke-Method @iwParameters
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
