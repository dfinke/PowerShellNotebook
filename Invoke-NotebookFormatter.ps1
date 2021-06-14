function Invoke-NotebookFormatter {
    <#
        .Synopsis
    #>
    
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Fullname')]
        $Path = $pwd
    )

    Begin {
        $found = (Get-Module -ListAvailable PSScriptAnalyzer)
        if (!$found) {
            Write-Host -ForegroundColor Red "PSScriptAnalyzer not found, 'Install-Module PSScriptAnalyzer' and rerun"
        }
    }

    Process {
        if ($found) {
            if ([System.Uri]::IsWellFormedUriString($Path, [System.UriKind]::Absolute)) {
                try {
                    $data = Invoke-RestMethod $Path
                }
                catch {
                    throw "$($Path) is not a valid Jupyter Notebook" 
                }
            }
            else {
                $json = Get-Content $Path 
                $data = $json | ConvertFrom-Json
            }            
        }
        
        $cells = $data.cells
        $totalCells = $cells.count
        for ($idx = 0; $idx -lt $totalCells; $idx++) {
            $cell = $cells[$idx]
            if ($cell.cell_type) {
                if ($cell.metadata.dotnet_interactive.language -eq 'pwsh') {
                    $result = Invoke-Formatter (-join $cell.source)
                    $lines = $result.split("`n")

                    $cell.source = $(
                        foreach ($line in $lines) {
                            $line + "`n"
                        }
                    )
                }
            }
        }

        $targetPath = Split-Path $Path
        $LeafBase = Split-Path $Path -LeafBase
        $Extension = Split-Path $Path -Extension

        $targetFile = "{0}\{1}.formatted{2}" -f $targetPath, $LeafBase, $Extension
        
        ConvertTo-Json $data -Depth 15 | Set-Content -Path $targetFile
    }
}