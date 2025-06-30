<#
.SYNOPSIS
    Retrieve the child pages of a given wiki page or pages.

.DESCRIPTION
    Return all pages directly below the given page(s).
    Optionally, the -Recurse parameter will return all child pages, no matter how nested.  Pass the optional parameter -ExcludePageBody to avoid fetching the pages' HTML content.

.PARAMETER PageID
    Filter results by page ID.

.PARAMETER Recurse
    Get all child pages recursively

.PARAMETER PageSize
    Maximum number of results to fetch per call. This setting can be tuned to get better performance according to the load on the server. > Warning: too high of a PageSize can cause a timeout on the request.

.PARAMETER IncludeTotalCount
    > NOTE: Not yet implemented. Causes an extra output of the total count at the beginning. Note this is actually a uInt64, but with a custom string representation.

.PARAMETER Skip
    Controls how many things will be skipped before starting output. Defaults to 0.

.PARAMETER First
    > NOTE: Not yet implemented. Indicates how many items to return.

.PARAMETER ExcludePageBody
    Avoids fetching pages' body

.EXAMPLE
    Get-ConfluenceChildPage -PageID 123456
    Get-ConfluencePage -PageID 123456 | Get-ConfluenceChildPage
    Two different methods to return all pages directly below page 123456. Both examples should return identical results.

.EXAMPLE
    Get-ConfluenceChildPage -PageID 123456 -Recurse
    Instead of returning only 123456's child pages, return grandchildren, great-grandchildren, and so on.

.OUTPUTS
    ConfluencePS.Page
#>
function Get-ChildPage {
    [CmdletBinding(SupportsPaging = $true)]
    [OutputType([ConfluencePS.Page])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [Alias('ID')]
        [System.UInt64]$PageID,

        [Parameter()]
        [switch]
        $Recurse,

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
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        #Fix: See fix statement below. These two fix statements are tied together
        if ($null -ne $_ -and ($_ -isnot [ConfluencePS.Page] -and $_ -isnot [System.UInt64])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            throw $exception
        }

        #Fix: This doesn't get called since there are no parameter sets for this function. It must be
        #copy paste from another function. This function doesn't really accept ConfluencePS.Page objects, it only
        #works due to powershell grabbing the 'ID' from ConfluencePS.Page using the
        #'ValueFromPipelineByPropertyName = $true' and '[Alias('ID')]' on the PageID Parameter.
        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $PageID = $InputObject.ID
        }

        $iwParameters = @{
            Uri = if ($Recurse.IsPresent) {
                "$($Script:ApiUri)/content/{0}/descendant/page" -f $PageID
            } else {
                "$($Script:ApiUri)/content/{0}/child/page" -f $PageID
            }
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

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        Invoke-Method @iwParameters
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
