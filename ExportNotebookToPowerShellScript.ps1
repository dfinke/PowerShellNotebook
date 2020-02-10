function Export-NotebookToPowerShellScript {
    <#
        .SYNOPSIS
        Exports all code blocks from a PowerShell Notebook to a PowerShell script
    #>
    param(
        $outPath = "./",
        [Parameter(ValueFromPipelineByPropertyName)]
        $FullName
    )

    Process {
        Write-Progress -Activity "Exporting PowerShell Notebook" -Status $FullName
        $outFile = (Split-Path -Leaf $FullName) -replace ".ipynb", ".ps1"
        (Get-NotebookContent $FullName -JustCode).Source | Set-Content ($outPath + $outFile)
    }
}