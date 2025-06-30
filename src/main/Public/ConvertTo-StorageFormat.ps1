<#
.SYNOPSIS
    Convert your content to Confluence's storage format.

.DESCRIPTION
    To properly create/edit pages, content should be in the proper "XHTML-based" format. Invokes a POST call to convert from a "wiki" representation, receiving a "storage" response.

.PARAMETER Content
    A string (in plain text and/or wiki markup) to be converted to storage format.

.EXAMPLE
    $Body = ConvertTo-ConfluenceStorageFormat -Content 'Hello world!'
    Stores the returned value '<p>Hello world!</p>' in $Body for use in New-ConfluencePage/Set-ConfluencePage/etc.

.EXAMPLE
    Get-Date -Format s | ConvertTo-ConfluenceStorageFormat
    Pipe the current date/time in sortable format, returning the converted string.

.OUTPUTS
    System.String
#>
function ConvertTo-StorageFormat {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String[]]
        $Content
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri = "$($Script:ApiUri)/contentbody/convert/storage"
            Method = "Post"
        }

        foreach ($_content in $Content) {
            $iwParameters['Body'] = @{
                value          = "$_content"
                representation = 'wiki'
            } | ConvertTo-Json

            Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($_content | Out-String)"
            (Invoke-Method @iwParameters).value
        }
    }

    end {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
