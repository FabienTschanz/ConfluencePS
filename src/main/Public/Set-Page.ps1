<#
.SYNOPSIS
    Edit an existing Confluence page.

.DESCRIPTION
    For existing page(s): Edit page content, page title, and/or change parent page.
    Content needs to be in "Confluence storage format". Use `-Convert` if not preconditioned.

.PARAMETER InputObject
    Page Object which will be used to replace the current content.

.PARAMETER PageID
    The ID of the page to edit.

.PARAMETER Title
    Name of the page; existing or new value can be used. Existing will be automatically supplied via Get-Page if not manually included.

.PARAMETER Body
    The full contents of the updated body (existing contents will be overwritten). If not yet in "storage format"--or you don't know what that is--also use -Convert.

.PARAMETER Convert
    Optional switch flag for calling ConvertTo-ConfluenceStorageFormat against your Body.

.PARAMETER ParentID
    Optionally define a new parent page. If unspecified, no change.

.PARAMETER Parent
    Optionally define a new parent page. If unspecified, no change.

.EXAMPLE
    Set-ConfluencePage -PageID 123456 -Title 'Counting'
    For existing wiki page 123456, change its name to "Counting".

.EXAMPLE
    Set-ConfluencePage -PageID 123456 -Body 'Hello World!' -Convert
    For existing wiki page 123456, update its page contents to "Hello World!" -Convert applies the "Confluence storage format" to your given string.

.EXAMPLE
    Set-ConfluencePage -PageID 123456 -ParentID 654321
    Set-ConfluencePage -PageID 123456 -Parent (Get-ConfluencePage -PageID 654321)
    Two different methods to set a new parent page. Parent page 654321 will now have child page 123456.

.EXAMPLE
    $page = Get-ConfluencePage -PageID 123456
    $page.Title = "New Title"

    Set-ConfluencePage -InputObject $page
    $page | Set-ConfluencePage
    Two different methods to set a new parent page using a `ConfluencePS.Page` object.

.OUTPUTS
    ConfluencePS.Page
#>
function Set-Page {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byParameters'
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byObject'
        )]
        [ConfluencePS.Page]
        $InputObject,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [Alias('ID')]
        [System.UInt64]
        $PageID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Title,

        [Parameter(ParameterSetName = 'byParameters')]
        [System.String]
        $Body,

        [Parameter(ParameterSetName = 'byParameters')]
        [switch]
        $Convert,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [System.UInt64]
        $ParentID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Page]
        $Parent
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content/{0}"

        # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
        if ($Convert) {
            Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-StorageFormat -Content $Body
        }
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Method = "Put"
            OutputType = [ConfluencePS.Page]
        }

        $Content = [PSObject]@{
            type      = "page"
            title     = ""
            body      = [PSObject]@{
                storage = [PSObject]@{
                    value          = ""
                    representation = 'storage'
                }
            }
            version   = [PSObject]@{
                number = 0
            }
            ancestors = @()
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                $iwParameters["Uri"] = $resourceApi -f $InputObject.ID
                $Content.version.number = ++$InputObject.Version.Number
                $Content.title = $InputObject.Title
                $Content.body.storage.value = $InputObject.Body
                # if ($InputObject.Ancestors) {
                # $Content["ancestors"] += @( $InputObject.Ancestors | Foreach-Object { @{ id = $_.ID } } )
                # }
            }
            "byParameters" {
                $iwParameters["Uri"] = $resourceApi -f $PageID
                $originalPage = Get-Page -PageID $PageID

                if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }

                $Content.version.number = ++$originalPage.Version.Number
                if ($Title) {
                    $Content.title = $Title
                } else {
                    $Content.title = $originalPage.Title
                }

                # $Body might be empty
                if ($PSBoundParameters.Keys -contains "Body") {
                    $Content.body.storage.value = $Body
                } else {
                    $Content.body.storage.value = $originalPage.Body
                }

                # Ancestors is undocumented! May break in the future
                # http://stackoverflow.com/questions/23523705/how-to-create-new-page-in-confluence-using-their-rest-api
                if ($ParentID) {
                    $Content.ancestors = @( @{ id = $ParentID } )
                }
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        if ($PSCmdlet.ShouldProcess("Page $($Content.title)")) {
            Invoke-Method @iwParameters
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
