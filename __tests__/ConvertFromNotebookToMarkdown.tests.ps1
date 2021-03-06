Import-Module $PSScriptRoot\..\PowerShellNotebook.psd1 -Force

Describe "Test ConvertFrom-NoteBookToMarkdown" -Tag ConvertFromNoteBookToMarkdown  {
    It "Should convert to markdown" {
        $targetFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.ipynb"

        $actual = ConvertFrom-NoteBookToMarkdown -NotebookName $targetFile -AsText

        $actual.Count | Should -Be 3

        $actual[0].trim() | Should -Beexactly '# Test for converting a PS Notebook to Markdown'
        $actual[2].trim() | Should -Beexactly '## End of PS Notebook'
        $actual[1].trim() | Should -match '^```PowerShell'
        $actual[1].Trim( )| Should -match '```$'
    }

    It "Should convert to markdown in a file" {
        $targetFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.ipynb"
        $mdFile = "$PSScriptRoot\GoodNotebooks\SimpleNotebookToTestConvertToMarkdown.md"
        $expected = Split-Path $mdFile -Leaf

        $actual = ConvertFrom-NoteBookToMarkdown -NotebookName $targetFile

        $actual | Should -Match "$expected`$"

        Remove-Item $expected -ErrorAction SilentlyContinue
    }
}