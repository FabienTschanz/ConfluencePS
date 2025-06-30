<#
.SYNOPSIS
    Create a new page on your Confluence instance.

.DESCRIPTION
    Create a new page on Confluence.
    Optionally include content in -Body. Body content needs to be in "Confluence storage format" -- see also -Convert.

.PARAMETER InputObject
    A ConfluencePS.Page object from which to create a new page.

.PARAMETER Title
    Name of your new page.

.PARAMETER ParentID
    The ID of the parent page. > NOTE: This feature is not in the 5.8 REST API documentation, and should be considered experimental.

.PARAMETER Parent
    Supply a ConfluencePS.Page object to use as the parent page.

.PARAMETER SpaceKey
    Key of the space where the new page should exist. Only needed if you don't specify a parent page.

.PARAMETER Space
    Space Object in which to create the new page. Only needed if you don't specify a parent page.

.PARAMETER Body
    The contents of your new page.

.PARAMETER Convert
    Optionally, convert the provided body to Confluence's storage format. Has the same effect as calling ConvertTo-ConfluenceStorageFormat against your Body.

.EXAMPLE
    New-ConfluencePage -Title 'Test New Page' -SpaceKey Hoth
    Create a new blank wiki page at the root of space "Hoth".

.EXAMPLE
    New-ConfluencePage -Title 'Luke Skywalker' -Parent (Get-ConfluencePage -Title 'Darth Vader' -SpaceKey 'StarWars')
    Creates a new blank wiki page as a child page below "Darth Vader" in the specified space.

.EXAMPLE
    New-ConfluencePage -Title 'Luke Skywalker' -ParentID 123456 -Verbose
    Creates a new blank wiki page as a child page below the wiki page with ID 123456.
    -Verbose provides extra technical details, if interested.

.EXAMPLE
    New-ConfluencePage -Title 'foo' -SpaceKey 'bar' -Body $PageContents
    Create a new wiki page named 'foo' at the root of space 'bar'. The wiki page will contain the data stored in $PageContents.

.EXAMPLE
    New-ConfluencePage -Title 'foo' -SpaceKey 'bar' -Body 'Testing 123' -Convert
    Create a new wiki page named 'foo' at the root of space 'bar'.
    The wiki page will contain the text "Testing 123". -Convert will condition the -Body parameter's string into storage format.

.EXAMPLE
    $pageObject = [ConfluencePS.Page]@{
        Title = "My Title"
        Space = [ConfluencePS.Space]@{
            Key="ABC"
        }
    }

    # example 1
    New-ConfluencePage -InputObject $pageObject
    # example 2
    $pageObject | New-ConfluencePage
    Two different methods of creating a new page from an object `ConfluencePS.Page`.
    Both examples should return identical results.

.OUTPUTS
    ConfluencePS.Page
#>

function New-Page {
    [CmdletBinding(
        ConfirmImpact = 'Low',
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
        [ConfluencePS.Page]$InputObject,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [Alias('Name')]
        [System.String]$Title,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [System.UInt64]::MaxValue)]
        [System.UInt64]
        $ParentID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Page]
        $Parent,

        [Parameter(ParameterSetName = 'byParameters')]
        [System.String]
        $SpaceKey,

        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Space]
        $Space,

        [Parameter(ParameterSetName = 'byParameters')]
        [System.String]
        $Body,

        [Parameter(ParameterSetName = 'byParameters')]
        [switch]
        $Convert
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$($Script:ApiUri)/content"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri = $resourceApi
            Method = "Post"
            OutputType = [ConfluencePS.Page]
        }

        $Content = [PSObject]@{
            type      = "page"
            space     = [PSObject]@{ key = "" }
            title     = ""
            body      = [PSObject]@{
                storage = [PSObject]@{
                    representation = 'storage'
                }
            }
            ancestors = @()
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                $Content.title = $InputObject.Title
                $Content.space.key = $InputObject.Space.Key
                $Content.body.storage.value = $InputObject.Body
                if ($InputObject.Ancestors) {
                    $Content.ancestors += @( $InputObject.Ancestors | ForEach-Object { @{ id = $_.ID } } )
                }
            }
            "byParameters" {
                if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }
                if (($Space -is [ConfluencePS.Space]) -and ($Space.Key)) {
                    $SpaceKey = $Space.Key
                }

                if (($ParentID) -and -not ($SpaceKey)) {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] SpaceKey not specified. Retrieving from Get-ConfluencePage -PageID $ParentID"
                    $SpaceKey = (Get-Page -PageID $ParentID @authAndApiUri).Space.Key
                }

                # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
                if ($Convert) {
                    Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
                    $Body = ConvertTo-StorageFormat -Content $Body
                }

                $Content.title = $Title
                $Content.space = @{ key = $SpaceKey }
                $Content.body.storage.value = $Body
                if ($ParentID) {
                    $Content.ancestors = @( @{ id = $ParentID } )
                }
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        if ($PSCmdlet.ShouldProcess("Space $($Content.space.key)")) {
            Invoke-Method @iwParameters
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
