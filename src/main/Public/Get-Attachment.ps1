<#
.SYNOPSIS
    Retrieve the child Attachments of a given wiki Page.

.DESCRIPTION
    Return all Attachments directly below the given Page.

.PARAMETER PageID
    Return attachments for a list of page IDs.

.PARAMETER FileNameFilter
    Filter results by filename (case sensitive). Does not support wildcards (*).

.PARAMETER MediaTypeFilter
    Filter results by media type (case insensitive). Does not support wildcards (*).

.PARAMETER PageSize
    Maximum number of results to fetch per call. This setting can be tuned to get better performance according to the load on the server. > Warning: too high of a PageSize can cause a timeout on the request.

.PARAMETER Skip
    Controls how many things will be skipped before starting output. Defaults to 0.

.PARAMETER First
    > NOTE: Not yet implemented. Indicates how many items to return.

.PARAMETER IncludeTotalCount
    > NOTE: Not yet implemented. Causes an extra output of the total count at the beginning. Note this is actually a uInt64, but with a custom string representation.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456
    Get-ConfluencePage -PageID 123456 | Get-ConfluenceAttachment
    Two different methods to return all Attachments directly below Page 123456. Both examples should return identical results.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456, 234567
    Get-ConfluencePage -PageID 123456, 234567 | Get-ConfluenceAttachment
    Similar to the previous example, this shows two different methods to return the Attachments of multiple pages. Both examples should return identical results.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456 -FileNameFilter "test.png"
    Returns the Attachment called test.png from Page 123456 if it exists.

.EXAMPLE
    Get-ConfluenceAttachment -PageID 123456 -MediaTypeFilter "image/png"
    Returns any attachments of mime type image/png from Page 123456.

.OUTPUTS
    ConfluencePS.Attachment
#>
function Get-Attachment {
    [CmdletBinding(SupportsPaging = $true)]
    [OutputType([ConfluencePS.Attachment])]
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
        [System.String]
        $FileNameFilter,

        [Parameter()]
        [System.String]
        $MediaTypeFilter,

        [Parameter()]
        [ValidateRange(1, [System.UInt32]::MaxValue)]
        [System.UInt32]$PageSize = 25
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [System.UInt64])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            throw $exception
        }

        $iwParameters = @{
            Method = "Get"
            GetParameters = @{
                expand = "version"
                limit  = $PageSize
            }
            OutputType = [ConfluencePS.Attachment]
        }

        if ($FileNameFilter) {
            $iwParameters["GetParameters"]["filename"] = $FileNameFilter
        }

        if ($MediaTypeFilter) {
            $iwParameters["GetParameters"]["mediaType"] = $MediaTypeFilter
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        foreach ($_PageID in $PageID) {
            $iwParameters['Uri'] = "$($Script:ApiUri)/content/{0}/child/attachment" -f $_PageID
            Invoke-Method @iwParameters
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
