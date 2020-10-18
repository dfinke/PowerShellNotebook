function New-GistNotebook {
    param(
        [Parameter(Mandatory)]
        $contents,
        [Parameter(Mandatory)]
        $fileName,
        $gistDescription = "PowerShell Notebook",
        [Switch]$DoNotLaunchBrowser
    )

    if (!(test-path env:github_token)) {
        throw "env:github_token not set. You need to set it to a GitHub PAT"
    }

    $header = @{"Authorization" = "token $($env:GITHUB_TOKEN)" }

    $gist = @{
        'description' = $gistDescription
        'public'      = $false
        'files'       = @{
            "$($fileName)" = @{
                'content' = "$($contents)"
            }
        }
    }

    if (!$DoNotLaunchBrowser) {
        Invoke-RestMethod -Method Post -Uri 'https://api.github.com/gists' -Headers $Header -Body ($gist | ConvertTo-Json)
    }
}