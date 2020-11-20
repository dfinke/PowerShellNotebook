function New-GistNotebook {
    param(
        [Parameter(ParameterSetName='File',ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        $Path,
        [Parameter(Mandatory,ParameterSetName='TwoStrings',Position=0)]
        $Contents,
        [Parameter(ParameterSetName='File',ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory,ParameterSetName='TwoStrings',Position=1)]
        [alias('Name')]
        $FileName,
        $GistDescription = "PowerShell Notebook",
        [switch]$Public,
        [switch]$Show
    )
    begin    {
        if (Test-Path env:github_token) {$token = $env:github_token}
        elseif ($PSVersionTable.Platform -like "win*") {
            try   {$token = & (Join-Path $PSScriptRoot 'Get-CredentialFromWindowsCredentialManager.ps1') -TargetName git:https://github.com -PlainTextPasswordOnly }
            catch {throw "Could not read stored access token and env:github_token not set. You need to set it to a GitHub PAT"}
        }
        else { throw "env:github_token not set. You need to set it to a GitHub PAT"}
        $params = @{
            Method  = 'Post'
            Uri     = 'https://api.github.com/gists'
            Headers = @{"Authorization" = "token $token" }
        }
    }
    process  {
        if ($PSBoundParameters.ContainsKey('Path')) {
            $Contents = Get-content $Path -Encoding utf8
            if (-not $FileName) {$FileName = Split-Path -Leaf $Path}
        }
        $gist = @{
            'description' = $GistDescription
            'public'      = ($Public -as [bool])
            'files'       = @{
                "$($FileName)" = @{
                    'content' = "$($Contents)"
                }
            }
        }
        $result = Invoke-RestMethod @params -Body ($gist | ConvertTo-Json -EscapeHandling EscapeNonAscii)
        if ($Show) {Start-Process $result.html_url}
        else       {return        $result.html_Url}
    }
}