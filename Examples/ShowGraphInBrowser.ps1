Import-Module ..\PowerShellNotebook.psd1 -Force

$htmlFile = "$env:TEMP\test.html"

$result = Get-NotebookDisplayData -NoteBookFullName "$PSScriptRoot\..\__tests__\ChartNotebooks\charts.ipynb"
$result.Display > $htmlFile

Invoke-Item $htmlFile