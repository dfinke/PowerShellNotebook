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