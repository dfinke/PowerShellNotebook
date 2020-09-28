function Find-ParameterizedCell {
    <#
        .Synopsis
        Reads a Jupyter Notebook and returns all cells with a tag -eq to 'parameters'
        
    #>
    param(
        [Parameter(Mandatory)]
        $InputNotebook
    )

    $data = ConvertFrom-Json -InputObject (Get-Content -Raw $InputNotebook)

    for ($idx = 0; $idx -lt $data.cells.Count; $idx++) {
        $currentCell = $data.cells[$idx]
        if ($currentCell.metadata.tags -eq 'parameters') {
            $idx
        }
    }
}

function Get-ParameterInsertionIndex {
    param(
        [Parameter(Mandatory)]
        $InputNotebook
    )

    $cell = Find-ParameterizedCell $InputNotebook | Select-Object -First 1
    if ([string]::IsNullOrEmpty($cell)) {
        return 0
    }
    $cell + 1
}

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

    if ($Parameters) {        
        $newVars = @("# override parameters")
        $newVars += $(
            foreach ($entry in $parameters.GetEnumerator() ) {
                $quote = $null
                $currentValue = $entry.value
                                
                if ($currentValue -is [string]) { $quote = "'" }
                '${0} = {1}{2}{1}' -f $entry.name, $quote, $currentValue
                
                # "`$$($entry.name) = $($entry.value)"
            }
        )
            
        $newParams = New-CodeCell ($newVars -join "`r`n") | ConvertFrom-Json

        $index = Get-ParameterInsertionIndex -InputNotebook $InputNotebook
        $cells.Insert($index, $newParams)
    }

    for ($idx = 0; $idx -lt $cells.count; $idx++) {
        $PSNotebookRunspace.PowerShell.Commands.Clear()
        $cell = $cells[$idx]

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