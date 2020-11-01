function New-GistNotebook {
    param(
        [Parameter(Mandatory)]
        $contents,
        [Parameter(Mandatory)]
        $fileName,
        $gistDescription = "PowerShell Notebook"
    )

    if (!(test-path env:GITHUB_TOKEN)) {
        throw "env:GITHUB_TOKEN not set. You need to set it to a GitHub PAT"
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

    Invoke-RestMethod -Method Post -Uri 'https://api.github.com/gists' -Headers $Header -Body ($gist | ConvertTo-Json)
}