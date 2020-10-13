function Get-NotebookDisplayData {
    param($NoteBookFullName)

    $result = Get-NotebookContent -NoteBookFullName $NoteBookFullName -PassThru

    foreach ($cell in $result.cells) {
        if ($cell.outputs.'output_type' -eq 'display_data') {
            [PSCustomObject][Ordered]@{
                Source  = -join $cell.source
                Display = -join $cell.outputs.data.'text/html'
            }
        }
    }
}

    