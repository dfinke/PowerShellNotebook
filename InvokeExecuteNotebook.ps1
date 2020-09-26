function Invoke-ExecuteNotebook {
    param(
        $InputNotebook,
        $OutputNotebook,
        [hashtable]$Parameters
    )
}

function New-GistNotebook {
    param(
        [Parameter(Mandatory)]
        $contents,
        [Parameter(Mandatory)]
        $fileName,
        $gistDescription = "PowerShell Notebook"
    )

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

function New-CodeCell {
    param(
        [Parameter(Mandatory)]
        $Source
    )    
    @"
{
    "cell_type": "code",
    "execution_count": 0,
    "metadata": {
     "tags": [
      "new parameters"
     ]
    },
    "outputs": [],
    "source": $(@($source.split("`n")) | ConvertTo-Json)    
}
"@
}