function Export-NotebookToPowerShellScript {
    <#
        .SYNOPSIS
        Exports all code blocks from a PowerShell Notebook to a PowerShell script

        .Example
        Export-NotebookToPowerShellScript .\TestPS.ipynb
        Get-Content .\TestPS.ps1
    #>
    [CmdletBinding()]
    param(
        $FullName,
        $outPath = "./"
    )

    if (Test-Path $FullName) {
        Write-Progress -Activity "Exporting PowerShell Notebook" -Status $FullName
        $outFile = (Split-Path -Leaf $FullName) -replace ".ipynb", ".ps1"
        (Get-NotebookContent $FullName -JustCode).Source | Set-Content ($outPath + $outFile)
        Write-Verbose "$($outFile) created"
    } else{
        Write-Warning "File: $($FullName) not found"
    }
}