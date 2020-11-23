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
        Export-NotebookToPowerShellScript .\TestPS.ipynb -IncludeTextCells
        Get-Content .\TestPS.ps1

        Include exporting the the Text cells from the .IPYNB file to the .PS1 file.
        #>
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        $FullName,
        [Alias("OutPath")]
        $Destination      = $PWD,
        [switch]$IncludeTextCells,
        [switch]$AsText
    )
    Process {
        Write-Progress -Activity "Exporting PowerShell Notebook" -Status $FullName

        if (Test-Path $Destination -PathType Container) {
            #split-path works for well from URIs as well as filesystem paths
            $outFile = (Split-Path -Leaf $FullName) -replace ".ipynb", ".ps1"
            $Destination = Join-Path -Path $Destination -ChildPath $outFile
        }

        #ensure date is formated for local culture.
        $result = , (@'
<#
    Created from: {1}

    Created by:   Export-NotebookToPowerShellScript
    Created on:   {0:D} {0:t}
#>

'@      -f (Get-Date), $FullName)

        if ($IncludeTextCells) {$sourceBlocks = Get-NotebookContent $FullName}
        else                   {$sourceBlocks = Get-NotebookContent $FullName -JustCode}

        #if the last cell is empty don't output it
        if ($sourceBlocks.count -gt 1 -and  [string]::IsNullOrEmpty($sourceBlocks[-1].source)) {
            $sourceBlocks = $sourceBlocks[0..($sourceBlocks.count -2)]
        }

        $prevCode = $false
        $result += switch ($sourceBlocks) {
            {$_.type -eq 'code'} {
                    if ($prevCode) {"<# #>"}  #Avoid concatenating Code cells.
                    ($_.Source.trimend() )
                    $prevCode = $true
            }
            default {
                    "<#`r`n"+ $_.Source.TrimEnd() +"`r`n#>"
                    $prevCode = $false
            }
        }
        if ($AsText) {return $result}
        else {
            $result| Set-Content $Destination
            Get-item $Destination
        }
    }
}