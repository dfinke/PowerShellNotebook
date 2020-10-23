function Find-ParameterizedCell {
    <#
        .Synopsis
        Reads a Jupyter Notebook and returns all cells with a tag -eq to 'parameters'
        .Example
        Invoke-ExecuteNotebook -InputNotebook .\test.ipynb "abs://$($account)/$($containerName)/test.ipynb?$($sasToken)"
    #>
    param(
        [Parameter(Mandatory)]
        $InputNotebook
    )

    if ([System.Uri]::IsWellFormedUriString($InputNotebook, [System.UriKind]::Absolute)) {
        $data = Invoke-RestMethod $InputNotebook
    }
    else {
        $json = Get-Content $InputNotebook 
        $data = $json | ConvertFrom-Json
    }    

    for ($idx = 0; $idx -lt $data.cells.Count; $idx++) {
        $currentCell = $data.cells[$idx]
        if ($currentCell.metadata.tags -eq 'parameters') {
            $idx
        }
    }
}