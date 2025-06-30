<#
.SYNOPSIS
    Invoke a specific call to a Confluence REST Api endpoint

.DESCRIPTION
    Make a call to a REST Api endpoint with all the benefits of ConfluencePS.
    This cmdlet is what the other cmdlets call under the hood. It handles the authentication, parses the response, handles exceptions from Confluence, returns specific objects and handles the differences between versions of Powershell and Operating Systems.
    ConfluencePS does not support any third-party plugins on Confluence. This cmdlet can be used to interact with REST Api endpoints which are not already converted in ConfluencePS. It allows for anyone to use the same technics as ConfluencePS uses internally for creating their own functions or modules. When used by a module, the Manifest (.psd1) can define the dependency to ConfluencePS with the 'RequiredModules' property. This will import the module if not already loaded or even download it from the PSGallery.

.PARAMETER Uri
    URI address of the REST API endpoint.

.PARAMETER Method
    Method of the HTTP request.

.PARAMETER Body
    Body of the HTTP request. By default each character of the Body is encoded to a sequence of bytes. This enables the support of UTF8 characters. And was first reported here: <https://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json> This behavior can be changed with -RawBody.

.PARAMETER RawBody
    Keep the Body from being encoded.

.PARAMETER Headers
    Define a key-value set of HTTP headers that should be used in the call.

.PARAMETER GetParameters
    Define a key-value set of GET Parameters. This is not mandatory, and can be integrated in the Uri. This parameter exists to facilitate the addition and removal of parameters in particular for paging

.PARAMETER InFile
    Path to a file that will be uploaded with a multipart/form-data request. This parameter does not validate the input in any way.

.PARAMETER OutFile
    Path to the file where the response should be stored to. This parameter does not validate the input in any way

.PARAMETER OutputType
    Define the Type of the object that will be returned by the call. The casting to custom classes is done in private functions as uses the cast operator which throws a terminating error in case the response can't be casted.

.PARAMETER Caller
    Context which will be used for throwing errors.

.PARAMETER IncludeTotalCount
    > NOTE: Not yet implemented. Causes an extra output of the total count at the beginning. Note this is actually a uInt64, but with a custom string representation.

.PARAMETER Skip
    > NOTE: Not yet implemented. Controls how many objects will be skipped before starting output. Defaults to 0.

.PARAMETER First
    > NOTE: Not yet implemented. Indicates how many items to return.

.EXAMPLE
    Invoke-ConfluenceMethod -Uri https://contoso.com/rest/api/content -Credential $cred
    Executes a GET request on the defined URI and returns a collection of PSCustomObject

.EXAMPLE
    Invoke-ConfluenceMethod -Uri https://contoso.com/rest/api/content -OutputType [ConfluencePS.Page] -Credential $cred
    Executes a GET request on the defined URI and returns a collection of ConfluencePS.Page

.EXAMPLE
    $params = @{
        Uri = "https://contoso.com/rest/api/content"
        Method = "POST"
        Credential = $cred
    }
    Invoke-ConfluenceMethod @params
    Executes a POST request on the defined URI and returns a collection of ConfluencePS.Page.
    This will example doesn't really do anything on the server, as the content API needs requires a value for the BODY. See next example

.EXAMPLE
    $body = '{"type": "page", "space": {"key": "TS"}, "title": "My New Page", "body": {"storage": {"representation": "storage"}, "value": "<p>LoremIpsum</p>"}}'
    $params = @{
        Uri = "https://contoso.com/rest/api/content"
        Method = "POST"
        Body = $body
        Credential = $cred
    }
    Invoke-ConfluenceMethod @params
    Executes a POST request with a JSON string in the BODY on the defined URI and returns a collection of ConfluencePS.Page.

.EXAMPLE
    $params = @{
        Uri = "https://contoso.com/rest/api/content"
        GetParameters = @{
            expand = "space,version,body.storage,ancestors"
            limit  = 30
        }
        Credential = $cred
    }
    Invoke-ConfluenceMethod @params
    Executes a GET request on the defined URI with a Get Parameter that is resolved to look like this: ?expand=space,version,body.storage,ancestors&limit=30

.EXAMPLE
    $params = @{
        Uri = "https://contoso.com/rest/api/content/10001/child/attachment"
        Method = "POST"
        OutputType = [ConfluencePS.Attachment]
        InFile = "c:\temp\confidentialData.txt"
        Credential = $cred
    }
    Invoke-ConfluenceMethod @params
    Executes a POST request on the defined URI and uploads the InFile with a multipart/form-data request. The response of the request will be cast to an object of type ConfluencePS.Attachment.

.EXAMPLE
    $params = @{
        Uri = "https://contoso.com/rest/api/content/10001/child/attachment/110001"
        Method = "GET"
        Headers    = @{"Accept" = "text/plain"}
        OutFile = "c:\temp\confidentialData.txt"
        Credential = $cred
    }
    Invoke-ConfluenceMethod @params
    Executes a GET request on the defined URI and stores the output on the File System. It also uses the Headers to define what mimeTypes are expected in the response.

.OUTPUTS
    System.Management.Automation.PSObject ConfluencePS.Page ConfluencePS.Space ConfluencePS.Label ConfluencePS.Icon ConfluencePS.Version ConfluencePS.User ConfluencePS.Attachment
#>
function Invoke-Method {
    [CmdletBinding(SupportsPaging = $true)]
    [OutputType(
        [PSObject],
        [ConfluencePS.Page],
        [ConfluencePS.Space],
        [ConfluencePS.Label],
        [ConfluencePS.Icon],
        [ConfluencePS.Version],
        [ConfluencePS.User],
        [ConfluencePS.Attachment]
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute( "PSAvoidUsingEmptyCatchBlock", "" )]
    param (
        [Parameter(Mandatory = $true)]
        [uri]$Uri,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Body,

        [Parameter()]
        [Switch]
        $RawBody,

        [Parameter()]
        [Hashtable]
        $Headers,

        [Parameter()]
        [Hashtable]
        $GetParameters,

        [Parameter()]
        [System.String]
        $InFile,

        [Parameter()]
        [System.String]
        $OutFile,

        [Parameter()]
        [ValidateSet(
            [ConfluencePS.Page],
            [ConfluencePS.Space],
            [ConfluencePS.Label],
            [ConfluencePS.Icon],
            [ConfluencePS.Version],
            [ConfluencePS.User],
            [ConfluencePS.Attachment]
        )]
        [System.Type]
        $OutputType,

        [Parameter()]
        [System.Management.Automation.PSCmdlet]
        $Caller = $PSCmdlet
    )

    begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function started"

        Set-TlsLevel -Tls12

        # Sanitize double slash `//`
        # Happens when the BaseUri is the domain name
        # [Uri]"http://google.com" vs [Uri]"http://google.com/foo"
        $Uri = $Uri -replace '(?<!:)\/\/', '/'

        # pass input to local variable
        # this allows to use the PSBoundParameters for recursion
        $_headers = @{   # Set any default headers
            "Accept"         = "application/json"
            "Accept-Charset" = "utf-8"
        }

        foreach ($key in $Headers.Keys) {
            $_headers[$key] = $Headers[$key]
        }
        if (-not [System.String]::IsNullOrEmpty($Script:PAT)) {
            $_headers["Authorization"] = "Bearer $($Script:PAT)"
        }
    }

    process {
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $splatParameters = @{
            Uri = $Uri
            Method = $Method
            Headers = $_headers
            ContentType = "application/json; charset=utf-8"
            UseBasicParsing = $true
            ErrorAction = 'Stop'
            Verbose = $false
        }

        switch ($Script:AuthMethod) {
            "Credential" {
                $splatParameters.Add('Credential', $Script:Credential)
            }
            "WebSession" {
                $splatParameters.Add('WebSession', $Script:WebSession)
            }
            "Certificate" {
                $splatParameters.Add('Certificate', $Certificate)
            }
        }

        if ($null -ne $Script:Cookie) {
            $splatParameters.Add('Cookie', $Script:Cookie)
        }
        if ($null -ne $Script:PageSize) {
            $splatParameters.Add('PageSize', $Script:PageSize)
        }
        if ($PSBoundParameters.ContainsKey('InFile')) {
            $splatParameters.Add('InFile', $InFile)
        }
        if ($PSBoundParameters.ContainsKey('OutFile')) {
            $splatParameters.Add('OutFile', $OutFile)
        }

        #add 'start' query parameter if Paging with Skip is being used
        if (($PSCmdlet.PagingParameters) -and ($PSCmdlet.PagingParameters.Skip)) {
            $GetParameters["start"] = $PSCmdlet.PagingParameters.Skip
        }
        # Append GET parameters to Uri, aka query Parameters
        if ($GetParameters -and ($Uri.Query -eq "")) {
            Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Using `$GetParameters: $($GetParameters | Out-String)"
            $splatParameters['Uri'] = [uri]"$Uri$(ConvertTo-GetParameter $GetParameters)"
            # Prevent recursive appends
            $PSBoundParameters.Remove('GetParameters') | Out-Null
            $GetParameters = $null
        }

        if ($Body) {
            if ($RawBody) {
                $splatParameters.Add('Body', $Body)
            } else {
                # Encode Body to preserve special chars
                # http://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json
                $splatParameters.Add('Body', [System.Text.Encoding]::UTF8.GetBytes($Body))
            }
        }

        # Invoke the API
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Invoking method $Method to URI $URi"
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with: $(([PSCustomObject]$splatParameters) | Out-String)"
        try {
            $webResponse = Invoke-WebRequest @splatParameters
        } catch {
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server"
            $webResponse = $_
            if ($webResponse.ErrorDetails) {
                # In PowerShellCore (v6+), the response body is available as string
                $responseBody = $webResponse.ErrorDetails.Message
            } else {
                $webResponse = $webResponse.Exception.Response
            }
        }

        # Test response Headers if Confluence requires a CAPTCHA
        Test-Captcha -InputObject $webResponse

        Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"

        if ($webResponse) {
            # In PowerShellCore (v6+) the StatusCode of an exception is somewhere else
            if (-not ($statusCode = $webResponse.StatusCode)) {
                $statusCode = $webresponse.Exception.Response.StatusCode
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Status code: $($statusCode)"

            if ($statusCode.value__ -ge 400) {
                Write-Warning "Confluence returned HTTP error $($statusCode.value__) - $($statusCode)"

                if ((-not ($responseBody)) -and ($webResponse | Get-Member -Name "GetResponseStream")) {
                    # Retrieve body of HTTP response - this contains more useful information about exactly why the error occurred
                    $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                    $responseBody = $readStream.ReadToEnd()
                    $readStream.Close()
                }

                Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Retrieved body of HTTP response for more information about the error (`$responseBody)"
                Write-Debug -Message "[$($MyInvocation.MyCommand.Name)] Got the following error as `$responseBody"

                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Invalid Server Response"),
                    "InvalidResponse.Status$($statusCode.value__)",
                    [System.Management.Automation.ErrorCategory]::InvalidResult,
                    $responseBody
                )

                try {
                    $responseObject = ConvertFrom-Json -InputObject $responseBody -ErrorAction Stop
                    if ($responseObject.message) {
                        $errorItem.ErrorDetails = $responseObject.message
                    } else {
                        $errorItem.ErrorDetails = "An unknown error ocurred."
                    }

                } catch {
                    $errorItem.ErrorDetails = "An unknown error ocurred."
                }

                $Caller.WriteError($errorItem)
            }
            else {
                if ($webResponse.Content) {
                    try {
                        # API returned a Content: let's work with it
                        if ($webResponse.Content.Contains("<title>Sign in to your account</title>")) {
                            throw "Login required to access the desired content."
                        }
                        $response = ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($webResponse.RawContentStream.ToArray()))

                        if ($null -ne $response.errors) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] An error response was received from; resolving"
                            # This could be handled nicely in an function such as:
                            # ResolveError $response -WriteError
                            Write-Error $($response.errors | Out-String)
                        } else {
                            if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
                                [System.Double]$Accuracy = 0.0
                                $PSCmdlet.PagingParameters.NewTotalCount($response.size, $Accuracy)
                            }

                            # None paginated results / first page of pagination
                            $result = $response
                            if (($response) -and ($response | Get-Member -Name results)) {
                                $result = $response.results
                            }

                            if ($OutputType) {
                                # Results shall be casted to custom objects (see ValidateSet)
                                Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Outputting results as $($OutputType.FullName)"
                                $converter = "ConvertTo-$($OutputType.Name)"
                                $result | & $converter
                            } else {
                                $result
                            }

                            # Detect if result is paginated
                            if ($response._links.next) {
                                Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Invoking pagination"

                                $parameters = ([System.Collections.Hashtable]$PSBoundParameters).Clone()
                                $parameters['Method'] = $Method
                                $parameters['Headers'] = $_headers
                                $parameters['Uri'] = "{0}{1}" -f $response._links.base, $response._links.next

                                Write-Verbose -Message "NEXT PAGE: $($parameters["Uri"])"

                                Invoke-Method @parameters
                            }
                        }
                    } catch {
                        throw $_
                    }
                } else {
                    # No content, although statusCode < 400
                    # This could be wanted behavior of the API
                    Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] No content was returned from."
                }
            }
        } else {
            Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] No Web result object was returned from. This is unusual-not "
        }
    }

    end {
        Set-TlsLevel -Revert

        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
