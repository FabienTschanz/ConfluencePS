<#
.SYNOPSIS
    Retrieve a listing of pages in your Confluence instance.

.DESCRIPTION
    Return Confluence pages, filtered by ID, Name, or Space. Pass the optional parameter -ExcludePageBody to avoid fetching the pages' HTML content.

.PARAMETER PageID
    Filter results by page ID. Best option if you already know the ID.

.PARAMETER Title
    Filter results by page name (case-insensitive). This supports wildcards (*) to allow for partial matching.

.PARAMETER SpaceKey
    Filter results by space key (case-insensitive).

.PARAMETER Space
    Filter results by space object(s), typically from the pipeline.

.PARAMETER Label
    Filter results to only pages with the specified label(s).

.PARAMETER Query
    Use Confluences advanced search: CQL (https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/). This cmdlet will always append a filter to only look for pages (`type=page`).

.PARAMETER PageSize
    Maximum number of results to fetch per call. This setting can be tuned to get better performance according to the load on the server. > Warning: too high of a PageSize can cause a timeout on the request.

.PARAMETER IncludeTotalCount
    > NOTE: Not yet implemented. Causes an extra output of the total count at the beginning. Note this is actually a uInt64, but with a custom string representation.

.PARAMETER Skip
    > NOTE: Not yet implemented. Controls how many things will be skipped before starting output. Defaults to 0.

.PARAMETER First
    > NOTE: Not yet implemented. Indicates how many items to return.

.PARAMETER ExcludePageBody
    Avoids fetching pages' body

.EXAMPLE
    Get-ConfluencePage -SpaceKey HOTH
    Get-ConfluenceSpace -SpaceKey HOTH | Get-ConfluencePage
    Two different methods to return all wiki pages in space "HOTH". Both examples should return identical results.

.EXAMPLE
    Get-ConfluencePage -PageID 123456 | Format-List *
    Returns the wiki page with ID 123456. `Format-List *` displays all of the object's properties, including the full page body.

.EXAMPLE
    Get-ConfluencePage -Title 'luke*' -SpaceKey HOTH
    Return all pages in HOTH whose names start with "luke" (case-insensitive). Wildcards (*) can be inserted to support partial matching.

.EXAMPLE
    Get-ConfluencePage -Label 'skywalker'
    Return all pages containing the label "skywalker" (case-insensitive). Label text must match exactly; no wildcards are applied.

.EXAMPLE
    Get-ConfluencePage -Query "mention = jSmith and creator != jSmith"
    Return all pages matching the query.

.EXAMPLE
    Get-ConfluencePage -Label 'skywalker' -ExcludePageBody
    Return all pages containing the label "skywalker" (case-insensitive) without their page content.

.OUTPUTS
    ConfluencePS.Page
#>
function Get-Page {
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byId"
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "byId",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [Alias('ID')]
        [System.UInt64[]]$PageID,

        [Parameter(ParameterSetName = "bySpace")]
        [Parameter(ParameterSetName = "bySpaceObject")]
        [Alias('Name')]
        [System.String]
        $Title,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "bySpace"
        )]
        [Parameter(ParameterSetName = "byLabel")]
        [Alias('Key')]
        [System.String]
        $SpaceKey,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "bySpaceObject"
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = "byLabel"
        )]
        [ConfluencePS.Space]
        $Space,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byLabel"
        )]
        [System.String[]]
        $Label,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "byQuery"
        )]
        [System.String]
        $Query,

        [Parameter()]
        [ValidateRange(1, [System.UInt32]::MaxValue)]
        [System.UInt32]
        $PageSize = 25,

        [Parameter()]
        [switch]
        $ExcludePageBody
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content{0}"

        # setup defaults that don't change based on the pipeline or the parameter set
        $iwParameters = @{
            Method = "Get"
            GetParameters = @{
                expand = "space,version,body.storage,ancestors"
                limit  = $PageSize
            }
            OutputType = [ConfluencePS.Page]
        }

        if ($ExcludePageBody) {
            $iwParameters.GetParameters.expand = "space,version,ancestors"
        }
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Space -is [ConfluencePS.Space] -and ($Space.Key)) {
            $SpaceKey = $Space.Key
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        switch -regex ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($_pageID in $PageID) {
                    $iwParameters["Uri"] = $resourceApi -f "/$_pageID"
                    Invoke-Method @iwParameters
                }
                break
            }
            "bySpace" {
                # This includes 'bySpaceObject'
                $iwParameters["Uri"] = $resourceApi -f ''
                $iwParameters["GetParameters"]["type"] = "page"
                if ($SpaceKey) {
                    $iwParameters["GetParameters"]["spaceKey"] = $SpaceKey
                }

                if ($Title) {
                    Invoke-Method @iwParameters | Where-Object { $_.Title -like "*$Title*" }
                } else {
                    Invoke-Method @iwParameters
                }
                break
            }
            "byLabel" {
                $iwParameters["Uri"] = $resourceApi -f "/search"

                $CQLparameters = @("type=page", "label=$Label")
                if ($SpaceKey) {
                    $CQLparameters += "space=$SpaceKey"
                }
                $cqlQuery = ConvertTo-URLEncoded ($CQLparameters -join (" AND "))

                $iwParameters["GetParameters"]["cql"] = $cqlQuery
                Invoke-Method @iwParameters
                break
            }
            "byQuery" {
                $iwParameters["Uri"] = $resourceApi -f "/search"

                $cqlQuery = ConvertTo-URLEncoded $Query
                $iwParameters["GetParameters"]["cql"] = "type=page AND $cqlQuery"
                Invoke-Method @iwParameters
            }
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
