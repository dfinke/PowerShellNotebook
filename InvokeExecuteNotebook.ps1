function Invoke-ExecuteNotebook {
    param(
        $InputNotebook,
        $OutputNotebook,
        [hashtable]$Parameters
    )

    if (!$InputNotebook) { return }

    $data = Get-Content $inputNotebook | ConvertFrom-Json
    [System.Collections.ArrayList]$cells = $data.cells
    
    $PSNotebookRunspace = New-PSNotebookRunspace
    
    for ($idx = 0; $idx -lt $cells.count; $idx++) {
        $PSNotebookRunspace.PowerShell.Commands.Clear()
        $cell = $cells[$idx]

        if ($cell.metadata.tags -eq 'parameters' -and $parameters) {
            $newVars = @("# override parameters")
            $newVars += $(
                foreach ($entry in $parameters.GetEnumerator() ) {
                    "`$$($entry.name) = $($entry.value)"
                }
            )

            $newParams = New-CodeCell ($newVars -join "`r`n") | ConvertFrom-Json

            $cells.Insert(($idx + 1), $newParams)
        }

        $result = $PSNotebookRunspace.Invoke($cell.source)
        
        if ($cell.outputs -and $cell.outputs.text) {
            $cell.outputs[0].text = $result
        }
    }

    $data.cells = $cells
    
    if ($OutputNotebook) {
        if ($outputNotebook.startswith("gist://")) {

            $OutFile = $OutputNotebook.replace("gist://", "")
            $targetFileName = Split-Path $OutFile -Leaf

            $contents = $data | ConvertTo-Json -Depth 4
            $result = New-GistNotebook -contents $contents -fileName $targetFileName

            if ($result) {
                Start-Process $result.html_url
            }            
        }
        else {
            if (Test-Path $OutputNotebook) {
                throw "$OutputNotebook already exists"
            }

            ConvertTo-Json -InputObject $data -Depth 4 |
            Set-Content $OutputNotebook -Encoding utf8
        }
    }
    else {
        $data.cells.outputs.text
    }    
}

function New-GistNotebook {
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