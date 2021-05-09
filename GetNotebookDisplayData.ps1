function Get-NotebookDisplayData {
    <#
        .Synopsis
    #>
    param($NoteBookFullName)

    $result = Get-NotebookContent -Path $NoteBookFullName -PassThru

    foreach ($cell in $result.cells) {
        if ($cell.outputs.'output_type' -eq 'display_data') {
            [PSCustomObject][Ordered]@{
                Source  = -join $cell.source
                Display = -join $cell.outputs.data.'text/html'
            }
        }
    }
}

