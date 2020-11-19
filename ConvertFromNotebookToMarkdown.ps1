function ConvertFrom-NotebookToMarkdown {
    <#
        .SYNOPSIS
        Take and exiting PowerShell Notebook and convert it to markdown
    #>
    param(
        [Parameter(Mandatory)]
        $NotebookName,
        [Switch]$AsText
    )

    $text = $(switch (Get-NotebookContent -NoteBookFullName $NotebookName) {
            { $_.Type -eq 'markdown' } { $_.Source }
            { $_.Type -eq 'code' } {
                '```powershell' + "`n" + $_.Source.Replace("#!pwsh`n", "") + "`n" + '```' + "`n"
            }
        })

    if ($AsText) {
        return $text
    }

    $mdFilename = (Split-Path -Leaf $NotebookName) -replace 'ipynb', 'md'
    $text | Set-Content -Encoding UTF8 $mdFilename

    $mdFilename
}
