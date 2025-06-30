 <#
.SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
#>
function ConvertTo-Attachment {
    [CmdletBinding()]
    [OutputType([ConfluencePS.Attachment])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Converting Object to Attachment"

            if ($_.container.id) {
                $PageId = $_.container.id
            }
            else {
                [System.UInt32]$PageID = $_._expandable.container -replace '^.*\/content\/', ''
            }

            [ConfluencePS.Attachment](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{
                        Name = "id"
                        Expression = {
                            [System.UInt64]($_.id -replace 'att', '')
                        }
                    },
                    status,
                    title,
                    @{
                        Name = "filename"
                        Expression = {
                            '{0}_{1}' -f $PageID, $_.title | Remove-InvalidFileCharacter
                        }
                    },
                    @{
                        Name = "mediatype"
                        Expression = {
                            $_.extensions.mediaType
                        }
                    },
                    @{
                        Name = "filesize"
                        Expression = {
                            [convert]::ToInt32($_.extensions.fileSize, 10)
                        }
                    },
                    @{
                        Name = "comment"
                        Expression = {
                            $_.extensions.comment
                        }
                    },
                    @{
                        Name = "spacekey"
                        Expression = {
                            $_._expandable.space -replace '^.*\/space\/', ''
                        }
                    },
                    @{
                        Name = "pageid"
                        Expression = {
                            $PageID
                        }
                    },
                    @{
                        Name = "version"
                        Expression = {
                            if ($_.version) {
                                ConvertTo-Version $_.version
                            }
                            else {
                                $null
                            }
                        }
                    },
                    @{
                        Name = "URL"
                        Expression = {
                            $base = $_._links.base
                            if (-not ($base)) {
                                $base = $_._links.self -replace '\/rest.*', ''
                            }
                            if ($_._links.download) {
                                "{0}{1}" -f $base, $_._links.download
                            } else {
                                $null
                            }
                        }
                    }
                )
            )
        }
    }
}
