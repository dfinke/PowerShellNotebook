function Export-NotebookToSqlScript {
    <#
        .SYNOPSIS
        Exports all code blocks from a PowerShell Notebook to a PowerShell script

        .DESCRIPTION
        Exports from either a local notebook or one on the internet

        .Example
        Export-NotebookToSqlScript .\BPCheck.ipynb
        Get-Content .\TestSQL.ps1

        .Example
        Export-NotebookToSqlScript "https://raw.githubusercontent.com/microsoft/tigertoolbox/master/BPCheck/BPCheck.ipynb"
        Get-Content .\BPCheck.sql
        #>
    [CmdletBinding()]
    param(
        $FullName,
        $outPath = "./"
    )
    Write-Progress -Activity "Exporting SQL Notebook" -Status $FullName
    
    if ([System.Uri]::IsWellFormedUriString($FullName, [System.UriKind]::Absolute)) {
        $outFile = $FullName.split('/')[-1]
    }
    else {
        $outFile = (Split-Path -Leaf $FullName)
    }
    
    $outFile = $outFile -replace ".ipynb", ".sql"
    $fullOutFileName = $outPath + $outFile

    $heading = @"
/*
    Created from: $($FullName)

    Created by: Export-NotebookToSqlScript
    Created on: $(Get-Date)    
*/

"@ 

    $heading | Set-Content $fullOutFileName    
    $result = foreach ($sourceBlock in Get-NotebookContent $FullName) 
    {
        switch ($sourceBlock.Type) {
            'code'     {($sourceBlock.Source)}
            'markdown' {"/* "+($sourceBlock.Source)+" */"}
        }
        
        ""
    }

    $result | Add-Content  $fullOutFileName

    Write-Verbose "$($outFile) created"
}