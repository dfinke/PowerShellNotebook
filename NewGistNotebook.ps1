function New-GistNotebook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $contents,
        [Parameter(Mandatory)]
        $fileName,
        $gistDescription = "PowerShell Notebook"
    )

    if (!(test-path env:github_token)) {
        throw "env:github_token not set. You need to set it to a GitHub PAT"
    }

    $header = @{"Authorization" = "token $($env:github_token)" }

    $gist = @{
        'description' = $gistDescription
        'public'      = $false
        'files'       = @{
            "$($fileName)" = @{
                'content' = "$($contents)"
            }
        }
    }

    Write-Verbose ("`r`n" + ($gist | ConvertTo-Json | Out-String))    
    Write-Verbose 'https://api.github.com/gists'
    
    Invoke-RestMethod -Method Post -Uri 'https://api.github.com/gists' -Headers $Header -Body ($gist | ConvertTo-Json)
}