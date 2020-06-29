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
        $fullOutFileName = $outPath + $outFile

        $heading = @"
<#
    Created from: $($FullName)

    Created by: Export-NotebookToPowerShellScript
    Created on: $(Get-Date)    
#>

"@ 
        $heading | Set-Content $fullOutFileName

        $result = foreach ($sourceBlock in (Get-NotebookContent $FullName -JustCode).Source) {
            $sourceBlock
            ""
        }

        $result | Add-Content  $fullOutFileName
        # (Get-NotebookContent $FullName -JustCode).Source | Add-Content  $fullOutFileName

        Write-Verbose "$($outFile) created"
    }
    else {
        Write-Warning "File: $($FullName) not found"
    }
}