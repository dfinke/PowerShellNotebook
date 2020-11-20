Function Set-NotebookToPS {
    param (
        [Parameter(ValueFromPipeline = $true)]
        $Path,
        $OutputPath,
        [alias('PT')]
        [switch]$PassThru
    )
    process {
        #Re-write metadata from a VSCode add-in - C# with PWSH magic commands to server Jupyter style
        $nb = Get-Content $Path | ConvertFrom-Json -Depth 10
        $nb.metadata.kernelspec.display_name        = '.NET (PowerShell)'
        $nb.metadata.kernelspec.language            = 'PowerShell'
        $nb.metadata.kernelspec.name                = '.net-powershell'
        $nb.metadata.language_info.file_extension   = '.ps1'
        $nb.metadata.language_info.mimetype         = 'text/x-powershell'
        $nb.metadata.language_info.name             = 'PowerShell'
        $nb.metadata.language_info.pygments_lexer   = 'powerShell'
        $nb.metadata.language_info.version          = '7.0'
        foreach ($cell in $nb.cells.where({$_.cell_Type -eq 'code' -and
                                           $_.source[0] -match '^#!pwsh'})) {
             $cell.source = $cell.source[1..$cell.source.count]
        }

        if (-not $OutputPath) {$OutputPath = $Path}
        ConvertTo-Json $nb -Depth 10 |
            Out-File -Encoding utf8 -Path $OutputPath

        if ($PassThru) {Get-Item $OutputPath}
    }
}