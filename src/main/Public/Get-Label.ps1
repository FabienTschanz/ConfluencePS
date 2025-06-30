<#
.SYNOPSIS
    Retrieve all labels applied to the given object(s).

.DESCRIPTION
    Currently, this command only returns a label list from wiki pages. It is intended to eventually support other content types as well.

.PARAMETER PageID
    List the PageID number to check for labels. Accepts piped input.

.PARAMETER PageSize
    Maximum number of results to fetch per call. This setting can be tuned to get better performance according to the load on the server. > Warning: too high of a PageSize can cause a timeout on the request.

.PARAMETER IncludeTotalCount
    > NOTE: Not yet implemented. Causes an extra output of the total count at the beginning. Note this is actually a uInt64, but with a custom string representation.

.PARAMETER Skip
    > NOTE: Not yet implemented. Controls how many things will be skipped before starting output. Defaults to 0.

.PARAMETER First
    > NOTE: Not yet implemented. Indicates how many items to return.

.EXAMPLE
    Get-ConfluenceLabel -PageID 123456
    Returns all labels applied to wiki page 123456.

.EXAMPLE
    Get-ConfluencePage -SpaceKey HOTH -Label skywalker | Get-ConfluenceLabel
    For all pages in HOTH with the "skywalker" label applied, return the full list of labels found on each page.

.OUTPUTS
    ConfluencePS.ContentLabelSet
#>
function Get-Label {
    [CmdletBinding(SupportsPaging = $true)]
    [OutputType([ConfluencePS.ContentLabelSet])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [Alias('ID')]
        [System.UInt64[]]$PageID,

        [Parameter()]
        [ValidateRange(1, [System.UInt32]::MaxValue)]
        [System.UInt32]
        $PageSize = 25
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content/{0}/label"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($null -ne $_ -and ($_ -isnot [ConfluencePS.Page] -and $_ -isnot [System.UInt64])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            throw $exception
        }

        $iwParameters = @{
            Method = "Get"
            GetParameters = @{
                limit = $PageSize
            }
            OutputType = [ConfluencePS.Label]
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePS.Page]) {
                $InputObject = $_
            }
            else {
                $InputObject = Get-Page -PageID $_page
            }
            $iwParameters["Uri"] = $resourceApi -f $_page
            $output = New-Object -TypeName ConfluencePS.ContentLabelSet
            $output.Page = $InputObject
            $output.Labels += (Invoke-Method @iwParameters)
            $output
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
