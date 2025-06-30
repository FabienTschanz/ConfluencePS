<#
.SYNOPSIS
    Specify wiki location and authorization for use in this session's REST API requests.

.DESCRIPTION
    Set-ConfluenceInfo uses scoped variables and PSDefaultParameterValues to supply URI/auth info to all other functions in the module (e.g. Get-ConfluenceSpace). These session defaults can be overwritten on any single command, but using Set-ConfluenceInfo avoids repetitively specifying -ApiUri and -Credential parameters.
    Confluence's REST API supports passing basic authentication in headers. (If you have a better suggestion for how to handle auth, please reach out on GitHub!)
    Unless allowing anonymous access to your instance, credentials are needed.

.PARAMETER BaseURi
    Address of your base Confluence install. For Atlassian Cloud instances, include /wiki.

.PARAMETER Credential
    The username/password combo you use to log in to Confluence.

.PARAMETER PageSize
    Default PageSize for the invocations. More info in the Notes field of this help file.

.PARAMETER PAT
    The personal access token (PAT) to use for authentication.

.PARAMETER Cookie
    The cookie(s) to use for authentication or web requests.

.PARAMETER WebSession
    The web session to use for the web requests.

.PARAMETER PromptCredentials
    Prompt the user for credentials

.PARAMETER Certificate
    Certificate for authentication.

.EXAMPLE
    Set-ConfluenceInfo -BaseURI 'https://yournamehere.atlassian.net/wiki' -PromptCredentials
    Declare the URI of your Confluence instance; be prompted for username and password. Note that Atlassian Cloud Confluence instances typically use the /wiki subdirectory.

.EXAMPLE
    Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com'
    Declare the URI of your Confluence instance. You will not be prompted for credentials, and other commands would attempt to connect anonymously with read-only permissions.

.EXAMPLE
    Set-ConfluenceInfo -BaseURI 'https://wiki.contoso.com' -PromptCredentials -PageSize 50
    Declare the URI of your Confluence instance; be prompted for username and password. Set the default "page size" for all your commands in this session to 50 (see Notes).

.EXAMPLE
    $Cred = Get-Credential
    Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com' -Credential $Cred
    Declare the URI of your Confluence instance and the credentials (username and password).

.OUTPUTS
    None.
#>
function Set-Info {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(HelpMessage = 'Example = https://brianbunke.atlassian.net/wiki (/wiki for Cloud instances)')]
        [System.Uri]
        $BaseUri,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $PageSize,

        [Parameter()]
        [System.String]
        $PAT,

        [Parameter()]
        [System.String]
        $Cookie,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession,

        [Parameter()]
        [switch]$PromptCredentials,

        [Parameter()]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate
    )

    begin {
        if ($PromptCredentials) {
            $Credential = (Get-Credential)
        }
    }

    process {
        if ($PSBoundParameters.ContainsKey('BaseUri')) {
            New-Variable -Name "ApiUri" -Value ($BaseUri.AbsoluteUri.TrimEnd('/') + '/rest/api') -Scope Script -Force
        }

        if ($PSBoundParameters.ContainsKey('Credential')) {
            $Script:AuthMethod = "Credential"
            New-Variable -Name "Credential" -Value $Credential -Scope Script -Force
        }

        if ($PSBoundParameters.ContainsKey('PageSize')) {
            New-Variable -Name "PageSize" -Value $PageSize -Scope Script -Force
        }

        if ($PSBoundParameters.ContainsKey('WebSession')) {
            $Script:AuthMethod = "WebSession"
            New-Variable -Name "WebSession" -Value $WebSession -Scope Script -Force
        }

        if ($PSBoundParameters.ContainsKey('PAT')) {
            $Script:AuthMethod = "PAT"
            New-Variable -Name "PAT" -Value $PAT -Scope Script -Force
        }

        if ($PSBoundParameters.ContainsKey('Cookie')) {
            New-Variable -Name "Cookie" -Value $Cookie -Scope Script -Force
        }

        if ($PSBoundParameters.ContainsKey('Certificate')) {
            $Script:AuthMethod = "Certificate"
            New-Variable -Name "Certificate" -Value $Certificate -Scope Script -Force
        }
    }
}


