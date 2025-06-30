<#
.SYNOPSIS
    Retrieve a listing of spaces in your Confluence instance.

.DESCRIPTION
    Return all Confluence spaces, optionally filtering by Key.

.PARAMETER SpaceKey
    Filter results by key. Supports wildcard matching on partial input.

.PARAMETER PageSize
    Maximum number of results to fetch per call. This setting can be tuned to get better performance according to the load on the server. > Warning: too high of a PageSize can cause a timeout on the request.

.PARAMETER IncludeTotalCount
    > NOTE: Not yet implemented. Causes an extra output of the total count at the beginning. Note this is actually a uInt64, but with a custom string representation.

.PARAMETER Skip
    > NOTE: Not yet implemented. Controls how many objects will be skipped before starting output. Defaults to 0.

.PARAMETER First
    > NOTE: Not yet implemented. Indicates how many items to return.

.EXAMPLE
    Get-ConfluenceSpace
    Display the info of all spaces on the server.

.EXAMPLE
    Get-ConfluenceSpace -SpaceKey HOTH | Format-List *
    Return only the space with key "HOTH" (case-insensitive).
    `Format-List *` displays all of the object's properties.

.EXAMPLE
    Get-ConfluenceSpace -ApiUri "https://myserver.com/wiki" -Credential $cred
    Manually specifying a server and authentication credentials, list all spaces found on the instance. `Set-ConfluenceInfo` usually makes this unnecessary, unless you are actively maintaining multiple instances.

.OUTPUTS
    ConfluencePS.Space
#>
function Get-Space {
    [CmdletBinding(SupportsPaging = $true)]
    [OutputType([ConfluencePS.Space])]
    param (
        [Parameter(Position = 0)]
        [Alias('Key')]
        [System.String[]]
        $SpaceKey,

        [Parameter()]
        [ValidateRange(1, [System.UInt32]::MaxValue)]
        [System.UInt32]
        $PageSize = 25
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/space{0}"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Method = "Get"
            GetParameters = @{
                expand = "description.plain,icon,homepage,metadata.labels"
                limit  = $PageSize
            }
            OutputType = [ConfluencePS.Space]
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        if ($SpaceKey) {
            foreach ($_space in $SpaceKey) {
                $iwParameters["Uri"] = $resourceApi -f "/$_space"
                Invoke-Method @iwParameters
            }
        } else {
            $iwParameters["Uri"] = $resourceApi -f ""
            Invoke-Method @iwParameters
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
