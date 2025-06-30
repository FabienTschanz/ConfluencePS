<#
.SYNOPSIS
    Replace any invalid filename characters from a string with underscores
#>
function Remove-InvalidFileCharacter {
    [CmdletBinding()]
    [OutputType([System.String])]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [System.String]
        $InputString
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"
        $InvalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
        $RegExInvalid = "[{0}]" -f [RegEx]::Escape($InvalidChars)
    }

    process {
        foreach ($_string in $InputString) {
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Removing invalid characters"
            $_string -replace $RegExInvalid, '_'
        }
    }
}
