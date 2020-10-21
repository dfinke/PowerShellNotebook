function Export-AsPowerShellNotebook {
    <#
        .Synopsis
        Takes strings of PowerShell and creates and interactive Jupyter Notebook. Try exporting your PowerShell history to a notebook. Check the examples
        
        .Example
        Get-History | % command* | Out-ConsoleGridView | Export-AsPowerShellNotebook -OutputNotebook .\temp\testthis.ipynb
        
        .Example
        Get-History 7,14 | % comm* | Export-AsPowerShellNotebook -OutputNotebook d:\temp\testthis.ipynb
    #>
    param(
        $OutputNotebook,
        [Parameter(ValueFromPipeline)]
        $PowerShellText
    )

    Begin {
        if (!$OutputNotebook) {
            throw '$OutputNotebook not specified'
        }
        $psCode = @()
    }

    Process {
        $psCode += $PowerShellText
    }

    End {
        $count = $psCode.Count
        if ($count -gt 0) {
            New-PSNotebook -NoteBookName $OutputNotebook {
                for ($idx = 0; $idx -lt $count; $idx++) {
                    $currentText = $psCode[$idx]
                    if ($currentText.Trim().StartsWith('#')) {
                        Add-NotebookMarkdown -markdown $currentText 
                    }
                    else {
                        Add-NotebookCode -code $currentText
                    }
                }
            }
        }
    }
}