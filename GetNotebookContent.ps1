function Get-NotebookContent {
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $NoteBookFullName,
        [Switch]$JustCode,
        [Switch]$JustMarkdown
    )

    Process {
        $r = Get-Content $NoteBookFullName | ConvertFrom-Json

        if ($JustCode) { $cellType = "code" }
        if ($JustMarkdown) { $cellType = "markdown" }
        if ($JustCode -and $JustMarkdown) { $cellType = $null }

        $r.cells | Where-Object { $_.cell_type -match $cellType } | ForEach-Object {
            [PSCustomObject][Ordered]@{
                NoteBookName = Split-Path -Leaf $NoteBookFullName
                Type         = $_.'cell_type'
                Source       = $_.source
            }
        }
    }
}
