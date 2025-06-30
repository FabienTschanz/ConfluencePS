<#
.SYNOPSIS
    Convert your content to Confluence's wiki markup table format.

.DESCRIPTION
    Formats input as a table with a horizontal header row. This wiki formatting is an intermediate step, and would still need ConvertTo-ConfluenceStorageFormat called against it.
    This work is performed locally, and does not perform a REST call.

.PARAMETER Content
    The object array you would like to see displayed as a table on a wiki page.

.PARAMETER Vertical
    Create a vertical, two-column table.

.PARAMETER NoHeader
    Ignore the property names, keeping a table of values with no header row highlighting. In a vertical table, the property names remain, but the bold highlighting is removed.

.EXAMPLE
    Get-Service | Select-Object Name,DisplayName,Status -First 10 | ConvertTo-ConfluenceTable
    List the first ten services on your computer, and convert to a table in Confluence markup format.

.EXAMPLE
    $SvcTable = Get-Service | Select-Object Name,Status -First 10 |
        ConvertTo-ConfluenceTable | ConvertTo-ConfluenceStorageFormat
    Following Example 1, convert the table from wiki markup format into storage format. Store the results in $SvcTable for a later New-ConfluencePage/etc. command.

.EXAMPLE
    Get-Alias | Where-Object {$_.Name.Length -eq 1} | Select-Object CommandType,DisplayName |
        ConvertTo-ConfluenceTable -NoHeader
    Make a table of all one-character PowerShell aliases, and don't include the header row.

.EXAMPLE
    [PSCustomObject]@{Name = 'Max'; Age = 123} | ConvertTo-ConfluenceTable -Vertical
    Output a vertical table instead. Property names will be a left header column with bold highlighting. Property values will be in a normal right column. Multiple objects will output as multiple tables, one on top of the next.

.EXAMPLE
    Get-Alias | Where-Object {$_.Name.Length -eq 1} | Select-Object Name,Definition |
        ConvertTo-ConfluenceTable -Vertical -NoHeader
    Output one string containing four vertical tables (one for each object returned). Property names are still displayed, but -NoHeader suppresses the bold highlighting.

.OUTPUTS
    System.String
#>
function ConvertTo-Table {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [PSCustomObject[]]$Content,

        [Parameter()]
        [Switch]
        $Vertical,

        [Parameter()]
        [Switch]
        $NoHeader
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $sb = [System.Text.StringBuilder]::new()
        $HeaderGenerated = $NoHeader
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # This ForEach needed if the content wasn't piped in
        $Content | ForEach-Object {
            if ($Vertical) {
                if ($HeaderGenerated) {
                    $pipe = '|'
                } else {
                    $pipe = '||'
                }

                # Put an empty row between multiple tables (objects)
                if ($Spacer) {
                    $null = $sb.AppendLine('')
                }

                $_.PSObject.Properties | ForEach-Object {
                    $row = ("$pipe {0} $pipe {1} |" -f $_.Name, $_.Value) -replace "\|\s\s", "| "
                    $null = $sb.AppendLine($row)
                }

                $Spacer = $true
            } else {
                # Header row enclosed by ||
                if (-not $HeaderGenerated) {
                    $null = $sb.AppendLine("|| {0} ||" -f ($_.PSObject.Properties.Name -join " || "))
                    $HeaderGenerated = $true
                }

                # All other rows enclosed by |
                foreach ($property in $_.PSObject.Properties) {
                    switch ($property.Value.GetType().Name) {
                        "Object[]" { $property.Value = $property.Value -join ", " }
                        default { }
                    }
                }
                $row = ("| " + ($_.PSObject.Properties.Value -join " | ") + " |") -replace "\|\s\s", "| "
                $null = $sb.AppendLine($row)
            }
        }
    }

    end {
        # Return the array as one large, multi-line string
        $sb.ToString()
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
