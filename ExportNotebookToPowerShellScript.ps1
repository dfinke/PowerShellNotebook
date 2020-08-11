function Export-NotebookToPowerShellScript {
    <#
        .SYNOPSIS
        Exports all code blocks from a PowerShell Notebook to a PowerShell script

        .DESCRIPTION
        Exports from either a local notebook or one on the internet

        .Example
        Export-NotebookToPowerShellScript .\TestPS.ipynb
        Get-Content .\TestPS.ps1

        .Example
        Export-NotebookToPowerShellScript "https://raw.githubusercontent.com/dfinke/PowerShellNotebook/AddJupyterNotebookMetaInfo/samplenotebook/powershell.ipynb"
        Get-Content .\powershell.ps1
        
        .Example
        Export-NotebookToPowerShellScript .\TestPS.ipynb -IncludeTextCells $true
        Get-Content .\TestPS.ps1

        Include exporting the the Text cells from the .IPYNB file to the .PS1 file.
        #>
    [CmdletBinding()]
    param(
        $FullName,
        $outPath = "./",
        $IncludeTextCells=$false
    )
    Write-Progress -Activity "Exporting PowerShell Notebook" -Status $FullName
    
    if ([System.Uri]::IsWellFormedUriString($FullName, [System.UriKind]::Absolute)) {
        $outFile = $FullName.split('/')[-1]
    }
    else {
        $outFile = (Split-Path -Leaf $FullName)
    }
    
    $outFile = $outFile -replace ".ipynb", ".ps1"
    $fullOutFileName = $outPath + $outFile

    $heading = @"
<#
    Created from: $($FullName)

    Created by: Export-NotebookToPowerShellScript
    Created on: $(Get-Date)    
#>

"@ 

    $heading | Set-Content $fullOutFileName    
    if($IncludeTextCells -eq $false)
        {$sourceBlocks = Get-NotebookContent $FullName -JustCode}
    else{$sourceBlocks = Get-NotebookContent $FullName}

    $result = foreach ($sourceBlock in $sourceBlocks) {
        
        switch ($sourceBlock.Type) {
            'code'     {($sourceBlock.Source)}
            'markdown' {"<# "+($sourceBlock.Source)+" #>"}
        }
        ""
    }

    $result | Add-Content  $fullOutFileName

    Write-Verbose "$($outFile) created"
}