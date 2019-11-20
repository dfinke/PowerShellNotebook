function ConvertTo-PowerShellNoteBook {
    <#
        .Example
        ConvertTo-PowerShellNoteBook -InputFileName c:\Temp\demo.txt -OutputNotebookName c:\Temp\demo.ipynb
    #>
    param(
        $InputFileName,
        $OutputNotebookName
    )

    New-PSNotebook -NoteBookName $OutputNotebookName {
        switch -file ($InputFileName) {
            { $_.Trim().Length -eq 0 } { continue }
            { $_.startswith('#') } {
                Add-NotebookMarkdown $_
            }
            default {
                Add-NotebookCode $_
            }
        }
    }
}